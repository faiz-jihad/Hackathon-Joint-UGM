from typing import Dict, Optional, List, Any
from pydantic import BaseModel, Field, computed_field
from app.schemas.quality import QualityCheckResult
from app.schemas.reliability import ReliabilityResult

class PredictionResult(BaseModel):
    class_: str = Field(..., alias="class", description="Predicted clinical class e.g. 'Moderate'")
    class_index: int = Field(..., description="Class index (0-4)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Highest class probability")
    probabilities: Dict[str, float] = Field(..., description="Probabilities across all 5 classes")
    model_version: str
    inference_time_ms: float
    raw_probabilities: Optional[Dict[str, float]] = None

    @computed_field
    @property
    def predicted_class(self) -> str:
        return self.class_

    model_config = {
        "populate_by_name": True,
        "serialize_by_alias": True
    }

class ExplainabilityResult(BaseModel):
    available: bool
    heatmap_url: Optional[str] = None
    overlay_url: Optional[str] = None
    reason: Optional[str] = None

class ModelMetadata(BaseModel):
    name: str = "EfficientNet-B3"
    version: str = "0.1.0"
    classes: List[str] = [
        "No DR",
        "Mild",
        "Moderate",
        "Severe",
        "Proliferative DR"
    ]

SAFETY_DISCLAIMER = (
    "The screening result indicates that further assessment may be appropriate. "
    "This result is not a diagnosis. Please consult a healthcare professional."
)

class ScreeningResponse(BaseModel):
    screening_id: str
    status: str = Field(..., description="Exactly one of: 'ANALYZE', 'HUMAN_REVIEW', 'RETAKE'")
    quality: QualityCheckResult
    prediction: Optional[PredictionResult] = None
    reliability: ReliabilityResult
    explainability: Optional[ExplainabilityResult] = None
    model: ModelMetadata
    safety_notice: str = SAFETY_DISCLAIMER
    processing_time_ms: float

    # Interoperability fields
    model_name: Optional[str] = None
    model_version: Optional[str] = None
    pipeline_version: Optional[str] = None

    model_config = {
        "populate_by_name": True,
        "serialize_by_alias": True
    }

class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Any] = None

class ErrorResponse(BaseModel):
    error: ErrorDetail

class QualityCheckRequest(BaseModel):
    image_url: Optional[str] = None
    eye: Optional[str] = "OD"

class ScreenRequest(BaseModel):
    image_url: Optional[str] = None
    eye: Optional[str] = "OD"
    bypass_quality_check: Optional[bool] = False
