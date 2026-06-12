import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status

from ..auth import get_current_user
from ..database import diagnoses_col, farms_col
from ..models.farm import FarmCreate, FarmOut, FarmUpdate

router = APIRouter(prefix="/farms", tags=["farms"])


def _farm_to_out(doc: dict) -> FarmOut:
    return FarmOut(
        id=doc["_id"],
        user_id=doc["user_id"],
        name=doc["name"],
        country=doc.get("country", ""),
        region=doc.get("region", ""),
        latitude=doc.get("latitude"),
        longitude=doc.get("longitude"),
        size_ha=doc.get("size_ha", 0.0),
        crops=doc.get("crops", []),
        health_status=doc.get("health_status", "unknown"),
        notes=doc.get("notes", ""),
        health_score=doc.get("health_score"),
        last_scanned_at=doc.get("last_scanned_at"),
        created_at=doc["created_at"],
    )


async def _compute_health_score(farm_id: str) -> Optional[float]:
    """Compute 0-100 health score from the 10 most recent diagnoses."""
    cursor = diagnoses_col().find(
        {"farm_id": farm_id},
        sort=[("created_at", -1)],
        limit=10,
    )
    rows = await cursor.to_list(10)
    if not rows:
        return None
    total = 0.0
    for r in rows:
        conf = float(r.get("confidence", 0))
        if r.get("disease") == "healthy":
            total += conf * 100
        else:
            total += (1 - conf) * 100
    return round(min(max(total / len(rows), 0), 100), 1)


@router.get("/", response_model=list[FarmOut])
async def list_farms(current_user: dict = Depends(get_current_user)):
    cursor = farms_col().find({"user_id": current_user["_id"]})
    farms = await cursor.to_list(500)
    return [_farm_to_out(f) for f in farms]


@router.post("/", response_model=FarmOut, status_code=201)
async def create_farm(
    body: FarmCreate, current_user: dict = Depends(get_current_user)
):
    farm_id = str(uuid.uuid4())
    doc = {
        "_id": farm_id,
        "user_id": current_user["_id"],
        **body.model_dump(),
        "health_score": None,
        "last_scanned_at": None,
        "created_at": datetime.now(timezone.utc),
    }
    await farms_col().insert_one(doc)
    return _farm_to_out(doc)


@router.put("/{farm_id}", response_model=FarmOut)
async def update_farm(
    farm_id: str,
    body: FarmUpdate,
    current_user: dict = Depends(get_current_user),
):
    doc = await farms_col().find_one(
        {"_id": farm_id, "user_id": current_user["_id"]}
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Farm not found")

    update_data = body.model_dump()
    # Recompute health score on every update
    update_data["health_score"] = await _compute_health_score(farm_id)

    await farms_col().update_one({"_id": farm_id}, {"$set": update_data})
    doc.update(update_data)
    return _farm_to_out(doc)


@router.delete("/{farm_id}", status_code=204)
async def delete_farm(
    farm_id: str, current_user: dict = Depends(get_current_user)
):
    result = await farms_col().delete_one(
        {"_id": farm_id, "user_id": current_user["_id"]}
    )
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Farm not found")


@router.get("/{farm_id}/health", summary="Get health score for a specific farm")
async def farm_health(
    farm_id: str, current_user: dict = Depends(get_current_user)
):
    doc = await farms_col().find_one(
        {"_id": farm_id, "user_id": current_user["_id"]}
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Farm not found")
    score = await _compute_health_score(farm_id)
    # Persist latest score
    await farms_col().update_one(
        {"_id": farm_id}, {"$set": {"health_score": score}}
    )
    return {"farm_id": farm_id, "health_score": score}
