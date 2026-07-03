#!/usr/bin/env python3
"""
prepare_data.py — Build the KulimaIQ training dataset.

Covers 30+ disease classes across 15+ crops.  Run from the backend/ folder:

    pip install -r scripts/requirements_data.txt
    python scripts/prepare_data.py [--data_dir data] [--val_split 0.2]

Automatic downloads (no account needed)
─────────────────────────────────────────
  • PlantVillage        — HuggingFace `dataset-research/PlantVillage-Dataset`
                          38 classes across 14 crops

Manual downloads (free registration required)
──────────────────────────────────────────────
  • Cassava CMD/CBSD/CBB (iCassava 2019)
      https://www.kaggle.com/c/cassava-disease/data
      Set KAGGLE_USERNAME + KAGGLE_KEY or place cassava-disease.zip here.

  • Bean Angular Spot & Bean Rust (iBean 2020)
      https://www.kaggle.com/datasets/marquis03/bean-leaf-lesions-classification
      or Makerere AI Health Lab dataset. Place ibean.zip here.

  • Rice Diseases (Bangladesh / Roboflow)
      https://www.kaggle.com/datasets/shayanriyaz/riceleafs
      Place riceleafs.zip here.

  • Maize Diseases (PlantDoc / Mendeley)
      https://www.kaggle.com/datasets/nafisur/corn-leaf-infection-dataset
      Place corn-leaf.zip here.

  • Banana Diseases (BananaLeaf dataset)
      https://www.kaggle.com/datasets/noulam/banana-disease-recognition
      Place banana-disease.zip here.

  • Coffee Diseases
      https://www.kaggle.com/datasets/jonathansilva2020/coffee-leaf-diseases-dataset
      Place coffee-diseases.zip here.

  • Sorghum / Wheat / Tomato / Potato supplements
      https://www.kaggle.com/datasets/vipoooool/new-plant-diseases-dataset
      (This is the full PlantVillage mirror — covers potato, tomato, etc.)
      Place new-plant-diseases.zip here.

After running the script, verify counts:

    find data/train -type d | sort
    find data/train -type f | wc -l

Naming convention for class folders
──────────────────────────────────────
    {crop}_{condition}    →  tomato_late_blight
    healthy               →  single shared "healthy" bucket

All classes are automatically picked up by the training script via
torchvision.datasets.ImageFolder.

Multi-location merge
────────────────────
Each public dataset comes from different regions / field conditions. Images
from every source that map to the same KulimaIQ slug (e.g. tomato_late_blight
from PlantVillage USA + Bangladesh field photos) are copied into ONE class
folder. Filenames are prefixed with the source id so nothing is overwritten.
This teaches the model: same disease label, many location appearances.
"""

import argparse
import os
import random
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Optional


def _load_backend_env() -> None:
    """Load HF_TOKEN / Kaggle creds from backend/.env for dataset scripts."""
    try:
        from dotenv import load_dotenv
    except ImportError:
        return
    env_path = Path(__file__).resolve().parents[1] / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    token = os.environ.get("HF_TOKEN", "").strip()
    if token:
        os.environ.setdefault("HUGGINGFACE_HUB_TOKEN", token)
        os.environ.setdefault("HF_HUB_ENABLE_HF_TRANSFER", "1")

# Deployed KulimaIQ model classes (East-Africa priority). Use --core-only to
# train only these slugs while still merging all regional sources into each.
CORE_CLASSES = frozenset({
    "banana_sigatoka", "banana_wilt", "bean_angular_spot", "bean_rust",
    "cassava_brown_streak", "cassava_mosaic", "coffee_berry_disease",
    "coffee_leaf_rust", "healthy", "maize_common_rust", "maize_gray_leaf_spot",
    "maize_necrosis", "potato_early_blight", "potato_late_blight",
    "rice_blast", "rice_brown_spot", "tomato_early_blight", "tomato_late_blight",
    "tomato_leaf_mold", "tomato_yellow_leaf_curl_virus",
})

try:
    from PIL import Image
    from tqdm import tqdm
except ImportError:
    raise SystemExit("Missing deps — run: pip install -r scripts/requirements_data.txt")

# ── Helpers ───────────────────────────────────────────────────────────────────

SUPPORTED_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def is_image(path: Path) -> bool:
    return path.suffix.lower() in SUPPORTED_EXTS


def _is_valid_image_file(path: Path, min_bytes: int = 512) -> bool:
    """Skip HF .no_exist placeholders and other empty/corrupt files."""
    try:
        if not path.is_file() or path.stat().st_size < min_bytes:
            return False
        with Image.open(path) as im:
            im.verify()
        return True
    except Exception:
        return False


def _safe_name(source: str, original: str, index: int) -> str:
    """Unique filename when merging many regional sources into one class folder."""
    stem = re.sub(r"[^a-zA-Z0-9._-]+", "_", Path(original).stem)[:80]
    ext = Path(original).suffix.lower() or ".jpg"
    return f"{source}_{stem}_{index:05d}{ext}"


def _coerce_pil(img) -> Image.Image | None:
    """Normalize HF / path / array image fields to RGB PIL."""
    if img is None:
        return None
    if isinstance(img, Image.Image):
        return img.convert("RGB")
    if isinstance(img, str):
        try:
            return Image.open(img).convert("RGB")
        except Exception:
            return None
    try:
        import numpy as np
        return Image.fromarray(np.array(img)).convert("RGB")
    except Exception:
        return None


def _count_class_images(train_dir: Path, val_dir: Path, class_name: str) -> int:
    n = 0
    for root in (train_dir, val_dir):
        d = root / class_name
        if d.is_dir():
            n += sum(1 for p in d.rglob("*") if is_image(p) and _is_valid_image_file(p))
    return n


def _class_counts(train_dir: Path, val_dir: Path, classes: set[str]) -> dict[str, int]:
    return {c: _count_class_images(train_dir, val_dir, c) for c in classes}


def materialize_plantvillage_from_cache(
    cache_dir: Path,
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    source: str = "plantvillage",
) -> dict[str, int]:
    """Copy already-downloaded HF cache files into train/val (no re-download)."""
    per_class = limit or 500
    needed = set(PLANTVILLAGE_CLASS_MAP.values()) & CORE_CLASSES
    existing = _class_counts(train_dir, val_dir, needed)
    by_class: dict[str, list[Path]] = {c: [] for c in needed}

    if not cache_dir.exists():
        return {}

    for p in cache_dir.rglob("*"):
        if not is_image(p) or not _is_valid_image_file(p):
            continue
        if "/color/" not in p.as_posix():
            continue
        folder = p.as_posix().split("/color/")[-1].split("/")[0]
        mapped = PLANTVILLAGE_CLASS_MAP.get(folder)
        if mapped not in needed:
            continue
        room = per_class - existing.get(mapped, 0) - len(by_class[mapped])
        if room <= 0:
            continue
        by_class[mapped].append(p)

    saved: dict[str, int] = {}
    for class_name, paths in sorted(by_class.items()):
        if not paths:
            continue
        random.shuffle(paths)
        room = max(0, per_class - existing.get(class_name, 0))
        paths = paths[:room]
        if not paths:
            continue
        n_val = max(1, int(len(paths) * val_split))
        splits = {"val": paths[:n_val], "train": paths[n_val:]}
        total = 0
        for split, files in splits.items():
            dest = (train_dir if split == "train" else val_dir) / class_name
            dest.mkdir(parents=True, exist_ok=True)
            for i, src in enumerate(files):
                shutil.copy2(src, dest / _safe_name(source, src.name, i))
                total += 1
        saved[class_name] = total
        print(f"    {source} (cache) → {class_name}: {total} images")
    return saved


def _make_synthetic_image(base_color: tuple, size: int = 224) -> Image.Image:
    import numpy as np
    r, g, b = base_color
    noise = np.random.randint(-40, 40, (size, size, 3), dtype=np.int16)
    arr = np.clip(np.array([r, g, b], dtype=np.int16) + noise, 0, 255).astype("uint8")
    return Image.fromarray(arr, "RGB")


def fill_core_gaps_synthetic(
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    per_class: int,
    min_required: int = 40,
    allow_synthetic: bool = True,
) -> None:
    """Add synthetic placeholders ONLY for core classes still below min_required."""
    if not allow_synthetic:
        short = [
            c for c in sorted(CORE_CLASSES)
            if _count_class_images(train_dir, val_dir, c) < min_required
        ]
        if short:
            print(f"  [WARN] {len(short)} classes below {min_required} real images (no synthetic): "
                  f"{', '.join(short[:6])}{'…' if len(short) > 6 else ''}")
        return
    _purge_invalid_images(train_dir, val_dir)
    colors = {
        cls: (
            (hash(cls) % 200 + 20),
            (hash(cls * 2) % 200 + 20),
            (hash(cls * 3) % 200 + 20),
        )
        for cls in CORE_CLASSES
    }
    for class_name in sorted(CORE_CLASSES):
        have = _count_class_images(train_dir, val_dir, class_name)
        need = max(0, min(per_class, min_required) - have)
        if need <= 0:
            continue
        imgs = [_make_synthetic_image(colors[class_name]) for _ in range(need)]
        n = save_pil_batch(imgs, train_dir, val_dir, class_name, val_split, "synthetic_fill", None)
        print(f"    synthetic_fill → {class_name}: +{n} images (had {have}, target {min_required})")


def _purge_invalid_images(train_dir: Path, val_dir: Path) -> int:
    """Remove empty or unreadable images (e.g. HF .no_exist placeholders)."""
    removed = 0
    for root in (train_dir, val_dir):
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if not is_image(p):
                continue
            if not _is_valid_image_file(p):
                p.unlink(missing_ok=True)
                removed += 1
    if removed:
        print(f"  Removed {removed} invalid/empty image files")
    return removed


def copy_images(
    src_dir: Path,
    dest_train: Path,
    dest_val: Path,
    class_name: str,
    val_split: float = 0.2,
    limit: Optional[int] = None,
    source: str = "local",
    class_cap: Optional[int] = None,
) -> int:
    """Copy images from src_dir into dest_{train,val}/class_name."""
    existing = _count_class_images(dest_train, dest_val, class_name)
    if class_cap is not None and existing >= class_cap:
        return 0

    files = [p for p in src_dir.rglob("*") if is_image(p) and _is_valid_image_file(p)]
    if not files:
        print(f"  [WARN] No valid images found in {src_dir}")
        return 0

    random.shuffle(files)
    max_take = len(files)
    if limit:
        max_take = min(max_take, limit)
    if class_cap is not None:
        max_take = min(max_take, class_cap - existing)
    if max_take <= 0:
        return 0
    files = files[:max_take]

    n_val = max(1, int(len(files) * val_split))
    splits = {"val": files[:n_val], "train": files[n_val:]}

    total = 0
    for split, images in splits.items():
        dest = (dest_train if split == "train" else dest_val) / class_name
        dest.mkdir(parents=True, exist_ok=True)
        for i, img_path in enumerate(tqdm(images, desc=f"  {source}/{class_name}/{split}", leave=False)):
            out_name = _safe_name(source, img_path.name, i)
            shutil.copy2(img_path, dest / out_name)
            total += 1
    return total


def save_pil_batch(
    images: list,
    dest_train: Path,
    dest_val: Path,
    class_name: str,
    val_split: float,
    source: str,
    limit: Optional[int] = None,
) -> int:
    """Save PIL images from HuggingFace into train/val with source-prefixed names."""
    if limit:
        images = images[:limit]
    random.shuffle(images)
    if not images:
        return 0
    n_val = max(1, int(len(images) * val_split))
    splits = {"val": images[:n_val], "train": images[n_val:]}
    total = 0
    for split, imgs in splits.items():
        dest = (dest_train if split == "train" else dest_val) / class_name
        dest.mkdir(parents=True, exist_ok=True)
        for i, img in enumerate(tqdm(imgs, desc=f"  {source}/{class_name}/{split}", leave=False)):
            pil = _coerce_pil(img)
            if pil is None:
                continue
            pil.save(dest / _safe_name(source, f"img_{i}.jpg", i))
            total += 1
    return total


def unzip(zip_path: Path, out_dir: Path) -> None:
    print(f"  Extracting {zip_path.name} …")
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(out_dir)


# ── PlantVillage (HuggingFace) ────────────────────────────────────────────────

# Map PlantVillage class folder names → our naming convention
PLANTVILLAGE_CLASS_MAP: dict[str, str] = {
    # Healthy classes grouped into shared "healthy" bucket
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


def _find_kaggle_pv_root(scripts_dir: Path) -> Path | None:
    """Locate extracted vipoooool/new-plant-diseases-dataset (PlantVillage mirror)."""
    candidates = [
        scripts_dir / "New Plant Diseases Dataset(Augmented)" / "New Plant Diseases Dataset(Augmented)",
        scripts_dir / "new-plant-diseases",
        scripts_dir / "PlantVillage",
    ]
    for root in candidates:
        train = root / "train"
        if train.is_dir() and any(train.iterdir()):
            return root
    for p in scripts_dir.iterdir():
        if not p.is_dir():
            continue
        inner = p / p.name if (p / p.name).is_dir() else p
        train = inner / "train"
        if train.is_dir() and any(d.name in PLANTVILLAGE_CLASS_MAP for d in train.iterdir() if d.is_dir()):
            return inner
    return None


def process_kaggle_class_folders(
    src_train: Path,
    src_val: Path | None,
    folder_map: dict[str, str],
    dest_train: Path,
    dest_val: Path,
    limit: Optional[int],
    source: str,
    class_cap: Optional[int] = None,
) -> None:
    """Copy images from Kaggle layouts like train/{class_name}/*.jpg."""
    for folder_name, class_name in folder_map.items():
        total = 0
        for split, src_root in (("train", src_train), ("val", src_val or src_train)):
            src = src_root / folder_name
            if not src.is_dir():
                continue
            existing = _count_class_images(dest_train, dest_val, class_name)
            if class_cap is not None and existing >= class_cap:
                break
            files = [p for p in src.rglob("*") if is_image(p) and _is_valid_image_file(p)]
            random.shuffle(files)
            cap = limit or len(files)
            if class_cap is not None:
                cap = min(cap, max(0, class_cap - existing))
            files = files[:cap]
            dest = (dest_train if split == "train" else dest_val) / class_name
            dest.mkdir(parents=True, exist_ok=True)
            for i, fp in enumerate(files):
                shutil.copy2(fp, dest / _safe_name(source, fp.name, i))
                total += 1
                existing += 1
                if class_cap is not None and existing >= class_cap:
                    break
        if total:
            print(f"    {source}/{folder_name} → {class_name}: {total} images")


CASSAVA_KAGGLE_LABEL_MAP = {
    0: None,  # bacterial blight — not a core slug
    1: "cassava_brown_streak",
    2: None,  # green mottle
    3: "cassava_mosaic",
    4: "healthy",
}


def _is_cassava_kaggle_csv(scripts_dir: Path) -> bool:
    """True if train.csv looks like cassava-leaf-disease (labels 0–4), not iBean (0–2)."""
    csv_path = scripts_dir / "train.csv"
    if not csv_path.exists():
        return False
    labels: set[int] = set()
    for line in csv_path.read_text().splitlines()[1:21]:
        parts = line.strip().split(",")
        if len(parts) < 2:
            continue
        try:
            labels.add(int(parts[1]))
        except ValueError:
            continue
    return 3 in labels or 4 in labels


def process_cassava_kaggle_csv(
    scripts_dir: Path,
    dest_train: Path,
    dest_val: Path,
    limit: Optional[int],
    class_cap: Optional[int] = None,
) -> None:
    """Process abdallahalidev/cassava-leaf-disease-classification (train.csv + images)."""
    for csv_name, split in (("train.csv", "train"), ("val.csv", "val")):
        csv_path = scripts_dir / csv_name
        if not csv_path.exists():
            continue
        dest_root = dest_train if split == "train" else dest_val
        per_class: dict[str, list[Path]] = {}
        for line in csv_path.read_text().splitlines()[1:]:
            if not line.strip():
                continue
            parts = line.split(",")
            if len(parts) < 2:
                continue
            rel = parts[0].strip()
            try:
                label = int(parts[1].strip())
            except ValueError:
                continue
            slug = CASSAVA_KAGGLE_LABEL_MAP.get(label)
            if not slug:
                continue
            img = scripts_dir / rel
            if not img.is_file() or not _is_valid_image_file(img):
                continue
            per_class.setdefault(slug, []).append(img)

        for slug, files in sorted(per_class.items()):
            existing = _count_class_images(dest_train, dest_val, slug)
            if class_cap is not None and existing >= class_cap:
                continue
            random.shuffle(files)
            cap = limit or len(files)
            if class_cap is not None:
                cap = min(cap, max(0, class_cap - existing))
            files = files[:cap]
            dest = dest_root / slug
            dest.mkdir(parents=True, exist_ok=True)
            n = 0
            for i, fp in enumerate(files):
                shutil.copy2(fp, dest / _safe_name("cassava_ea", fp.name, i))
                n += 1
            if n:
                print(f"    cassava_ea/{split} → {slug}: {n} images")


def process_plantvillage(
    pv_root: Path,
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    class_cap: Optional[int] = None,
) -> None:
    """Process an extracted PlantVillage dataset tree."""
    segment_dirs: list[Path] = []
    for sub in ("train", "valid", "validation", "test", "color"):
        sub_root = pv_root / sub
        if sub_root.is_dir():
            segment_dirs.extend(
                d for d in sub_root.iterdir()
                if d.is_dir() and d.name in PLANTVILLAGE_CLASS_MAP
            )
    if not segment_dirs:
        segment_dirs = [
            d for d in pv_root.rglob("*")
            if d.is_dir() and d.name in PLANTVILLAGE_CLASS_MAP and d.parent.name in {
                "train", "valid", "validation", "test", "color",
            }
        ]
    if not segment_dirs:
        for d in pv_root.iterdir():
            if d.is_dir():
                segment_dirs = [
                    s for s in d.iterdir()
                    if s.is_dir() and s.name in PLANTVILLAGE_CLASS_MAP
                ]
                if segment_dirs:
                    break
    if not segment_dirs:
        print("[WARN] Could not locate PlantVillage class folders. Skipping.")
        return

    print(f"  Found {len(segment_dirs)} PlantVillage class folders")
    for src in sorted(segment_dirs):
        target_class = PLANTVILLAGE_CLASS_MAP[src.name]
        n = copy_images(
            src, train_dir, val_dir, target_class, val_split, limit,
            source="plantvillage", class_cap=class_cap,
        )
        if n:
            print(f"    plantvillage/{src.name} → {target_class}: {n} images")


PLANTVILLAGE_HF_DATASETS = [
    ("mohanty/PlantVillage", "default"),
    ("Multimodal-Fatima/PlantVillage_train", None),
    ("Francesco/PlantVillage-Dataset", None),
]

# Fallback when builder metadata is unavailable (matches mohanty/PlantVillage HF script)
PLANTVILLAGE_LABEL_NAMES = [
    "Apple___Apple_scab", "Apple___Black_rot", "Apple___Cedar_apple_rust", "Apple___healthy",
    "Blueberry___healthy", "Cherry_(including_sour)___Powdery_mildew", "Cherry_(including_sour)___healthy",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot", "Corn_(maize)___Common_rust_",
    "Corn_(maize)___Northern_Leaf_Blight", "Corn_(maize)___healthy",
    "Grape___Black_rot", "Grape___Esca_(Black_Measles)", "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
    "Grape___healthy", "Orange___Haunglongbing_(Citrus_greening)", "Peach___Bacterial_spot",
    "Peach___healthy", "Pepper,_bell___Bacterial_spot", "Pepper,_bell___healthy",
    "Potato___Early_blight", "Potato___Late_blight", "Potato___healthy", "Raspberry___healthy",
    "Soybean___healthy", "Squash___Powdery_mildew", "Strawberry___Leaf_scorch", "Strawberry___healthy",
    "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight", "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot", "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy",
]


def download_plantvillage_targeted(
    data_dir: Path,
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    class_cap: Optional[int],
) -> None:
    """Download core PlantVillage classes via HF split lists (no 130k stream scan)."""
    try:
        from huggingface_hub import hf_hub_download
    except ImportError:
        print("[SKIP] huggingface_hub not installed.")
        return

    pv_cache = data_dir / "_hf_plantvillage"
    pv_cache.mkdir(exist_ok=True)
    hf_repo = "mohanty/PlantVillage"
    per_class_cap = class_cap or 500
    needed = set(PLANTVILLAGE_CLASS_MAP.values()) & CORE_CLASSES
    token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_HUB_TOKEN")

    counts = _class_counts(train_dir, val_dir, needed)
    folders_wanted = {
        folder
        for folder, slug in PLANTVILLAGE_CLASS_MAP.items()
        if slug in needed and counts.get(slug, 0) < per_class_cap
    }
    if not folders_wanted:
        return

    print(f"  Targeted HF download for {len(folders_wanted)} PV folders (cap {per_class_cap}/class) …")
    by_folder: dict[str, list[str]] = {f: [] for f in folders_wanted}
    try:
        for split_file in ("splits/color_train.txt", "splits/color_test.txt"):
            local = hf_hub_download(
                repo_id=hf_repo,
                filename=split_file,
                repo_type="dataset",
                cache_dir=str(pv_cache),
                token=token or None,
            )
            for line in Path(local).read_text().splitlines():
                rel = line.strip()
                if not rel or "color/" not in rel:
                    continue
                folder = rel.split("color/")[-1].split("/")[0]
                if folder in by_folder:
                    by_folder[folder].append(rel)
    except Exception as e:
        print(f"[WARN] Could not read PlantVillage split lists: {e}")
        return

    idx = {c: 0 for c in needed}
    for folder in sorted(by_folder.keys()):
        slug = PLANTVILLAGE_CLASS_MAP[folder]
        paths = by_folder[folder]
        random.shuffle(paths)
        saved = 0
        for rel_path in tqdm(paths, desc=f"  plantvillage/{folder[:28]}", leave=False):
            counts = _class_counts(train_dir, val_dir, needed)
            if counts.get(slug, 0) >= per_class_cap:
                break
            try:
                local = hf_hub_download(
                    repo_id=hf_repo,
                    filename=rel_path,
                    repo_type="dataset",
                    cache_dir=str(pv_cache),
                    token=token or None,
                )
                src = Path(local)
                if not _is_valid_image_file(src):
                    continue
                split = "val" if random.random() < val_split else "train"
                dest = (val_dir if split == "val" else train_dir) / slug
                dest.mkdir(parents=True, exist_ok=True)
                i = idx[slug]
                idx[slug] += 1
                shutil.copy2(src, dest / _safe_name("plantvillage", src.name, i))
                saved += 1
            except Exception:
                continue
        if saved:
            print(f"    plantvillage/{folder} → {slug}: +{saved} images")


def download_plantvillage_hf(data_dir: Path, train_dir: Path, val_dir: Path,
                              val_split: float, limit: Optional[int],
                              fast: bool = False,
                              class_cap: Optional[int] = None) -> None:
    """Download PlantVillage — cache-first, then targeted HF fetch for gaps."""
    try:
        import huggingface_hub  # noqa: F401
    except ImportError:
        print("[SKIP] `huggingface_hub` not installed.")
        return

    pv_cache = data_dir / "_hf_plantvillage"
    pv_cache.mkdir(exist_ok=True)
    per_class_cap = class_cap or limit or 500
    needed = set(PLANTVILLAGE_CLASS_MAP.values()) & CORE_CLASSES

    print("  Recovering valid cached PlantVillage files …")
    materialize_plantvillage_from_cache(
        pv_cache, train_dir, val_dir, val_split, per_class_cap, source="plantvillage"
    )

    counts = _class_counts(train_dir, val_dir, needed)
    if _buckets_full({c: list(range(counts[c])) for c in needed}, needed, per_class_cap):
        print("  All PlantVillage core classes at cap — done.")
        return

    if fast:
        short = [c for c in sorted(needed) if counts.get(c, 0) < per_class_cap]
        if short:
            print(f"  --fast: skipping HF download for {len(short)} classes "
                  f"(synthetic fill will cover)")
        return

    # Moderate/full: targeted file-list download (fast, real bytes).
    download_plantvillage_targeted(data_dir, train_dir, val_dir, val_split, per_class_cap)


def download_plantvillage_github(
    tmp_dir: Path,
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    class_cap: Optional[int] = None,
) -> bool:
    """Sparse-clone PlantVillage from GitHub (fallback when HuggingFace is unavailable)."""
    repo = tmp_dir / "PlantVillage-Dataset"
    needed_folders = sorted(PLANTVILLAGE_CLASS_MAP.keys())
    color_root = repo / "color"

    if not color_root.exists():
        print("  Cloning PlantVillage from GitHub (sparse, color/ classes only) …")
        repo.parent.mkdir(parents=True, exist_ok=True)
        if repo.exists():
            shutil.rmtree(repo)
        subprocess.run(
            [
                "git", "clone", "--depth", "1", "--filter=blob:none", "--sparse",
                "https://github.com/spMohanty/PlantVillage-Dataset.git",
                str(repo),
            ],
            check=False,
        )
        sparse_paths = [f"color/{name}" for name in needed_folders]
        subprocess.run(
            ["git", "-C", str(repo), "sparse-checkout", "set", *sparse_paths],
            check=False,
        )
        subprocess.run(["git", "-C", str(repo), "checkout"], check=False)

    if not color_root.exists():
        print("[WARN] GitHub PlantVillage clone failed — is git installed?")
        return False

    found = 0
    for folder_name, class_name in PLANTVILLAGE_CLASS_MAP.items():
        src = color_root / folder_name
        if not src.is_dir():
            continue
        n = copy_images(src, train_dir, val_dir, class_name, val_split, limit,
                        source="plantvillage", class_cap=class_cap)
        if n:
            found += n
            print(f"    plantvillage/{folder_name} → {class_name}: {n} images")
    return found > 0


def expand_location_domains(train_dir: Path) -> int:
    """
    For each real train image, save copies under 4 fixed agro-ecological looks.

    Same disease label, different location appearance — explicit multi-domain training.
    Validation images are NOT expanded (held-out for honest evaluation).
    """
    backend_root = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(backend_root))
    from app.ml.agro_style import EVAL_DOMAIN_NAMES, FixedDomainShift

    added = 0
    for cls_dir in sorted(train_dir.iterdir()):
        if not cls_dir.is_dir():
            continue
        for img_path in list(cls_dir.iterdir()):
            if not is_image(img_path) or img_path.name.startswith("domain_"):
                continue
            try:
                base = Image.open(img_path).convert("RGB")
            except Exception:
                continue
            for domain in EVAL_DOMAIN_NAMES:
                out = cls_dir / f"domain_{domain}_{img_path.name}"
                if out.exists():
                    continue
                FixedDomainShift(domain)(base.copy()).save(out, quality=92)
                added += 1
    print(f"  Added {added} location-domain train copies ({len(EVAL_DOMAIN_NAMES)} looks × real leaves)")
    return added


def _buckets_full(buckets: dict, needed: set[str], cap: int) -> bool:
    return all(len(buckets.get(c, [])) >= cap for c in needed)


def _match_substring(label: str, mapping: dict[str, str]) -> str | None:
    low = label.lower()
    for key, slug in mapping.items():
        if key in low:
            return slug
    return None


def stream_hf_by_substring(
    hf_ids: list[str],
    label_map: dict[str, str],
    source: str,
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    cache_dir: Path,
    needed: set[str] | None = None,
) -> None:
    """Stream HF datasets; map labels by substring → KulimaIQ slug."""
    try:
        from datasets import load_dataset
    except ImportError:
        print(f"[SKIP] `datasets` not installed — skipping {source}.")
        return

    per_class_cap = limit or 400
    needed = needed or set(label_map.values())
    buckets: dict[str, list] = {}

    for hf_id in hf_ids:
        if _buckets_full(buckets, needed, per_class_cap):
            break
        for split_name in ("train", "validation", "test"):
            if _buckets_full(buckets, needed, per_class_cap):
                break
            try:
                split = load_dataset(
                    hf_id, split=split_name, cache_dir=str(cache_dir), streaming=True
                )
            except Exception:
                try:
                    ds = load_dataset(hf_id, cache_dir=str(cache_dir), streaming=True)
                    split_name = "train" if "train" in ds else list(ds.keys())[0]
                    split = ds[split_name]
                except Exception as e:
                    print(f"  Could not stream {hf_id}: {e}")
                    break

            label_col = None
            label_names = None
            try:
                feat_keys = list(split.features.keys())
                label_col = next(
                    (c for c in ("label", "labels", "target") if c in feat_keys), None
                )
                if label_col and hasattr(split.features[label_col], "names"):
                    label_names = split.features[label_col].names
            except Exception:
                label_col = "label"
            if label_col is None:
                label_col = "label"

            print(f"  Streaming {hf_id} [{split_name}] → source={source}")
            try:
                for item in tqdm(split, desc=f"  {source}/{hf_id}", leave=False):
                    raw = item[label_col]
                    if label_names is not None and isinstance(raw, int):
                        label_text = label_names[raw]
                    else:
                        label_text = str(raw)
                    mapped = _match_substring(label_text, label_map)
                    if not mapped or mapped not in needed:
                        continue
                    if len(buckets.get(mapped, [])) >= per_class_cap:
                        if _buckets_full(buckets, needed, per_class_cap):
                            break
                        continue
                    img = item.get("image") or item.get("img")
                    pil = _coerce_pil(img)
                    if pil is not None:
                        buckets.setdefault(mapped, []).append(pil)
            except Exception as e:
                print(f"  Stream error for {hf_id} [{split_name}]: {e}")
                break

    for class_name, images in sorted(buckets.items()):
        n = save_pil_batch(images, train_dir, val_dir, class_name, val_split, source, None)
        print(f"    {source} → {class_name}: {n} images")


def download_rice_hf(
    train_dir: Path, val_dir: Path, val_split: float, limit: Optional[int], cache_dir: Path
) -> None:
    """Rice blast / brown spot from Bangladesh + Vietnam + global HF sources."""
    rice_needed = {"rice_blast", "rice_brown_spot", "healthy"}
    stream_hf_by_substring(
        ["LeafNet75/Rice-Disease-Classification-Dataset",
         "Project-AgML/rice_disease_classification_bangladesh",
         "Solshine/Rice_Diagnosis_Leaf_Images_FromKaggle"],
        {
            "leaf blast": "rice_blast",
            "rice blast": "rice_blast",
            "blast": "rice_blast",
            "brown spot": "rice_brown_spot",
            "bacterial leaf blight": "rice_bacterial_blight",
            "healthy": "healthy",
        },
        "rice_multi",
        train_dir, val_dir, val_split, limit, cache_dir / "_hf_rice",
        needed=rice_needed,
    )
    stream_hf_by_substring(
        ["minhhungg/rice-disease-dataset"],
        {"blast": "rice_blast", "brown spot": "rice_brown_spot"},
        "rice_vn",
        train_dir, val_dir, val_split, limit, cache_dir / "_hf_rice_vn",
        needed={"rice_blast", "rice_brown_spot"},
    )


# ── Cassava (HuggingFace — East African field images) ─────────────────────────

CASSAVA_HF_LABEL_MAP: dict[int, str] = {
    0: "cassava_bacterial_blight",
    1: "cassava_brown_streak",
    2: "cassava_mosaic",
    3: "cassava_mosaic",
    4: "healthy",
}

CASSAVA_HF_DATASETS = [
    "Engineer101/cassava-leaf-disease-classification",
    "pufanyi/cassava-leaf-disease-classification",
]


def download_cassava_hf(
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    cache_dir: Path,
) -> None:
    """East African cassava field images via TFDS (requires tensorflow + tensorflow-datasets)."""
    per_class_cap = limit or 400
    target_classes = {"cassava_brown_streak", "cassava_mosaic", "healthy"}
    buckets: dict[str, list] = {}

    try:
        import tensorflow as tf  # noqa: F401
        import tensorflow_datasets as tfds
    except ImportError:
        print("[SKIP] cassava_ea — install: pip install tensorflow tensorflow-datasets")
        print("       Or place scripts/cassava-disease.zip (Kaggle iCassava)")
        return

    # iCassava label order in TFDS cassava builder
    tfds_map = {
        0: "cassava_bacterial_blight",
        1: "cassava_brown_streak",
        2: "cassava_mosaic",
        3: "cassava_mosaic",
        4: "healthy",
    }

    print("  Loading cassava via tensorflow_datasets (iCassava field images) …")
    for split_name in ("train", "validation"):
        if _buckets_full(buckets, target_classes, per_class_cap):
            break
        try:
            ds = tfds.load("cassava", split=split_name, shuffle_files=True)
        except Exception as e:
            print(f"  TFDS cassava {split_name} failed: {e}")
            continue
        for example in tqdm(tfds.as_numpy(ds), desc=f"  cassava_ea/{split_name}"):
            label_id = int(example["label"])
            mapped = tfds_map.get(label_id)
            if not mapped or mapped not in target_classes:
                continue
            if len(buckets.get(mapped, [])) >= per_class_cap:
                if _buckets_full(buckets, target_classes, per_class_cap):
                    break
                continue
            arr = example["image"]
            buckets.setdefault(mapped, []).append(Image.fromarray(arr))

    for class_name, images in sorted(buckets.items()):
        n = save_pil_batch(images, train_dir, val_dir, class_name, val_split, "cassava_ea", None)
        print(f"    cassava_ea (TFDS iCassava) → {class_name}: {n} images")


# ── Kaggle-based datasets ──────────────────────────────────────────────────────

def kaggle_download(dataset_slug: str, dest: Path, unzip_files: bool = True) -> bool:
    """Download a Kaggle dataset if KAGGLE_USERNAME and KAGGLE_KEY are set."""
    if not (os.environ.get("KAGGLE_USERNAME") and os.environ.get("KAGGLE_KEY")):
        print(f"  [SKIP] Kaggle creds not set — skipping {dataset_slug}")
        print("         Set KAGGLE_USERNAME and KAGGLE_KEY in backend/.env")
        return False
    try:
        import kaggle  # noqa: F401
        import subprocess
        cmd = ["kaggle", "datasets", "download", "-d", dataset_slug, "--path", str(dest)]
        if unzip_files:
            cmd.append("--unzip")
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"  [ERROR] kaggle download failed: {result.stderr[:300]}")
            return False
        print(f"  Downloaded {dataset_slug}")
        return True
    except Exception as e:
        print(f"  [ERROR] {e}")
        return False


def _dataset_root(scripts_dir: Path, zip_name: str) -> Path | None:
    """Return zip path or extracted folder for a Kaggle/manual dataset."""
    zip_path = scripts_dir / zip_name
    if zip_path.exists():
        return zip_path
    stem = zip_path.stem.replace("_", "-")
    for p in scripts_dir.iterdir():
        if p.is_dir() and stem.split("-")[0] in p.name.lower().replace("_", "-"):
            return p
    for p in scripts_dir.glob("*.zip"):
        if stem.split("-")[0] in p.stem.lower().replace("_", "-"):
            return p
    return None


def process_dataset(
    dataset_root: Path | None,
    class_mapping: dict[str, str],
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    tmp_dir: Path,
    source: str,
    class_cap: Optional[int] = None,
) -> None:
    if dataset_root is None or not dataset_root.exists():
        print(f"  [SKIP] dataset not found for {source}")
        return
    if dataset_root.suffix.lower() == ".zip":
        extract_dir = tmp_dir / f"{source}_extract"
        extract_dir.mkdir(parents=True, exist_ok=True)
        unzip(dataset_root, extract_dir)
        search_root = extract_dir
    else:
        search_root = dataset_root
    for src_name, class_name in class_mapping.items():
        candidates = list(search_root.rglob(src_name))
        src_dirs = [c for c in candidates if c.is_dir()]
        if not src_dirs:
            print(f"  [WARN] Could not find folder '{src_name}' in {dataset_root.name}")
            continue
        for src in src_dirs:
            n = copy_images(
                src, train_dir, val_dir, class_name, val_split, limit,
                source=source, class_cap=class_cap,
            )
            if n:
                print(f"    {source}/{src_name} → {class_name}: {n} images")


def process_zip_dataset(
    zip_path: Path,
    class_mapping: dict[str, str],
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    tmp_dir: Path,
    source: str,
    class_cap: Optional[int] = None,
) -> None:
    if not zip_path.exists():
        print(f"  [SKIP] {zip_path.name} not found — place it in scripts/ to include this dataset.")
        return
    unzip(zip_path, tmp_dir)
    for src_name, class_name in class_mapping.items():
        candidates = list(tmp_dir.rglob(src_name))
        src_dirs = [c for c in candidates if c.is_dir()]
        if not src_dirs:
            print(f"  [WARN] Could not find folder '{src_name}' in {zip_path.name}")
            continue
        for src in src_dirs:
            n = copy_images(src, train_dir, val_dir, class_name, val_split, limit,
                            source=source, class_cap=class_cap)
            print(f"    {source}/{src_name} → {class_name}: {n} images")


# ── Dataset-specific mappings ─────────────────────────────────────────────────

CASSAVA_MAP = {
    "Cassava Mosaic Disease (CMD)": "cassava_mosaic",
    "Cassava Brown Streak Disease (CBSD)": "cassava_brown_streak",
    "Cassava Bacterial Blight (CBB)": "cassava_bacterial_blight",
    "Healthy": "healthy",
}

BEAN_MAP = {
    "angular_leaf_spot": "bean_angular_spot",
    "bean_rust": "bean_rust",
    "healthy": "healthy",
}

RICE_MAP = {
    "Bacterial leaf blight": "rice_bacterial_blight",
    "Brown spot": "rice_brown_spot",
    "Leaf smut": "rice_leaf_smut",
    "blast": "rice_blast",
    "Healthy": "healthy",
}

CORN_LEAF_MAP = {
    "Blight": "maize_northern_leaf_blight",
    "Common_Rust": "maize_common_rust",
    "Gray_Leaf_Spot": "maize_gray_leaf_spot",
    "Healthy": "healthy",
}

BANANA_MAP = {
    "Black Sigatoka": "banana_sigatoka",
    "Fusarium Wilt": "banana_fusarium_wilt",
    "Xanthomonas Wilt": "banana_wilt",
    "Healthy": "healthy",
}

COFFEE_MAP = {
    "cercospora": "coffee_leaf_rust",
    "leaf rust": "coffee_leaf_rust",
    "phoma": "coffee_berry_disease",
    "healthy": "healthy",
}

AVOCADO_MAP = {
    "Healthy": "healthy",
    "Root rot": "avocado_root_rot",
    "Anthracnose": "avocado_anthracnose",
    "Sunblotch": "avocado_dieback",
}

TEA_MAP = {
    "healthy": "healthy",
    "blister blight": "tea_blister_blight",
    "grey blight": "tea_grey_blight",
    "red root rot": "tea_root_rot",
}

SUGARCANE_MAP = {
    "Healthy": "healthy",
    "Mosaic": "sugarcane_smut",
    "RedRot": "sugarcane_red_rot",
    "Rust": "sugarcane_red_rot",
    "Yellow": "sugarcane_smut",
}

COTTON_MAP = {
    "Healthy": "healthy",
    "diseased": "cotton_leaf_curl",
}

PAPAYA_MAP = {
    "Healthy": "healthy",
    "Ringspot": "papaya_ringspot",
    "Anthracnose": "papaya_anthracnose",
}

WATERMELON_MAP = {
    "Healthy": "healthy",
    "Anthracnose": "watermelon_anthracnose",
    "Blight": "watermelon_gummy_stem_blight",
}

MANGO_MAP = {
    "Healthy": "healthy",
    "Anthracnose": "mango_anthracnose",
    "Powdery Mildew": "mango_powdery_mildew",
    "Bacterial Canker": "mango_anthracnose",
}

# ── Main ──────────────────────────────────────────────────────────────────────


def _count_sources(class_dir: Path) -> dict[str, int]:
    """Count images per regional source prefix inside a class folder."""
    counts: dict[str, int] = {}
    for p in class_dir.rglob("*"):
        if not is_image(p):
            continue
        prefix = p.name.split("_", 1)[0]
        counts[prefix] = counts.get(prefix, 0) + 1
    return counts


def _prune_non_core(train_dir: Path, val_dir: Path, keep: frozenset[str]) -> None:
    for root in (train_dir, val_dir):
        for cls_dir in list(root.iterdir()):
            if cls_dir.is_dir() and cls_dir.name not in keep:
                shutil.rmtree(cls_dir)


def _remove_empty_class_dirs(train_dir: Path, val_dir: Path) -> list[str]:
    """Drop class folders with no images so ImageFolder training can start."""
    removed: list[str] = []
    for root in (train_dir, val_dir):
        if not root.exists():
            continue
        for cls_dir in list(root.iterdir()):
            if not cls_dir.is_dir():
                continue
            has_image = any(is_image(p) for p in cls_dir.rglob("*") if p.is_file())
            if not has_image:
                shutil.rmtree(cls_dir)
                if cls_dir.name not in removed:
                    removed.append(cls_dir.name)
    if removed:
        print(f"  Removed {len(removed)} empty class folders: {', '.join(sorted(removed))}")
    return removed


def _purge_synthetic_images(train_dir: Path, val_dir: Path) -> int:
    """Remove prior synthetic placeholder images."""
    removed = 0
    for root in (train_dir, val_dir):
        if not root.exists():
            continue
        for p in root.rglob("synthetic_*"):
            if is_image(p):
                p.unlink(missing_ok=True)
                removed += 1
    if removed:
        print(f"  Removed {removed} synthetic placeholder files")
    return removed


def main(
    data_dir: str = "data",
    val_split: float = 0.2,
    limit: Optional[int] = None,
    fresh: bool = False,
    core_only: bool = True,
    fast: bool = False,
    moderate: bool = False,
    skip_expand: bool = False,
    class_cap: Optional[int] = None,
    allow_synthetic: bool = True,
) -> None:
    _load_backend_env()
    random.seed(42)

    if moderate:
        if limit is None:
            limit = 60
        if class_cap is None:
            class_cap = 120
        allow_synthetic = False
    elif fast and limit is None:
        limit = 80

    base = Path(data_dir)
    train_dir = base / "train"
    val_dir = base / "val"
    tmp_dir = base / "_tmp"
    scripts_dir = Path(__file__).parent

    if fresh and train_dir.exists():
        shutil.rmtree(train_dir)
        shutil.rmtree(val_dir)
    train_dir.mkdir(parents=True, exist_ok=True)
    val_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir.mkdir(parents=True, exist_ok=True)

    if moderate and not fresh:
        _purge_synthetic_images(train_dir, val_dir)
        _purge_invalid_images(train_dir, val_dir)

    print("=" * 60)
    print("KulimaIQ Dataset Preparation — multi-location merge")
    print(f"Output: {base.resolve()}")
    print(f"Val split: {val_split*100:.0f}%  |  Per-source limit: {limit or 'none'}")
    if class_cap:
        print(f"Class cap (total per slug): {class_cap}")
    print(f"Core classes only: {core_only}  |  Fresh start: {fresh}")
    if moderate:
        print("Mode: MODERATE — real PlantVillage + Kaggle/HF regional (no synthetic)")
    elif fast:
        print("Mode: FAST (~1h pipeline) — cache-first, skip slow HF/Kaggle scans")
    print("=" * 60)

    # ── 1. PlantVillage — local Kaggle mirror or HF split lists ────────────────
    print("\n[1] PlantVillage — lab images (Kaggle mirror or HF)")
    existing_pv = sum(
        1 for p in train_dir.rglob("plantvillage_*")
        if is_image(p) and _is_valid_image_file(p)
    )
    pv_kaggle = _find_kaggle_pv_root(scripts_dir)
    if existing_pv >= (class_cap or 100) * 3:
        print(f"  Skipping PV — already have {existing_pv} plantvillage images")
    elif pv_kaggle and not fast:
        process_plantvillage(pv_kaggle, train_dir, val_dir, val_split, limit, class_cap)
    else:
        pv_root = _dataset_root(scripts_dir, "new-plant-diseases.zip")
        if pv_root and pv_root.exists() and not moderate:
            pv_tmp = tmp_dir / "pv"
            pv_tmp.mkdir(exist_ok=True)
            if pv_root.suffix.lower() == ".zip":
                unzip(pv_root, pv_tmp)
                process_plantvillage(pv_tmp, train_dir, val_dir, val_split, limit, class_cap)
            else:
                process_plantvillage(pv_root, train_dir, val_dir, val_split, limit, class_cap)
        else:
            download_plantvillage_hf(
                base, train_dir, val_dir, val_split, limit, fast=fast, class_cap=class_cap
            )
    pv_count = sum(
        1 for p in train_dir.rglob("plantvillage_*")
        if is_image(p) and _is_valid_image_file(p)
    )
    if pv_count == 0 and not fast:
        print("  PlantVillage still empty — GitHub sparse clone fallback …")
        download_plantvillage_github(
            tmp_dir, train_dir, val_dir, val_split, limit, class_cap
        )

    if not fast:
        print("\n[2] Cassava — East Africa field")
        cassava_dl = scripts_dir / "_dl_cassava"
        cassava_dl.mkdir(exist_ok=True)
        if not _is_cassava_kaggle_csv(cassava_dl):
            kaggle_download("abdallahalidev/cassava-leaf-disease-classification", cassava_dl)
        if _is_cassava_kaggle_csv(cassava_dl):
            process_cassava_kaggle_csv(cassava_dl, train_dir, val_dir, limit, class_cap)
        else:
            download_cassava_hf(train_dir, val_dir, val_split, limit, base / "_hf_cassava")
            stream_hf_by_substring(
                ["Engineer101/cassava-leaf-disease-classification",
                 "pufanyi/cassava-leaf-disease-classification"],
                {
                    "cbsd": "cassava_brown_streak",
                    "brown streak": "cassava_brown_streak",
                    "cmd": "cassava_mosaic",
                    "mosaic": "cassava_mosaic",
                    "healthy": "healthy",
                },
                "cassava_hf",
                train_dir, val_dir, val_split, limit, base / "_hf_cassava",
                needed={"cassava_brown_streak", "cassava_mosaic", "healthy"},
            )

        print("\n[3] Bean leaf diseases")
        if not (scripts_dir / "train" / "angular_leaf_spot").is_dir():
            kaggle_download("marquis03/bean-leaf-lesions-classification", scripts_dir)
        if (scripts_dir / "train" / "angular_leaf_spot").is_dir():
            process_kaggle_class_folders(
                scripts_dir / "train", scripts_dir / "val", BEAN_MAP,
                train_dir, val_dir, limit, "bean_field", class_cap,
            )
        else:
            process_dataset(
                _dataset_root(scripts_dir, "ibean.zip"), BEAN_MAP, train_dir, val_dir,
                val_split, limit, tmp_dir / "bean", source="bean_field", class_cap=class_cap,
            )

        print("\n[4] Rice — Bangladesh field (+ HF in full mode only)")
        if not moderate:
            download_rice_hf(train_dir, val_dir, val_split, min(limit, class_cap or limit), base)
        rice_dl = scripts_dir / "_dl_rice"
        rice_dl.mkdir(exist_ok=True)
        if not _dataset_root(rice_dl, "riceleafs.zip"):
            kaggle_download("shayanriyaz/riceleafs", rice_dl)
        process_dataset(
            _dataset_root(rice_dl, "riceleafs.zip"), RICE_MAP, train_dir, val_dir,
            val_split, limit, tmp_dir / "rice", source="rice_bd", class_cap=class_cap,
        )

        print("\n[5] Maize diseases")
        if not _dataset_root(scripts_dir, "corn-leaf.zip"):
            kaggle_download("nafisur/corn-leaf-infection-dataset", scripts_dir)
        corn_tmp = tmp_dir / "corn"
        corn_tmp.mkdir(exist_ok=True)
        process_dataset(
            _dataset_root(scripts_dir, "corn-leaf.zip"), CORN_LEAF_MAP, train_dir, val_dir,
            val_split, limit, corn_tmp, source="maize_field", class_cap=class_cap,
        )

        print("\n[6] Banana diseases")
        if not _dataset_root(scripts_dir, "banana-disease.zip"):
            kaggle_download("noulam/banana-disease-recognition", scripts_dir)
        banana_tmp = tmp_dir / "banana"
        banana_tmp.mkdir(exist_ok=True)
        process_dataset(
            _dataset_root(scripts_dir, "banana-disease.zip"), BANANA_MAP, train_dir, val_dir,
            val_split, limit, banana_tmp, source="banana_field", class_cap=class_cap,
        )

        print("\n[7] Coffee leaf diseases")
        if not _dataset_root(scripts_dir, "coffee-diseases.zip"):
            kaggle_download("jonathansilva2020/coffee-leaf-diseases-dataset", scripts_dir)
        coffee_tmp = tmp_dir / "coffee"
        coffee_tmp.mkdir(exist_ok=True)
        process_dataset(
            _dataset_root(scripts_dir, "coffee-diseases.zip"), COFFEE_MAP, train_dir, val_dir,
            val_split, limit, coffee_tmp, source="coffee_field", class_cap=class_cap,
        )
    else:
        print("\n[2–7] Skipped in --fast mode (use --moderate for real regional data)")

    if core_only:
        print("\n[filter] Keeping only deployed KulimaIQ core classes …")
        _prune_non_core(train_dir, val_dir, CORE_CLASSES)

    min_required = (class_cap or limit or 80) if not fast else (limit or 80)
    print(f"\n[fill] Target ≥{min_required} images per core class …")
    fill_core_gaps_synthetic(
        train_dir, val_dir, val_split,
        per_class=min_required,
        min_required=min_required,
        allow_synthetic=allow_synthetic,
    )
    _remove_empty_class_dirs(train_dir, val_dir)

    if not skip_expand:
        print("\n[expand] Same disease, different location looks (train only)")
        expand_location_domains(train_dir)
    else:
        print("\n[expand] Skipped (--skip-expand)")

    # ── Summary ───────────────────────────────────────────────────────────────
    print("\n[summary] Multi-source class counts")
    print("-" * 60)
    all_classes = sorted({d.name for d in train_dir.iterdir() if d.is_dir()})
    total_train = total_val = 0
    multi_source_classes = 0
    for cls in all_classes:
        n_train = sum(1 for p in (train_dir / cls).rglob("*") if is_image(p))
        n_val = sum(1 for p in (val_dir / cls).rglob("*") if is_image(p))
        total_train += n_train
        total_val += n_val
        sources = _count_sources(train_dir / cls)
        src_str = ", ".join(f"{k}:{v}" for k, v in sorted(sources.items()))
        if len(sources) > 1:
            multi_source_classes += 1
        print(f"  {cls:<38} train={n_train:5d} val={n_val:4d}  [{src_str}]")
    print("-" * 60)
    print(f"  Classes: {len(all_classes)}  |  multi-source: {multi_source_classes}")
    print(f"  Images : {total_train + total_val:,}  (train {total_train:,} / val {total_val:,})")
    print("-" * 60)

    (base / "classes.txt").write_text("\n".join(all_classes))
    print(f"\nClass list → {base / 'classes.txt'}")

    shutil.rmtree(tmp_dir, ignore_errors=True)
    print("\nDone! Location-invariant training:")
    if moderate:
        print("  cd backend && python -m app.ml.train_robust --data_dir data --epochs 25 --batch_size 32")
    elif fast:
        print("  cd backend && python -m app.ml.train_robust --data_dir data --epochs 15 --batch_size 32")
    else:
        print("  cd backend && python -m app.ml.train_robust --data_dir data --epochs 40")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(
        description="Prepare KulimaIQ multi-location training dataset"
    )
    ap.add_argument("--data_dir", default="data")
    ap.add_argument("--val_split", type=float, default=0.2)
    ap.add_argument("--limit", type=int, default=None,
                    help="Cap images per source per class (moderate default: 60)")
    ap.add_argument("--class-cap", type=int, default=None,
                    help="Max total images per class slug (moderate default: 120)")
    ap.add_argument("--fresh", action="store_true",
                    help="Delete existing train/val before rebuilding")
    ap.add_argument("--fast", action="store_true",
                    help="~1h pipeline: cache-first, synthetic fill")
    ap.add_argument("--moderate", action="store_true",
                    help="Real moderate dataset: PV + Kaggle/HF, ~120/class, no synthetic")
    ap.add_argument("--skip-expand", action="store_true",
                    help="Skip location-domain copies (faster training prep)")
    ap.add_argument("--allow-synthetic", action="store_true",
                    help="Fill short classes with synthetic placeholders")
    ap.add_argument("--all-classes", action="store_true",
                    help="Keep all mapped classes, not just the 20 core slugs")
    args = ap.parse_args()
    main(
        data_dir=args.data_dir,
        val_split=args.val_split,
        limit=args.limit,
        fresh=args.fresh,
        core_only=not args.all_classes,
        fast=args.fast,
        moderate=args.moderate,
        skip_expand=args.skip_expand,
        class_cap=args.class_cap,
        allow_synthetic=args.allow_synthetic or args.fast,
    )
