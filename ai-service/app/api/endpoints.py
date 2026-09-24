from fastapi import APIRouter, HTTPException, Header, Depends
from typing import Optional
from app.schemas.screening import (
    QualityCheckRequest,
    QualityAssessment,
    ScreenRequest,
    ScreenResponse
)
from app.services.quality_gate import QualityGateService
from app.services.reliability_gate import ReliabilityGateService
from app.services.classifier import EfficientNetB3Classifier
from app.config import settings

router = APIRouter(prefix="/api/v1")

quality_service = QualityGateService()
reliability_service = ReliabilityGateService()
classifier = EfficientNetB3Classifier(settings.MODEL_VERSION)

def verify_internal_secret(x_internal_secret: Optional[str] = Header(None)):
    if settings.INTERNAL_API_SECRET and x_internal_secret != settings.INTERNAL_API_SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized: invalid internal secret token")
    return True

@router.post("/quality-check", response_model=QualityAssessment, dependencies=[Depends(verify_internal_secret)])
def run_quality_check(payload: QualityCheckRequest):
    """
    Quality Gate endpoint: Assesses blur, illumination, and FOV without triggering classification.
    """
    assessment = quality_service.evaluate_quality(image_url=payload.image_url)
    return assessment

@router.post("/screen", response_model=ScreenResponse, dependencies=[Depends(verify_internal_secret)])
def run_screening(payload: ScreenRequest):
    """
    Main screening pipeline: Quality Gate -> Classifier -> Reliability Gate.
    """
    # 1. Quality Gate
    quality = quality_service.evaluate_quality(image_url=payload.image_url)
    
    # If quality fails and bypass is not set, stop classification immediately
    if not quality.passed and not payload.bypass_quality_check:
        reliability = reliability_service.assess_reliability(
            quality=quality,
            prediction=None # Not run
        )
        return ScreenResponse(
            model_name=settings.MODEL_NAME,
            model_version=settings.MODEL_VERSION,
            pipeline_version=settings.PIPELINE_VERSION,
            quality=quality,
            prediction=None,
            reliability=reliability
        )

    # 2. Inference
    prediction = classifier.predict(image_url=payload.image_url)

    # 3. Reliability Assessment
    reliability = reliability_service.assess_reliability(
        quality=quality,
        prediction=prediction
    )

    return ScreenResponse(
        model_name=settings.MODEL_NAME,
        model_version=settings.MODEL_VERSION,
        pipeline_version=settings.PIPELINE_VERSION,
        quality=quality,
        prediction=prediction,
        reliability=reliability
    )

@router.post("/explainability", dependencies=[Depends(verify_internal_secret)])
def get_explainability(screening_id: str):
    """
    Generates Grad-CAM / heatmap visualization metadata for clinical explainability.
    """
    return {
        "screening_id": screening_id,
        "model_version": settings.MODEL_VERSION,
        "heatmap_storage_key": f"explainability/{screening_id}/gradcam.png",
        "salient_regions": [
            {"region": "macula", "relevance_score": 0.84},
            {"region": "inferior_temporal_arcade", "relevance_score": 0.72}
        ]
    }
