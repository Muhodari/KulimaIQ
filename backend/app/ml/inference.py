"""
Singleton inference service — fully dynamic class list.

The model checkpoint stores the class labels, so the service works for
any number of crops/diseases without code changes.
"""

from pathlib import Path
from typing import Optional

import torch
import torch.nn.functional as F
from PIL import Image

from .dataset import inference_transform
from .model import load_model


class InferenceService:
    def __init__(self) -> None:
        self._model: Optional[torch.nn.Module] = None
        self._classes: list[str] = []
        self._device = torch.device("cpu")

    def load(self, weights_path: str) -> None:
        if not Path(weights_path).exists():
            print(
                f"[InferenceService] Weights not found at '{weights_path}'. "
                "API will return 503 until weights are placed there."
            )
            return
        self._model, self._classes = load_model(
            weights_path, device=str(self._device)
        )
        print(
            f"[InferenceService] Loaded model from '{weights_path}' "
            f"with {len(self._classes)} classes: {self._classes}"
        )

    @property
    def is_ready(self) -> bool:
        return self._model is not None

    @property
    def classes(self) -> list[str]:
        return list(self._classes)

    def predict(self, image: Image.Image) -> dict[str, float]:
        """Run inference. Returns {class_label: probability} for all classes."""
        if not self.is_ready:
            raise RuntimeError("Model is not loaded")
        tensor = inference_transform(image).unsqueeze(0).to(self._device)
        with torch.no_grad():
            logits = self._model(tensor)
            probs = F.softmax(logits, dim=1)[0]
        return {label: float(probs[i]) for i, label in enumerate(self._classes)}


def filter_probs_by_crop(
    all_probs: dict[str, float], crop: str
) -> dict[str, float]:
    """
    Keep only classes for the selected crop (+ shared healthy).

    Returns raw softmax probabilities (not re-normalized). Re-normalizing within
    a crop inflates "healthy" when all scores are low — the main cause of false
    healthy predictions in the app.
    """
    return {
        label: prob
        for label, prob in all_probs.items()
        if label == "healthy" or label.startswith(f"{crop}_")
    }


def normalize_probs(probs: dict[str, float]) -> dict[str, float]:
    """Re-normalize for display only (percentages within the crop)."""
    if not probs:
        return {}
    total = sum(probs.values())
    if total <= 0:
        return dict(probs)
    return {label: prob / total for label, prob in probs.items()}


def pick_crop_label(filtered_probs: dict[str, float]) -> tuple[str, float]:
    """
    Choose the best label for a crop scan.

    Prefer the strongest disease over the shared "healthy" bucket unless healthy
    clearly wins on raw model confidence.
    """
    if not filtered_probs:
        return "healthy", 0.0

    healthy_prob = filtered_probs.get("healthy", 0.0)
    disease_probs = {
        label: prob
        for label, prob in filtered_probs.items()
        if label != "healthy"
    }
    if not disease_probs:
        return "healthy", healthy_prob

    best_disease, best_disease_prob = max(
        disease_probs.items(), key=lambda item: item[1]
    )
    # In scan flow, false "healthy" is worse than naming a likely disease.
    # Only return healthy when the model is clearly confident it is healthy.
    healthy_clearly_wins = (
        healthy_prob >= 0.25
        and healthy_prob > best_disease_prob * 1.25
    )
    if healthy_clearly_wins:
        return "healthy", healthy_prob
    return best_disease, best_disease_prob


# ── Module-level singleton ────────────────────────────────────────────────────

_service: Optional[InferenceService] = None


def get_inference_service() -> InferenceService:
    global _service
    if _service is None:
        _service = InferenceService()
    return _service


def init_inference_service(weights_path: str) -> None:
    get_inference_service().load(weights_path)
