from typing import Optional, Dict
from pydantic import BaseModel, Field

class ReliabilityResult(BaseModel):
    status: str = Field(..., description="Exactly one of: 'RETAKE', 'HUMAN_REVIEW', 'ANALYZE'")
    score: float = Field(..., ge=0.0, le=1.0, description="Composite reliability score")
    confidence: Optional[float] = None
    margin: Optional[float] = Field(None, description="Difference between top-1 and top-2 class probability")
    entropy: Optional[float] = Field(None, description="Normalized predictive distribution entropy")
    thresholds: Dict[str, float] = Field(default_factory=dict)
    message: Optional[str] = None
    reason: Optional[str] = None

    # Interoperability fields
    confidence_threshold: Optional[float] = None
    quality_threshold: Optional[float] = None
