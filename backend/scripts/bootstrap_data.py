#!/usr/bin/env python3
"""
bootstrap_data.py — Quick-start data setup.

Tries two strategies in order:

  1. Download PlantVillage from HuggingFace (real images — best for training).
  2. Generate synthetic placeholder images (solid-colour patches) so the
     training pipeline can be tested end-to-end without internet access.

Run from the backend/ directory:

    python scripts/bootstrap_data.py

Options:
    --data_dir      Output directory (default: data)
    --val_split     Fraction held out for validation (default: 0.2)
    --limit         Cap images per class (default: 500 real, 60 synthetic)
    --synthetic     Force synthetic mode (skip HuggingFace attempt)

After this script succeeds you can train immediately:

    python -m app.ml.train --data_dir data --epochs 30 --batch_size 32
"""

import argparse
import io
import os
import random
import shutil
from pathlib import Path

# ── Helpers ────────────────────────────────────────────────────────────────────

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Missing Pillow — run: pip install Pillow")

SUPPORTED_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def is_image(p: Path) -> bool:
    return p.suffix.lower() in SUPPORTED_EXTS


def copy_split(images, train_dir: Path, val_dir: Path,
               class_name: str, val_split: float) -> int:
    """Copy/save a list of PIL images into train/val class folders."""
    random.shuffle(images)
    n_val = max(1, int(len(images) * val_split))
    splits = {"val": images[:n_val], "train": images[n_val:]}
    total = 0
    for split, imgs in splits.items():
        dest = (train_dir if split == "train" else val_dir) / class_name
        dest.mkdir(parents=True, exist_ok=True)
        for i, item in enumerate(imgs):
            if isinstance(item, Path):
                shutil.copy2(item, dest / item.name)
            else:
                item.convert("RGB").save(dest / f"{class_name}_{split}_{i:05d}.jpg")
            total += 1
    return total


# ── Strategy 1 — HuggingFace PlantVillage ─────────────────────────────────────

# Map HuggingFace label names → our folder naming convention
_PV_MAP = {
    # Healthy
    "Apple___healthy": "healthy",
    "Blueberry___healthy": "healthy",
    "Cherry_(including_sour)___healthy": "healthy",
    "Corn_(maize)___healthy": "healthy",
    "Grape___healthy": "healthy",
    "Orange___healthy": "healthy",
    "Peach___healthy": "healthy",
    "Pepper,_bell___healthy": "healthy",
    "Potato___healthy": "healthy",
    "Raspberry___healthy": "healthy",
    "Soybean___healthy": "healthy",
    "Strawberry___healthy": "healthy",
    "Tomato___healthy": "healthy",
    # Apple
    "Apple___Apple_scab": "apple_scab",
    "Apple___Black_rot": "apple_black_rot",
    "Apple___Cedar_apple_rust": "apple_cedar_rust",
    # Cherry
    "Cherry_(including_sour)___Powdery_mildew": "cherry_powdery_mildew",
    # Corn / Maize
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": "maize_gray_leaf_spot",
    "Corn_(maize)___Common_rust_": "maize_common_rust",
    "Corn_(maize)___Northern_Leaf_Blight": "maize_northern_leaf_blight",
    # Grape
    "Grape___Black_rot": "grape_black_rot",
    "Grape___Esca_(Black_Measles)": "grape_esca",
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": "grape_leaf_blight",
    # Orange
    "Orange___Haunglongbing_(Citrus_greening)": "citrus_greening",
    # Peach
    "Peach___Bacterial_spot": "peach_bacterial_spot",
    # Pepper
    "Pepper,_bell___Bacterial_spot": "pepper_bacterial_spot",
    # Potato
    "Potato___Early_blight": "potato_early_blight",
    "Potato___Late_blight": "potato_late_blight",
    # Squash
    "Squash___Powdery_mildew": "squash_powdery_mildew",
    # Strawberry
    "Strawberry___Leaf_scorch": "strawberry_leaf_scorch",
    # Tomato
    "Tomato___Bacterial_spot": "tomato_bacterial_spot",
    "Tomato___Early_blight": "tomato_early_blight",
    "Tomato___Late_blight": "tomato_late_blight",
    "Tomato___Leaf_Mold": "tomato_leaf_mold",
    "Tomato___Septoria_leaf_spot": "tomato_septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite": "tomato_spider_mites",
    "Tomato___Target_Spot": "tomato_target_spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": "tomato_yellow_leaf_curl_virus",
    "Tomato___Tomato_mosaic_virus": "tomato_mosaic_virus",
}


def download_plantvillage(train_dir: Path, val_dir: Path,
                          val_split: float, limit: int) -> bool:
    """Download PlantVillage via HuggingFace datasets. Returns True on success."""
    print("  Trying HuggingFace PlantVillage download …")
    try:
        from datasets import load_dataset
    except ImportError:
        print("  [SKIP] `datasets` package not installed.")
        print("         Run: pip install datasets   then try again.")
        return False

    # Two possible HF dataset IDs for PlantVillage
    candidates = [
        "Multimodal-Fatima/PlantVillage_train",
        "dataset-research/PlantVillage-Dataset",
        "Francesco/PlantVillage-Dataset",
    ]
    ds = None
    for hf_id in candidates:
        try:
            print(f"  Trying {hf_id} …")
            ds = load_dataset(hf_id, split="train", trust_remote_code=True)
            print(f"  Loaded {len(ds)} samples from {hf_id}")
            break
        except Exception as e:
            print(f"  Could not load {hf_id}: {e}")

    if ds is None:
        print("  [FAIL] Could not load any PlantVillage variant from HuggingFace.")
        return False

    # Determine label column name
    label_col = "label" if "label" in ds.features else "labels"
    label_names = ds.features[label_col].names

    buckets: dict[str, list] = {}
    for item in ds:
        label_name = label_names[item[label_col]]
        mapped = _PV_MAP.get(label_name)
        if mapped:
            if limit and len(buckets.get(mapped, [])) >= limit:
                continue
            img = item.get("image") or item.get("img")
            if img is not None:
                buckets.setdefault(mapped, []).append(img)

    if not buckets:
        print("  [FAIL] No images mapped — label names may have changed.")
        return False

    print(f"  Saving {sum(len(v) for v in buckets.values())} images …")
    for class_name, pil_images in sorted(buckets.items()):
        n = copy_split(pil_images, train_dir, val_dir, class_name, val_split)
        print(f"    {class_name}: {n} images")

    return True


# ── Strategy 2 — Synthetic placeholder images ─────────────────────────────────

# Important classes that are representative for training pipeline testing
_SYNTHETIC_CLASSES = [
    # Cassava
    "healthy", "cassava_mosaic", "cassava_brown_streak",
    # Maize
    "maize_necrosis", "maize_common_rust", "maize_gray_leaf_spot",
    # Banana
    "banana_wilt", "banana_sigatoka",
    # Tomato
    "tomato_late_blight", "tomato_early_blight", "tomato_leaf_mold",
    "tomato_yellow_leaf_curl_virus",
    # Potato
    "potato_late_blight", "potato_early_blight",
    # Bean
    "bean_angular_spot", "bean_rust",
    # Coffee
    "coffee_leaf_rust", "coffee_berry_disease",
    # Rice
    "rice_blast", "rice_brown_spot",
]

# Colour palette: each class gets a unique hue so the model can learn something
# (synthetic training proves the pipeline, not real disease detection)
_CLASS_COLORS = {
    cls: (
        (hash(cls) % 200 + 20),
        (hash(cls * 2) % 200 + 20),
        (hash(cls * 3) % 200 + 20),
    )
    for cls in _SYNTHETIC_CLASSES
}


def _make_synthetic_image(base_color: tuple, size: int = 224) -> Image.Image:
    """Create a 224×224 image with noise around a base hue."""
    import numpy as np
    r, g, b = base_color
    noise = np.random.randint(-40, 40, (size, size, 3), dtype=np.int16)
    arr = np.clip(
        np.array([r, g, b], dtype=np.int16) + noise, 0, 255
    ).astype("uint8")
    return Image.fromarray(arr, "RGB")


def generate_synthetic(train_dir: Path, val_dir: Path,
                        val_split: float, per_class: int) -> None:
    """Generate per_class synthetic images for each disease class."""
    print(f"  Generating {per_class} synthetic images × {len(_SYNTHETIC_CLASSES)} classes …")
    for class_name in _SYNTHETIC_CLASSES:
        color = _CLASS_COLORS[class_name]
        images = [_make_synthetic_image(color) for _ in range(per_class)]
        n = copy_split(images, train_dir, val_dir, class_name, val_split)
        print(f"    {class_name}: {n} synthetic images")
    print()
    print("  ⚠ Synthetic data trains the PIPELINE, not real disease detection.")
    print("    Run scripts/prepare_data.py with real images before deployment.")


# ── Main ───────────────────────────────────────────────────────────────────────

def main(data_dir: str = "data", val_split: float = 0.2,
         limit: int = 500, synthetic: bool = False) -> None:
    random.seed(42)
    base = Path(data_dir)
    train_dir = base / "train"
    val_dir = base / "val"
    train_dir.mkdir(parents=True, exist_ok=True)
    val_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 58)
    print("KulimaIQ — Quick-start data bootstrap")
    print(f"Output : {base.resolve()}")
    print("=" * 58)

    # Check whether train already has classes
    existing = [d for d in train_dir.iterdir() if d.is_dir()]
    if existing:
        print(f"\n  data/train already has {len(existing)} class folders.")
        answer = input("  Re-download / re-generate? [y/N] ").strip().lower()
        if answer != "y":
            print("  Keeping existing data. Exiting.")
            return
        shutil.rmtree(train_dir)
        shutil.rmtree(val_dir)
        train_dir.mkdir(parents=True, exist_ok=True)
        val_dir.mkdir(parents=True, exist_ok=True)

    success = False
    if not synthetic:
        success = download_plantvillage(
            train_dir, val_dir, val_split, limit
        )

    if not success:
        print("\n  Falling back to synthetic images …")
        per_class = min(limit, 80)
        generate_synthetic(train_dir, val_dir, val_split, per_class)

    # Summary
    classes = sorted(d.name for d in train_dir.iterdir() if d.is_dir())
    total = sum(
        sum(1 for f in (train_dir / c).rglob("*") if is_image(f))
        for c in classes
    )
    print(f"\n  ✓ {len(classes)} classes, {total} total images ready in {base}")
    print(f"\nNext step:")
    print(f"  cd backend && python -m app.ml.train \\")
    print(f"      --data_dir {data_dir} --epochs 30 --batch_size 32")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(
        description="Bootstrap KulimaIQ training data"
    )
    ap.add_argument("--data_dir", default="data",
                    help="Output root directory (default: data)")
    ap.add_argument("--val_split", type=float, default=0.2,
                    help="Validation fraction (default: 0.2)")
    ap.add_argument("--limit", type=int, default=500,
                    help="Max images per class from HuggingFace (default: 500)")
    ap.add_argument("--synthetic", action="store_true",
                    help="Skip HuggingFace, generate synthetic images only")
    args = ap.parse_args()
    main(
        data_dir=args.data_dir,
        val_split=args.val_split,
        limit=args.limit,
        synthetic=args.synthetic,
    )
