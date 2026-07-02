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
    Keep only classes for the selected crop (+ shared healthy), then re-normalize.

    Without this step a multi-crop model can return e.g. tomato_late_blight when
    the user scanned cassava leaves with crop=cassava.
    """
    filtered = {
        label: prob
        for label, prob in all_probs.items()
        if label == "healthy" or label.startswith(f"{crop}_")
    }
    if not filtered:
        return {}
    total = sum(filtered.values())
    if total <= 0:
        return filtered
    return {label: prob / total for label, prob in filtered.items()}


# ── Module-level singleton ────────────────────────────────────────────────────

_service: Optional[InferenceService] = None


def get_inference_service() -> InferenceService:
    global _service
    if _service is None:
        _service = InferenceService()
    return _service


def init_inference_service(weights_path: str) -> None:
    get_inference_service().load(weights_path)
