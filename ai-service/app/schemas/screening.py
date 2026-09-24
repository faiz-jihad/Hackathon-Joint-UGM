from typing import Dict, Optional, List
from pydantic import BaseModel, Field

class QualityCheckRequest(BaseModel):
    image_url: Optional[str] = None
    storage_key: Optional[str] = None
    eye: str = Field(default="OD", description="OD (Right) or OS (Left)")

class QualityAssessment(BaseModel):
    passed: bool = False
    overall_score: float
    blur_score: float
    illumination_score: float
    fov_score: float
    retake_reason: Optional[str] = None
    retake_instructions: Optional[str] = None

# Fixing bool type
QualityAssessment.model_rebuild()

class ScreenRequest(BaseModel):
    image_url: Optional[str] = None
    storage_key: Optional[str] = None
    eye: str = "OD"
    bypass_quality_check: bool = False

class PredictionResult(BaseModel):
    predicted_class: str
    class_index: int
    confidence: float
    raw_probabilities: Dict[str, float]

class ReliabilityResult(BaseModel):
    status: str  # "analyze" | "human_review" | "retake"
    score: float
    confidence_threshold: float
    quality_threshold: float
    reason: Optional[str] = None

class ScreenResponse(BaseModel):
    model_name: str
    model_version: str
    pipeline_version: str
    quality: QualityAssessment
    prediction: Optional[PredictionResult] = None
    reliability: Optional[ReliabilityResult] = None
