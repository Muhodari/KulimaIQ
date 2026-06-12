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
"""

import argparse
import os
import random
import shutil
import zipfile
from pathlib import Path
from typing import Optional

try:
    from PIL import Image
    from tqdm import tqdm
except ImportError:
    raise SystemExit("Missing deps — run: pip install -r scripts/requirements_data.txt")

# ── Helpers ───────────────────────────────────────────────────────────────────

SUPPORTED_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def is_image(path: Path) -> bool:
    return path.suffix.lower() in SUPPORTED_EXTS


def copy_images(
    src_dir: Path,
    dest_train: Path,
    dest_val: Path,
    class_name: str,
    val_split: float = 0.2,
    limit: Optional[int] = None,
) -> int:
    """Copy all images from src_dir into dest_{train,val}/class_name."""
    files = [p for p in src_dir.rglob("*") if is_image(p)]
    if not files:
        print(f"  [WARN] No images found in {src_dir}")
        return 0

    random.shuffle(files)
    if limit:
        files = files[:limit]

    n_val = max(1, int(len(files) * val_split))
    splits = {"val": files[:n_val], "train": files[n_val:]}

    total = 0
    for split, images in splits.items():
        dest = (dest_train if split == "train" else dest_val) / class_name
        dest.mkdir(parents=True, exist_ok=True)
        for img_path in tqdm(images, desc=f"  {class_name}/{split}", leave=False):
            shutil.copy2(img_path, dest / img_path.name)
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


def process_plantvillage(pv_root: Path, train_dir: Path, val_dir: Path,
                         val_split: float, limit: Optional[int]) -> None:
    """Process an extracted PlantVillage dataset tree."""
    segment_dirs = [d for d in pv_root.rglob("*") if d.is_dir() and d.name in PLANTVILLAGE_CLASS_MAP]
    if not segment_dirs:
        # Try one level under root
        for d in pv_root.iterdir():
            if d.is_dir():
                segment_dirs = [s for s in d.iterdir() if s.is_dir() and s.name in PLANTVILLAGE_CLASS_MAP]
                if segment_dirs:
                    break
    if not segment_dirs:
        print("[WARN] Could not locate PlantVillage class folders. Skipping.")
        return

    print(f"  Found {len(segment_dirs)} PlantVillage class folders")
    for src in sorted(segment_dirs):
        target_class = PLANTVILLAGE_CLASS_MAP[src.name]
        n = copy_images(src, train_dir, val_dir, target_class, val_split, limit)
        print(f"    {src.name} → {target_class}: {n} images")


def download_plantvillage_hf(data_dir: Path, train_dir: Path, val_dir: Path,
                              val_split: float, limit: Optional[int]) -> None:
    """Download PlantVillage from HuggingFace datasets hub."""
    try:
        from datasets import load_dataset
    except ImportError:
        print("[SKIP] `datasets` not installed — skipping HuggingFace PlantVillage.")
        print("       Run:  pip install datasets  then re-run this script.")
        return

    print("Downloading PlantVillage from HuggingFace (this may take several minutes)…")
    pv_cache = data_dir / "_hf_plantvillage"
    pv_cache.mkdir(exist_ok=True)

    try:
        ds = load_dataset(
            "dataset-research/PlantVillage-Dataset",
            split="train",
            cache_dir=str(pv_cache),
        )
    except Exception as e:
        print(f"[ERROR] HuggingFace download failed: {e}")
        return

    print(f"  PlantVillage: {len(ds)} total images, {len(set(ds['label']))} classes")

    label_names: list[str] = ds.features["label"].names
    buckets: dict[str, list] = {}
    for item in tqdm(ds, desc="  Sorting PV classes"):
        label_name = label_names[item["label"]]
        mapped = PLANTVILLAGE_CLASS_MAP.get(label_name)
        if mapped:
            buckets.setdefault(mapped, []).append(item["image"])

    for class_name, images in sorted(buckets.items()):
        if limit:
            images = images[:limit]
        random.shuffle(images)
        n_val = max(1, int(len(images) * val_split))
        splits = {"val": images[:n_val], "train": images[n_val:]}
        for split, imgs in splits.items():
            dest = (train_dir if split == "train" else val_dir) / class_name
            dest.mkdir(parents=True, exist_ok=True)
            for i, img in enumerate(tqdm(imgs, desc=f"    {class_name}/{split}", leave=False)):
                if not isinstance(img, Image.Image):
                    img = Image.fromarray(img)
                img.convert("RGB").save(dest / f"{class_name}_{split}_{i:05d}.jpg")
        total = sum(len(v) for v in splits.values())
        print(f"    {class_name}: {total} images")


# ── Kaggle-based datasets ──────────────────────────────────────────────────────

def kaggle_download(dataset_slug: str, dest: Path) -> None:
    """Download a Kaggle dataset if KAGGLE_USERNAME and KAGGLE_KEY are set."""
    if not (os.environ.get("KAGGLE_USERNAME") and os.environ.get("KAGGLE_KEY")):
        print(f"  [SKIP] Kaggle creds not set — skipping {dataset_slug}")
        print("         Export KAGGLE_USERNAME and KAGGLE_KEY to enable auto-download.")
        return
    try:
        import kaggle  # noqa: F401
        import subprocess
        result = subprocess.run(
            ["kaggle", "datasets", "download", "-d", dataset_slug,
             "--path", str(dest), "--unzip"],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"  [ERROR] kaggle download failed: {result.stderr[:200]}")
        else:
            print(f"  Downloaded {dataset_slug}")
    except Exception as e:
        print(f"  [ERROR] {e}")


def process_zip_dataset(
    zip_path: Path,
    class_mapping: dict[str, str],   # {folder_name_in_zip: our_class_name}
    train_dir: Path,
    val_dir: Path,
    val_split: float,
    limit: Optional[int],
    tmp_dir: Path,
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
            n = copy_images(src, train_dir, val_dir, class_name, val_split, limit)
            print(f"    {src_name} → {class_name}: {n} images")


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


def main(data_dir: str = "data", val_split: float = 0.2,
         limit: Optional[int] = None) -> None:
    random.seed(42)

    base = Path(data_dir)
    train_dir = base / "train"
    val_dir = base / "val"
    tmp_dir = base / "_tmp"
    scripts_dir = Path(__file__).parent

    train_dir.mkdir(parents=True, exist_ok=True)
    val_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("KulimaIQ Dataset Preparation")
    print(f"Output: {base.resolve()}")
    print(f"Val split: {val_split*100:.0f}%  |  Per-class limit: {limit or 'none'}")
    print("=" * 60)

    # ── 1. PlantVillage (HuggingFace) — automatic ──────────────────────────────
    print("\n[1/7] PlantVillage (HuggingFace) — 38 classes, 14 crops")

    pv_zip = scripts_dir / "new-plant-diseases.zip"
    if pv_zip.exists():
        pv_tmp = tmp_dir / "pv"
        pv_tmp.mkdir(exist_ok=True)
        unzip(pv_zip, pv_tmp)
        process_plantvillage(pv_tmp, train_dir, val_dir, val_split, limit)
    else:
        download_plantvillage_hf(base, train_dir, val_dir, val_split, limit)

    # ── 2. Cassava diseases ────────────────────────────────────────────────────
    print("\n[2/7] Cassava diseases")
    cassava_zip = scripts_dir / "cassava-disease.zip"
    if not cassava_zip.exists():
        kaggle_download("c/cassava-disease", scripts_dir)
    cassava_tmp = tmp_dir / "cassava"
    cassava_tmp.mkdir(exist_ok=True)
    process_zip_dataset(cassava_zip, CASSAVA_MAP, train_dir, val_dir,
                        val_split, limit, cassava_tmp)

    # ── 3. Bean diseases (iBean) ───────────────────────────────────────────────
    print("\n[3/7] Bean leaf diseases (iBean)")
    bean_zip = scripts_dir / "ibean.zip"
    if not bean_zip.exists():
        kaggle_download("marquis03/bean-leaf-lesions-classification", scripts_dir)
    bean_tmp = tmp_dir / "bean"
    bean_tmp.mkdir(exist_ok=True)
    process_zip_dataset(bean_zip, BEAN_MAP, train_dir, val_dir,
                        val_split, limit, bean_tmp)

    # ── 4. Rice diseases ───────────────────────────────────────────────────────
    print("\n[4/7] Rice leaf diseases")
    rice_zip = scripts_dir / "riceleafs.zip"
    if not rice_zip.exists():
        kaggle_download("shayanriyaz/riceleafs", scripts_dir)
    rice_tmp = tmp_dir / "rice"
    rice_tmp.mkdir(exist_ok=True)
    process_zip_dataset(rice_zip, RICE_MAP, train_dir, val_dir,
                        val_split, limit, rice_tmp)

    # ── 5. Banana diseases ─────────────────────────────────────────────────────
    print("\n[5/7] Banana diseases")
    banana_zip = scripts_dir / "banana-disease.zip"
    if not banana_zip.exists():
        kaggle_download("noulam/banana-disease-recognition", scripts_dir)
    banana_tmp = tmp_dir / "banana"
    banana_tmp.mkdir(exist_ok=True)
    process_zip_dataset(banana_zip, BANANA_MAP, train_dir, val_dir,
                        val_split, limit, banana_tmp)

    # ── 6. Coffee diseases ─────────────────────────────────────────────────────
    print("\n[6/11] Coffee leaf diseases")
    coffee_zip = scripts_dir / "coffee-diseases.zip"
    if not coffee_zip.exists():
        kaggle_download("jonathansilva2020/coffee-leaf-diseases-dataset", scripts_dir)
    coffee_tmp = tmp_dir / "coffee"
    coffee_tmp.mkdir(exist_ok=True)
    process_zip_dataset(coffee_zip, COFFEE_MAP, train_dir, val_dir,
                        val_split, limit, coffee_tmp)

    # ── 7. Avocado diseases ────────────────────────────────────────────────────
    print("\n[7/11] Avocado diseases")
    avocado_zip = scripts_dir / "avocado-disease.zip"
    if not avocado_zip.exists():
        kaggle_download("umeshnarayankar/avocado-leaf-disease-detection", scripts_dir)
    avocado_tmp = tmp_dir / "avocado"
    avocado_tmp.mkdir(exist_ok=True)
    process_zip_dataset(avocado_zip, AVOCADO_MAP, train_dir, val_dir,
                        val_split, limit, avocado_tmp)

    # ── 8. Sugarcane diseases ──────────────────────────────────────────────────
    print("\n[8/11] Sugarcane diseases")
    sugarcane_zip = scripts_dir / "sugarcane-disease.zip"
    if not sugarcane_zip.exists():
        kaggle_download("nirmalsankalana/sugarcane-leaf-disease-dataset", scripts_dir)
    sugarcane_tmp = tmp_dir / "sugarcane"
    sugarcane_tmp.mkdir(exist_ok=True)
    process_zip_dataset(sugarcane_zip, SUGARCANE_MAP, train_dir, val_dir,
                        val_split, limit, sugarcane_tmp)

    # ── 9. Cotton diseases ─────────────────────────────────────────────────────
    print("\n[9/11] Cotton leaf diseases")
    cotton_zip = scripts_dir / "cotton-disease.zip"
    if not cotton_zip.exists():
        kaggle_download("janmejaybhoi/cotton-disease-dataset", scripts_dir)
    cotton_tmp = tmp_dir / "cotton"
    cotton_tmp.mkdir(exist_ok=True)
    process_zip_dataset(cotton_zip, COTTON_MAP, train_dir, val_dir,
                        val_split, limit, cotton_tmp)

    # ── 10. Mango diseases ─────────────────────────────────────────────────────
    print("\n[10/11] Mango leaf diseases")
    mango_zip = scripts_dir / "mango-disease.zip"
    if not mango_zip.exists():
        kaggle_download("warcoder/mango-leaf-disease-dataset", scripts_dir)
    mango_tmp = tmp_dir / "mango"
    mango_tmp.mkdir(exist_ok=True)
    process_zip_dataset(mango_zip, MANGO_MAP, train_dir, val_dir,
                        val_split, limit, mango_tmp)

    # ── 11. Summary ────────────────────────────────────────────────────────────
    print("\n[11/11] Dataset summary")
    print("-" * 40)
    all_classes = sorted({d.name for d in train_dir.iterdir() if d.is_dir()})
    total_train = total_val = 0
    for cls in all_classes:
        n_train = sum(1 for p in (train_dir / cls).rglob("*") if is_image(p))
        n_val = sum(1 for p in (val_dir / cls).rglob("*") if is_image(p))
        total_train += n_train
        total_val += n_val
        print(f"  {cls:<40} train={n_train:5d}  val={n_val:4d}")
    print("-" * 40)
    print(f"  TOTAL classes: {len(all_classes)}")
    print(f"  TOTAL images : {total_train + total_val:,}  "
          f"(train {total_train:,} / val {total_val:,})")
    print("-" * 40)

    # Save class list for quick reference
    (base / "classes.txt").write_text("\n".join(all_classes))
    print(f"\nClass list saved to {base / 'classes.txt'}")

    # Clean up temp dir
    shutil.rmtree(tmp_dir, ignore_errors=True)
    print("\nDone! Train with:")
    print("  cd backend && python -m app.ml.train --data_dir data --epochs 30")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Prepare KulimaIQ training dataset")
    ap.add_argument("--data_dir", default="data",
                    help="Output directory for train/val splits (default: data)")
    ap.add_argument("--val_split", type=float, default=0.2,
                    help="Fraction of images held back for validation (default: 0.2)")
    ap.add_argument("--limit", type=int, default=None,
                    help="Cap images per class (useful for quick tests, e.g. --limit 200)")
    args = ap.parse_args()
    main(data_dir=args.data_dir, val_split=args.val_split, limit=args.limit)
