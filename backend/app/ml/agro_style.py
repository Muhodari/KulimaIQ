"""
Agro-ecological style augmentation.

Simulates how the *appearance* of a leaf photo changes across East African
agro-ecological zones, without changing the disease itself:

  • Highland (cool, bright, high UV)  → cooler white balance, higher brightness,
    higher contrast, more saturation.
  • Lowland (hot, hazy)               → warmer white balance, lower contrast,
    slight haze/blur, mild desaturation.
  • Humid zones                       → reduced contrast, soft haze, dew glare.
  • Dry/dusty zones                   → warm cast, added sensor noise, lower
    saturation.

These transforms are used two ways:
  1. As TRAINING augmentation, so the model sees many "locations" of the same
     leaf and learns location-invariant disease features.
  2. To build held-out LOCATION-SHIFT evaluation domains, to measure how well
     the model generalises to appearances it was not trained on.

The zone appearance signatures are derived from the same agro-ecological
knowledge base used elsewhere in KulimaIQ, keeping the story coherent.
"""

from __future__ import annotations

import random

import torch
from PIL import Image, ImageEnhance, ImageFilter
from torchvision import transforms

from .model import INPUT_SIZE

_IMAGENET_MEAN = [0.485, 0.456, 0.406]
_IMAGENET_STD = [0.229, 0.224, 0.225]


def _white_balance(img: Image.Image, warmth: float) -> Image.Image:
    """Shift colour temperature. warmth>0 = warmer (lowland), <0 = cooler."""
    r, g, b = img.split()
    r = r.point(lambda v: min(255, max(0, v * (1 + 0.18 * warmth))))
    b = b.point(lambda v: min(255, max(0, v * (1 - 0.18 * warmth))))
    return Image.merge("RGB", (r, g, b))


class AgroStyleShift:
    """Callable PIL→PIL transform emulating one random agro-ecological look."""

    def __init__(self, strength: float = 1.0, seed: int | None = None) -> None:
        self.strength = strength
        self._rng = random.Random(seed)

    def __call__(self, img: Image.Image) -> Image.Image:
        s = self.strength
        rng = self._rng

        warmth = rng.uniform(-1.0, 1.0) * s
        img = _white_balance(img, warmth)

        brightness = 1.0 + rng.uniform(-0.28, 0.28) * s
        contrast = 1.0 + rng.uniform(-0.32, 0.22) * s
        saturation = 1.0 + rng.uniform(-0.30, 0.30) * s

        img = ImageEnhance.Brightness(img).enhance(brightness)
        img = ImageEnhance.Contrast(img).enhance(contrast)
        img = ImageEnhance.Color(img).enhance(saturation)

        # Humidity haze / soft focus.
        if rng.random() < 0.5 * s:
            img = img.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 1.2) * s))

        return img


class AddSensorNoise:
    """Add mild Gaussian sensor noise (dusty/low-light phone cameras)."""

    def __init__(self, sigma: float = 0.03) -> None:
        self.sigma = sigma

    def __call__(self, t: torch.Tensor) -> torch.Tensor:
        if self.sigma <= 0:
            return t
        return torch.clamp(t + torch.randn_like(t) * self.sigma, -3.0, 3.0)


def build_train_transform(agro_strength: float = 1.0) -> transforms.Compose:
    """Training transform: geometry + colour + agro-ecological style shift."""
    return transforms.Compose([
        transforms.RandomResizedCrop(INPUT_SIZE, scale=(0.6, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomVerticalFlip(),
        transforms.RandomApply([AgroStyleShift(strength=agro_strength)], p=0.8),
        transforms.ColorJitter(brightness=0.25, contrast=0.25,
                               saturation=0.25, hue=0.05),
        transforms.RandomRotation(30),
        transforms.ToTensor(),
        transforms.RandomApply([AddSensorNoise(0.03)], p=0.4),
        transforms.Normalize(_IMAGENET_MEAN, _IMAGENET_STD),
    ])


# Named location-shift domains for evaluation. Each fixes the appearance to a
# deterministic look so we can measure accuracy per "unseen location".
_EVAL_DOMAINS: dict[str, dict] = {
    "highland_cool_bright": dict(warmth=-0.8, brightness=1.22, contrast=1.15,
                                 saturation=1.18, blur=0.0),
    "lowland_warm_hazy": dict(warmth=0.85, brightness=1.05, contrast=0.78,
                              saturation=0.85, blur=1.1),
    "humid_lowcontrast": dict(warmth=0.25, brightness=1.08, contrast=0.7,
                              saturation=0.9, blur=0.8),
    "dry_dusty_warm": dict(warmth=0.7, brightness=0.9, contrast=0.95,
                           saturation=0.78, blur=0.2),
}

EVAL_DOMAIN_NAMES = list(_EVAL_DOMAINS.keys())


class FixedDomainShift:
    """Deterministic agro-ecological appearance for one evaluation domain.

    A picklable callable (works with DataLoader multiprocessing on macOS).
    """

    def __init__(self, domain: str) -> None:
        self.spec = _EVAL_DOMAINS[domain]

    def __call__(self, img: Image.Image) -> Image.Image:
        spec = self.spec
        img = _white_balance(img, spec["warmth"])
        img = ImageEnhance.Brightness(img).enhance(spec["brightness"])
        img = ImageEnhance.Contrast(img).enhance(spec["contrast"])
        img = ImageEnhance.Color(img).enhance(spec["saturation"])
        if spec["blur"] > 0:
            img = img.filter(ImageFilter.GaussianBlur(spec["blur"]))
        return img


def build_eval_domain_transform(domain: str) -> transforms.Compose:
    """Deterministic transform that renders val images in a given 'location'."""
    return transforms.Compose([
        transforms.Resize(int(INPUT_SIZE * 1.15)),
        transforms.CenterCrop(INPUT_SIZE),
        FixedDomainShift(domain),
        transforms.ToTensor(),
        transforms.Normalize(_IMAGENET_MEAN, _IMAGENET_STD),
    ])
