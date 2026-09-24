from fastapi import APIRouter
from app.core.config import settings
from app.models.model_loader import model_loader

router = APIRouter(tags=["Health & Model"])

@router.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "retiva-ai-service",
        "model": settings.MODEL_NAME,
        "version": settings.MODEL_VERSION,
        "pipeline_version": settings.PIPELINE_VERSION,
        "quality_gate": "active",
        "reliability_gate": "active",
        "gradcam_enabled": settings.GRADCAM_ENABLED
    }

@router.get("/api/v1/model/info")
def get_model_info():
    meta = model_loader.get_metadata()
    return {
        "model_name": meta.get("model_name", settings.MODEL_NAME),
        "version": meta.get("version", settings.MODEL_VERSION),
        "input_resolution": [300, 300, 3],
        "classes": meta.get("classes", settings.CLASSES),
        "thresholds": {
            "quality_threshold": settings.QUALITY_THRESHOLD,
            "reliability_threshold": settings.RELIABILITY_THRESHOLD,
            "margin_threshold": settings.RELIABILITY_MARGIN_THRESHOLD,
            "max_entropy": settings.RELIABILITY_MAX_ENTROPY
        },
        "explainability": {
            "gradcam": settings.GRADCAM_ENABLED
        },
        "status": "ready"
    }
