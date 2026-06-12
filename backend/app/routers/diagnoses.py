from fastapi import APIRouter, Depends
from ..auth import get_current_user
from ..database import diagnoses_col
from ..models.diagnosis import DiagnosisOut

router = APIRouter(prefix="/diagnoses", tags=["diagnoses"])


@router.get("/", response_model=list[DiagnosisOut])
async def list_diagnoses(
    farm_id: str | None = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
):
    query: dict = {"user_id": current_user["_id"]}
    if farm_id:
        query["farm_id"] = farm_id
    cursor = diagnoses_col().find(query, sort=[("created_at", -1)], limit=limit)
    docs = await cursor.to_list(limit)

    def _to_out(d: dict) -> DiagnosisOut:
        return DiagnosisOut(
            id=d["_id"],
            user_id=d["user_id"],
            farm_id=d.get("farm_id"),
            crop=d["crop"],
            disease=d["disease"],
            confidence=d["confidence"],
            recommendation=d.get("recommendation", ""),
            image_url=d.get("image_url"),
            is_offline=d.get("is_offline", False),
            created_at=d["created_at"],
        )

    return [_to_out(d) for d in docs]
