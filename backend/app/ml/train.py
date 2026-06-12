"""
Training script for the KulimaIQ crop-disease CNN.

The number of output classes is determined automatically from the
data/train/ folder structure — add a new disease by adding a folder.

Quick start
───────────
  python -m app.ml.train \\
      --data_dir data \\
      --output_dir model_weights \\
      --epochs 30 \\
      --batch_size 32

  Best checkpoint → output_dir/kulimaiq_mobilenet.pth
  Training log   → output_dir/training_history.json
"""

import argparse
import json
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from .dataset import load_datasets
from .model import build_model


def train(
    data_dir: str,
    output_dir: str,
    epochs: int = 30,
    batch_size: int = 32,
    lr: float = 1e-3,
    freeze_backbone: bool = False,
    device_str: str = "auto",
) -> None:
    # ── Device ────────────────────────────────────────────────────────────────
    if device_str == "auto":
        device = torch.device(
            "cuda" if torch.cuda.is_available() else
            "mps" if torch.backends.mps.is_available() else
            "cpu"
        )
    else:
        device = torch.device(device_str)
    print(f"[train] Device: {device}")

    # ── Data ──────────────────────────────────────────────────────────────────
    train_ds, val_ds = load_datasets(data_dir)
    classes: list[str] = train_ds.classes          # ← dynamic class list
    num_classes = len(classes)

    train_loader = DataLoader(
        train_ds, batch_size=batch_size, shuffle=True,
        num_workers=4, pin_memory=True,
    )
    val_loader = DataLoader(
        val_ds, batch_size=batch_size, shuffle=False,
        num_workers=4, pin_memory=True,
    )

    print(f"[train] {num_classes} classes: {classes}")
    print(f"[train] Train: {len(train_ds)} | Val: {len(val_ds)}")

    # ── Model ─────────────────────────────────────────────────────────────────
    model = build_model(
        num_classes=num_classes,
        pretrained=True,
        freeze_backbone=freeze_backbone,
    )
    model.to(device)

    # ── Compute class weights to handle imbalance ─────────────────────────────
    class_counts = [0] * num_classes
    for _, label in train_ds.samples:
        class_counts[label] += 1
    total = sum(class_counts)
    weights = torch.tensor(
        [total / (num_classes * c) if c > 0 else 1.0 for c in class_counts],
        dtype=torch.float, device=device,
    )
    print(f"[train] Class weights: {dict(zip(classes, [round(w.item(),2) for w in weights]))}")

    # ── Optimiser + scheduler ─────────────────────────────────────────────────
    optimizer = torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=lr, weight_decay=1e-4,
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)
    criterion = nn.CrossEntropyLoss(weight=weights, label_smoothing=0.1)

    # ── Training loop ─────────────────────────────────────────────────────────
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    best_val_acc = 0.0
    history: list[dict] = []

    for epoch in range(1, epochs + 1):
        model.train()
        train_loss, train_correct = 0.0, 0
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)
            optimizer.zero_grad()
            loss = criterion(model(images), labels)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * images.size(0)
            train_correct += (model(images).argmax(1) == labels).sum().item()
        scheduler.step()

        train_loss /= len(train_ds)
        train_acc = train_correct / len(train_ds)

        model.eval()
        val_loss, val_correct = 0.0, 0
        with torch.no_grad():
            for images, labels in val_loader:
                images, labels = images.to(device), labels.to(device)
                out = model(images)
                val_loss += criterion(out, labels).item() * images.size(0)
                val_correct += (out.argmax(1) == labels).sum().item()
        val_loss /= len(val_ds)
        val_acc = val_correct / len(val_ds)

        row = {
            "epoch": epoch,
            "train_loss": round(train_loss, 4),
            "train_acc": round(train_acc, 4),
            "val_loss": round(val_loss, 4),
            "val_acc": round(val_acc, 4),
        }
        history.append(row)
        print(
            f"Epoch {epoch:3d}/{epochs} | "
            f"loss {train_loss:.4f} acc {train_acc:.4f} | "
            f"val_loss {val_loss:.4f} val_acc {val_acc:.4f}"
        )

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            ckpt_path = Path(output_dir) / "kulimaiq_mobilenet.pth"
            torch.save(
                {
                    "model_state_dict": model.state_dict(),
                    "classes": classes,          # ← saved in checkpoint
                    "num_classes": num_classes,
                    "epoch": epoch,
                    "val_acc": val_acc,
                },
                ckpt_path,
            )
            print(f"  ✓ Saved best (val_acc={val_acc:.4f}) → {ckpt_path}")

    Path(output_dir, "training_history.json").write_text(
        json.dumps(history, indent=2)
    )
    # Also save class list as standalone JSON for easy reference
    Path(output_dir, "classes.json").write_text(json.dumps(classes, indent=2))
    print(f"[train] Done. Best val acc: {best_val_acc:.4f}")
    print(f"[train] Classes saved to {output_dir}/classes.json")


def main() -> None:
    p = argparse.ArgumentParser(description="Train KulimaIQ disease CNN")
    p.add_argument("--data_dir", default="data")
    p.add_argument("--output_dir", default="model_weights")
    p.add_argument("--epochs", type=int, default=30)
    p.add_argument("--batch_size", type=int, default=32)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--freeze_backbone", action="store_true")
    p.add_argument("--device", default="auto",
                   choices=["auto", "cpu", "cuda", "mps"])
    args = p.parse_args()
    train(
        data_dir=args.data_dir,
        output_dir=args.output_dir,
        epochs=args.epochs,
        batch_size=args.batch_size,
        lr=args.lr,
        freeze_backbone=args.freeze_backbone,
        device_str=args.device,
    )


if __name__ == "__main__":
    main()
