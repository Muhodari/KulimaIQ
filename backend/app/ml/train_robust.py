"""
Train the location-invariant KulimaIQ disease model.

This strengthens the vision CNN so it detects disease accurately in *any*
agro-ecological location from the leaf photo alone — no location input.

Two mechanisms work together:
  1. Agro-ecological STYLE AUGMENTATION (app/ml/agro_style.py): each training
     image is re-rendered in random "location looks" (highland/lowland/humid/
     dry lighting, colour, contrast, haze, noise).
  2. MIXSTYLE (app/ml/mixstyle.py): mixes feature statistics across the batch,
     synthesising further unseen location styles inside the network.

Model selection uses the WORST location-shift domain accuracy (a genuine
domain-generalization objective), not clean accuracy — so we reward the model
that holds up everywhere, not just on familiar-looking images.

Usage:
    python -m app.ml.train_robust --epochs 40

Best checkpoint → model_weights/kulimaiq_mobilenet.pth (ordinary MobileNetV2
state_dict; loads with the existing inference service unchanged).
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, WeightedRandomSampler
from torchvision import datasets

from .agro_style import (
    EVAL_DOMAIN_NAMES,
    build_eval_domain_transform,
    build_train_transform,
)
from .dataset import val_transform
from .model import MixStyleMobileNet


def _device(pref: str = "auto") -> torch.device:
    if pref != "auto":
        return torch.device(pref)
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


@torch.no_grad()
def _accuracy(model: nn.Module, loader: DataLoader, device: torch.device) -> float:
    model.eval()
    correct = total = 0
    for images, labels in loader:
        images, labels = images.to(device), labels.to(device)
        preds = model(images).argmax(1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)
    return correct / max(total, 1)


def train(
    data_dir: str = "data",
    output_dir: str = "model_weights",
    epochs: int = 40,
    batch_size: int = 32,
    lr: float = 1e-3,
    agro_strength: float = 1.0,
    device_str: str = "auto",
    init_weights: str | None = None,
) -> None:
    device = _device(device_str)
    print(f"[train_robust] Device: {device}")

    root = Path(data_dir)
    train_ds = datasets.ImageFolder(
        str(root / "train"), transform=build_train_transform(agro_strength)
    )
    val_clean = datasets.ImageFolder(str(root / "val"), transform=val_transform)
    classes = train_ds.classes
    num_classes = len(classes)
    print(f"[train_robust] {num_classes} classes | train {len(train_ds)} "
          f"| val {len(val_clean)}")

    val_clean_loader = DataLoader(val_clean, batch_size=batch_size, shuffle=False,
                                  num_workers=0)
    # Held-out location-shift evaluation domains.
    domain_loaders = {
        name: DataLoader(
            datasets.ImageFolder(str(root / "val"),
                                 transform=build_eval_domain_transform(name)),
            batch_size=batch_size, shuffle=False, num_workers=0,
        )
        for name in EVAL_DOMAIN_NAMES
    }

    # Warm-start from existing weights when available (avoids re-downloading
    # ImageNet weights and fine-tunes the already-good model to be robust).
    pretrained = init_weights is None
    model = MixStyleMobileNet(num_classes=num_classes, pretrained=pretrained)
    if init_weights:
        state = torch.load(init_weights, map_location="cpu", weights_only=False)
        sd = state["model_state_dict"] if "model_state_dict" in state else state
        model.load_state_dict(sd, strict=False)
        print(f"[train_robust] Warm-started from {init_weights}")
    model.to(device)

    counts = [0] * num_classes
    for _, y in train_ds.samples:
        counts[y] += 1
    total = sum(counts)
    class_weights: list[float] = []
    sample_weights: list[float] = []
    for idx, name in enumerate(classes):
        c = counts[idx]
        w = total / (num_classes * c) if c else 1.0
        if name == "healthy":
            w *= 0.35
        class_weights.append(w)
    weights = torch.tensor(class_weights, dtype=torch.float, device=device)
    for _, y in train_ds.samples:
        sw = 1.0 / max(counts[y], 1)
        if classes[y] == "healthy":
            sw *= 0.4
        sample_weights.append(sw)
    sampler = WeightedRandomSampler(
        sample_weights, num_samples=len(sample_weights), replacement=True
    )
    train_loader = DataLoader(train_ds, batch_size=batch_size, sampler=sampler,
                              num_workers=2, pin_memory=True)
    criterion = nn.CrossEntropyLoss(weight=weights, label_smoothing=0.05)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    Path(output_dir).mkdir(parents=True, exist_ok=True)
    best_score = -1.0
    history: list[dict] = []

    for epoch in range(1, epochs + 1):
        model.train()
        run_loss = correct = seen = 0.0
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            out = model(images)
            loss = criterion(out, labels)
            loss.backward()
            optimizer.step()
            run_loss += loss.item() * images.size(0)
            correct += (out.argmax(1) == labels).sum().item()
            seen += images.size(0)
        scheduler.step()

        clean_acc = _accuracy(model, val_clean_loader, device)
        domain_acc = {n: _accuracy(model, dl, device)
                      for n, dl in domain_loaders.items()}
        worst = min(domain_acc.values())
        mean_shift = sum(domain_acc.values()) / len(domain_acc)

        history.append({
            "epoch": epoch,
            "train_loss": round(run_loss / seen, 4),
            "train_acc": round(correct / seen, 4),
            "val_clean_acc": round(clean_acc, 4),
            "val_shift_mean_acc": round(mean_shift, 4),
            "val_shift_worst_acc": round(worst, 4),
            "domains": {k: round(v, 4) for k, v in domain_acc.items()},
        })
        print(f"epoch {epoch:3d}/{epochs} | loss {run_loss/seen:.3f} | "
              f"clean {clean_acc:.3f} | shift_mean {mean_shift:.3f} | "
              f"worst {worst:.3f}")

        # Selection balances clean accuracy with worst-domain accuracy, so the
        # deployed model is both accurate on normal photos AND robust to unseen
        # location appearances (not one at the expense of the other).
        score = 0.5 * clean_acc + 0.5 * worst
        if score > best_score:
            best_score = score
            torch.save(
                {
                    "model_state_dict": model.state_dict(),
                    "classes": classes,
                    "num_classes": num_classes,
                    "epoch": epoch,
                    "val_acc": clean_acc,
                    "val_shift_worst_acc": worst,
                    "training": "location-invariant (MixStyle + agro-style aug)",
                },
                Path(output_dir) / "kulimaiq_mobilenet.pth",
            )
            print(f"  ✓ saved best (worst-domain {worst:.3f}, clean {clean_acc:.3f})")

    Path(output_dir, "training_history_robust.json").write_text(
        json.dumps(history, indent=2)
    )
    Path(output_dir, "classes.json").write_text(json.dumps(classes, indent=2))
    print(f"[train_robust] Done. Best selection score: {best_score:.4f}")


def main() -> None:
    p = argparse.ArgumentParser(description="Train location-invariant disease CNN")
    p.add_argument("--data_dir", default="data")
    p.add_argument("--output_dir", default="model_weights")
    p.add_argument("--epochs", type=int, default=40)
    p.add_argument("--batch_size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--agro_strength", type=float, default=1.0)
    p.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda", "mps"])
    p.add_argument("--init_weights", default=None,
                   help="Warm-start from an existing checkpoint (e.g. the baseline)")
    args = p.parse_args()
    train(
        data_dir=args.data_dir,
        output_dir=args.output_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        agro_strength=args.agro_strength,
        device_str=args.device,
        init_weights=args.init_weights,
    )


if __name__ == "__main__":
    main()
