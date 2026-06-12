"""
Dataset utilities for KulimaIQ disease detection training.

Expected directory layout
─────────────────────────
  data/
    train/
      healthy/          ← images of healthy leaves
      cassava_mosaic/   ← CMD-infected cassava
      maize_necrosis/   ← MLN-infected maize
      banana_wilt/      ← BXW-infected banana
    val/
      healthy/
      cassava_mosaic/
      maize_necrosis/
      banana_wilt/

Recommended public datasets
────────────────────────────
  • PlantVillage  (https://github.com/spMohanty/PlantVillage-Dataset)
  • Cassava Leaf Disease (Kaggle)
  • iCassava 2019 Fine-Grained Visual Categorization Challenge
"""

from pathlib import Path

from torchvision import datasets, transforms

from .model import INPUT_SIZE

# ── Transforms ────────────────────────────────────────────────────────────────

_IMAGENET_MEAN = [0.485, 0.456, 0.406]
_IMAGENET_STD = [0.229, 0.224, 0.225]

train_transform = transforms.Compose([
    transforms.RandomResizedCrop(INPUT_SIZE, scale=(0.6, 1.0)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomVerticalFlip(),
    transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.1),
    transforms.RandomRotation(30),
    transforms.ToTensor(),
    transforms.Normalize(_IMAGENET_MEAN, _IMAGENET_STD),
])

val_transform = transforms.Compose([
    transforms.Resize(int(INPUT_SIZE * 1.15)),
    transforms.CenterCrop(INPUT_SIZE),
    transforms.ToTensor(),
    transforms.Normalize(_IMAGENET_MEAN, _IMAGENET_STD),
])

inference_transform = val_transform


def load_datasets(data_root: str):
    """
    Returns (train_dataset, val_dataset) as ImageFolder datasets.
    `data_root` should contain `train/` and `val/` subdirectories.
    """
    root = Path(data_root)
    train_ds = datasets.ImageFolder(str(root / "train"), transform=train_transform)
    val_ds = datasets.ImageFolder(str(root / "val"), transform=val_transform)
    return train_ds, val_ds
