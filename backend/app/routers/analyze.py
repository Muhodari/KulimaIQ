"""
Analyze router — location-invariant disease detection.

The deployed vision model is trained to detect disease from the leaf alone,
robust to agro-ecological location (see app/ml/train_robust.py). No location,
GPS or zone is required or used at scan time — the request carries only the
leaf photo and the crop.

Recommendations are loaded from app/ml/recommendations.json at startup. Any
class label from the trained model works; unknown labels get a fallback.
"""

import base64
import io
import json
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image

from ..auth import get_current_user
from ..database import diagnoses_col, farms_col
from ..ml.inference import filter_probs_by_crop, get_inference_service
from ..models.diagnosis import AnalyzeResult

router = APIRouter(prefix="/analyze", tags=["analyze"])

# ── Load recommendations from JSON ────────────────────────────────────────────

_RECS_PATH = Path(__file__).parent.parent / "ml" / "recommendations.json"

def _load_recommendations() -> dict:
    if _RECS_PATH.exists():
        data = json.loads(_RECS_PATH.read_text())
        return {k: v for k, v in data.items() if not k.startswith("_")}
    return {}


_RECOMMENDATIONS: dict[str, dict] = _load_recommendations()


def _get_recommendation(label: str) -> str:
    info = _RECOMMENDATIONS.get(label)
    if info:
        return info.get("summary", "")
    parts = label.replace("_", " ").split()
    if len(parts) >= 2 and parts[-1] == "healthy":
        return f"Your {' '.join(parts[:-1])} plant looks healthy. Continue regular monitoring."
    human = " ".join(w.capitalize() for w in parts)
    return (
        f"{human} detected. Please consult your local agricultural extension officer "
        "for specific treatment advice."
    )


def _get_severity(label: str) -> str:
    info = _RECOMMENDATIONS.get(label, {})
    return info.get("severity", "medium")


def _get_actions(label: str) -> list[str]:
    info = _RECOMMENDATIONS.get(label, {})
    return info.get("actions", [])


# ── Core analysis logic ───────────────────────────────────────────────────────


async def _run_analysis(
    image_bytes: bytes,
    crop: str,
    farm_id: Optional[str],
    current_user: dict,
) -> AnalyzeResult:
    svc = get_inference_service()
    if not svc.is_ready:
        raise HTTPException(
            status_code=503,
            detail=(
                "ML model not loaded. Train the model first "
                "(python -m app.ml.train_robust) or place pre-trained weights at "
                "model_weights/kulimaiq_mobilenet.pth"
            ),
        )

    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")

    raw_probabilities = svc.predict(image)
    probabilities = filter_probs_by_crop(raw_probabilities, crop)
    if not probabilities:
        supported = sorted(
            {
                label.split("_", 1)[0]
                for label in raw_probabilities
                if label != "healthy" and "_" in label
            }
        )
        raise HTTPException(
            status_code=400,
            detail=(
                f"Crop '{crop}' is not supported by the deployed model. "
                f"Supported crops: {', '.join(supported)}"
            ),
        )

    top_label = max(probabilities, key=lambda k: probabilities[k])
    confidence = probabilities[top_label]

    recommendation = _get_recommendation(top_label)
    severity = _get_severity(top_label)
    actions = _get_actions(top_label)

    # Persist to MongoDB
    diagnosis_id = str(uuid.uuid4())
    doc = {
        "_id": diagnosis_id,
        "user_id": current_user["_id"],
        "farm_id": farm_id,
        "crop": crop,
        "disease": top_label,
        "confidence": confidence,
        "recommendation": recommendation,
        "severity": severity,
        "actions": actions,
        "is_offline": False,
        "created_at": datetime.now(timezone.utc),
    }
    await diagnoses_col().insert_one(doc)

    if farm_id:
        await farms_col().update_one(
            {"_id": farm_id},
            {"$set": {"last_scanned_at": doc["created_at"]}},
        )

    return AnalyzeResult(
        disease=top_label,
        confidence=round(confidence, 4),
        recommendation=recommendation,
        severity=severity,
        actions=actions,
        all_probabilities={k: round(v, 4) for k, v in probabilities.items()},
        diagnosis_id=diagnosis_id,
    )


# ── Endpoints ─────────────────────────────────────────────────────────────────


@router.post(
    "/image",
    response_model=AnalyzeResult,
    summary="Analyze a leaf image (multipart upload)",
)
async def analyze_image(
    image: UploadFile = File(..., description="Leaf photograph (JPEG/PNG)"),
    crop: str = Form(..., description="Crop type slug (e.g. tomato, maize, cassava)"),
    farm_id: Optional[str] = Form(None),
    current_user: dict = Depends(get_current_user),
):
    image_bytes = await image.read()
    return await _run_analysis(image_bytes, crop, farm_id, current_user)


@router.post(
    "/base64",
    response_model=AnalyzeResult,
    summary="Analyze a leaf image (base64 JSON body)",
)
async def analyze_base64(
    crop: str,
    image_b64: str,
    farm_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    try:
        image_bytes = base64.b64decode(image_b64)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid base64 string")
    return await _run_analysis(image_bytes, crop, farm_id, current_user)
