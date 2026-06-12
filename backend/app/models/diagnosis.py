from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class DiagnosisOut(BaseModel):
    id: str
    user_id: str
    farm_id: Optional[str] = None
    crop: str
    disease: str
    confidence: float
    recommendation: str
    severity: Optional[str] = None
    actions: list[str] = []
    image_url: Optional[str] = None
    is_offline: bool = False
    created_at: datetime


class AnalyzeRequest(BaseModel):
    """Used when sending base64 image from mobile (alternative to multipart)."""
    crop: str = Field(..., examples=["tomato"])
    image_b64: str
    farm_id: Optional[str] = None


class AnalyzeResult(BaseModel):
    disease: str
    confidence: float
    recommendation: str
    severity: Optional[str] = None
    actions: list[str] = []
    all_probabilities: dict[str, float]
    diagnosis_id: Optional[str] = None
