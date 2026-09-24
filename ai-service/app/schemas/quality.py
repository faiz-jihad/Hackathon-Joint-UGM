from typing import Optional, Dict
from pydantic import BaseModel, Field

class QualitySubCheck(BaseModel):
    passed: bool
    score: float = Field(..., ge=0.0, le=1.0, description="Normalized quality metric between 0 and 1")
    details: Optional[str] = None

class QualityChecks(BaseModel):
    blur: QualitySubCheck
    brightness: QualitySubCheck
    field_of_view: QualitySubCheck
    dimensions: Optional[QualitySubCheck] = None

class QualityCheckResult(BaseModel):
    passed: bool
    score: float = Field(..., ge=0.0, le=1.0)
    checks: QualityChecks
    decision: str = Field(..., description="'ANALYZE' if passed, else 'RETAKE'")
    reason: Optional[str] = None
    instructions: Optional[str] = None

    # Interoperability fields
    overall_score: Optional[float] = None
    blur_score: Optional[float] = None
    illumination_score: Optional[float] = None
    fov_score: Optional[float] = None
    retake_reason: Optional[str] = None
    retake_instructions: Optional[str] = None
