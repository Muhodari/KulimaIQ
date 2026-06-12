from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class FarmCreate(BaseModel):
    name: str = Field(..., min_length=1)
    country: str = ""
    region: str = ""
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    size_ha: float = 0.0
    crops: list[str] = []
    health_status: str = "unknown"
    notes: str = ""


class FarmUpdate(FarmCreate):
    pass


class FarmOut(FarmCreate):
    id: str
    user_id: str
    health_score: Optional[float] = None
    last_scanned_at: Optional[datetime] = None
    created_at: datetime
