"""
Location-shift robustness evaluation.

Measures a checkpoint's accuracy on the clean validation set and on each
simulated agro-ecological location domain (highland/lowland/humid/dry). This
quantifies how well the model detects disease "in whatever location" from the
leaf alone — the core claim of the strengthened model.

Usage:
    python -m scripts.eval_robustness --weights model_weights/kulimaiq_mobilenet.pth
    python -m scripts.eval_robustness --compare   # baseline vs current side-by-side
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import torch
from torch.utils.data import DataLoader
from torchvision import datasets

from app.ml.agro_style import EVAL_DOMAIN_NAMES, build_eval_domain_transform
from app.ml.dataset import val_transform
from app.ml.model import load_model

DATA_VAL = Path(__file__).resolve().parents[1] / "data" / "val"


def _device() -> torch.device:
    if torch.cuda.is_available():
        return torch.device("cuda")
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


@torch.no_grad()
def _acc(model, loader, device) -> float:
    correct = total = 0
    for images, labels in loader:
        images, labels = images.to(device), labels.to(device)
        correct += (model(images).argmax(1) == labels).sum().item()
        total += labels.size(0)
    return correct / max(total, 1)


def evaluate(weights: str) -> dict:
    device = _device()
    model, _ = load_model(weights, device=str(device))
    model.to(device)

    clean = DataLoader(datasets.ImageFolder(str(DATA_VAL), transform=val_transform),
                       batch_size=32, num_workers=0)
    results = {"clean": _acc(model, clean, device)}
    for name in EVAL_DOMAIN_NAMES:
        dl = DataLoader(
            datasets.ImageFolder(str(DATA_VAL),
                                 transform=build_eval_domain_transform(name)),
            batch_size=32, num_workers=0,
        )
        results[name] = _acc(model, dl, device)
    shifts = [results[n] for n in EVAL_DOMAIN_NAMES]
    results["shift_mean"] = sum(shifts) / len(shifts)
    results["shift_worst"] = min(shifts)
    return results


def _print_table(title: str, r: dict) -> None:
    print(f"\n{title}")
    print("-" * 52)
    print(f"  {'clean':<26} {r['clean']:6.1%}")
    for n in EVAL_DOMAIN_NAMES:
        print(f"  {n:<26} {r[n]:6.1%}")
    print("-" * 52)
    print(f"  {'shift mean':<26} {r['shift_mean']:6.1%}")
    print(f"  {'shift worst':<26} {r['shift_worst']:6.1%}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--weights", default="model_weights/kulimaiq_mobilenet.pth")
    p.add_argument("--compare", action="store_true",
                   help="Compare baseline vs current deployed model")
    args = p.parse_args()

    base = Path(__file__).resolve().parents[1]
    if args.compare:
        baseline = str(base / "model_weights" / "kulimaiq_mobilenet_baseline.pth")
        current = str(base / "model_weights" / "kulimaiq_mobilenet.pth")
        rb = evaluate(baseline)
        rc = evaluate(current)
        _print_table("BASELINE (image-only, standard training)", rb)
        _print_table("STRENGTHENED (location-invariant training)", rc)
        print("\nDelta (strengthened − baseline)")
        print("-" * 52)
        for k in ["clean", *EVAL_DOMAIN_NAMES, "shift_mean", "shift_worst"]:
            d = rc[k] - rb[k]
            print(f"  {k:<26} {d:+6.1%}")
    else:
        _print_table(f"Robustness: {args.weights}", evaluate(args.weights))


if __name__ == "__main__":
    main()
