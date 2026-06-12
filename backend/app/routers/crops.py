"""
/crops  — expose the model's known crop and disease classes.

The Flutter app can call GET /crops/classes to discover what the
deployed model supports, enabling it to offer an up-to-date crop
selector without requiring an app update.
"""

import json
from pathlib import Path

from fastapi import APIRouter
from pydantic import BaseModel

from ..ml.inference import get_inference_service

router = APIRouter(prefix="/crops", tags=["crops"])

# ── Load human-readable metadata from recommendations.json ───────────────────

_RECS_PATH = Path(__file__).parent.parent / "ml" / "recommendations.json"


def _load_recs() -> dict:
    if _RECS_PATH.exists():
        data = json.loads(_RECS_PATH.read_text())
        return {k: v for k, v in data.items() if not k.startswith("_")}
    return {}


# ── Response models ───────────────────────────────────────────────────────────


class DiseaseInfo(BaseModel):
    id: str
    title: str
    severity: str
    crop: str


class CropInfo(BaseModel):
    id: str
    label: str
    diseases: list[DiseaseInfo]


class CropClassesResponse(BaseModel):
    model_loaded: bool
    raw_classes: list[str]
    crops: list[CropInfo]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _crop_label(crop_id: str) -> str:
    """'sweet_potato' → 'Sweet Potato'"""
    return " ".join(w.capitalize() for w in crop_id.split("_"))


def _build_crops(classes: list[str]) -> list[CropInfo]:
    """
    Group disease labels by their crop prefix.
    Convention: 'healthy' is shared; 'tomato_late_blight' belongs to 'tomato'.
    """
    recs = _load_recs()
    crop_map: dict[str, list[DiseaseInfo]] = {}

    for cls in classes:
        if "_" in cls:
            parts = cls.split("_", 1)
            crop_id = parts[0]
        elif cls == "healthy":
            crop_id = "general"
        else:
            crop_id = cls

        info = recs.get(cls, {})
        disease_info = DiseaseInfo(
            id=cls,
            title=info.get("title", _crop_label(cls)),
            severity=info.get("severity", "medium"),
            crop=crop_id,
        )
        crop_map.setdefault(crop_id, []).append(disease_info)

    return [
        CropInfo(
            id=crop_id,
            label=_crop_label(crop_id),
            diseases=diseases,
        )
        for crop_id, diseases in sorted(crop_map.items())
    ]


# ── Endpoints ─────────────────────────────────────────────────────────────────


@router.get(
    "/classes",
    response_model=CropClassesResponse,
    summary="List all crops and disease classes known by the deployed model",
)
async def list_classes():
    """
    Returns the full list of classes the currently loaded model can detect,
    grouped by crop for easy consumption by the mobile app.

    If the model is not yet loaded the raw_classes list will be empty and
    model_loaded will be false.
    """
    svc = get_inference_service()
    classes = svc.classes if svc.is_ready else []
    return CropClassesResponse(
        model_loaded=svc.is_ready,
        raw_classes=classes,
        crops=_build_crops(classes),
    )


@router.get(
    "/recommendations/{disease_id}",
    summary="Get treatment recommendations for a specific disease",
)
async def get_recommendation(disease_id: str):
    """
    Returns detailed treatment actions for any disease class the model knows.
    """
    recs = _load_recs()
    info = recs.get(disease_id)
    if not info:
        return {
            "id": disease_id,
            "title": _crop_label(disease_id),
            "severity": "medium",
            "summary": (
                "Please consult your local agricultural extension officer "
                "for specific treatment advice."
            ),
            "actions": [],
        }
    return {"id": disease_id, **info}
