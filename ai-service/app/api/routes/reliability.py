from typing import Optional, Dict
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from app.services.reliability_service import reliability_service
from app.schemas.quality import QualityCheckResult
from app.schemas.screening import PredictionResult
from app.schemas.reliability import ReliabilityResult

router = APIRouter(prefix="/api/v1/reliability", tags=["Reliability Gate"])

class ReliabilityCheckRequest(BaseModel):
    quality: QualityCheckResult
    prediction: Optional[PredictionResult] = None

@router.post("/check", response_model=ReliabilityResult)
def check_reliability(payload: ReliabilityCheckRequest):
    """
    Evaluates clinical reliability score, prediction entropy, margin,
    and returns decision: 'ANALYZE', 'HUMAN_REVIEW', or 'RETAKE'.
    """
    result = reliability_service.evaluate_reliability(
        quality=payload.quality,
        prediction=payload.prediction
    )
    return result
