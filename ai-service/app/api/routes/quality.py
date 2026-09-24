from fastapi import APIRouter, Request, HTTPException, status
from app.api.utils import resolve_image_bytes
from app.services.quality_service import quality_service
from app.schemas.quality import QualityCheckResult

router = APIRouter(prefix="/api/v1", tags=["Quality Gate"])

@router.post("/quality/check", response_model=QualityCheckResult)
@router.post("/quality-check", response_model=QualityCheckResult)
async def check_image_quality(request: Request):
    """
    Evaluates fundus image quality before running inference:
    - Blur / optical sharpness (Laplacian variance)
    - Luminance & exposure (central retina brightness)
    - Field of view (45-degree circular aperture coverage)
    - Image dimensions (minimum 300x300)
    Supports multipart/form-data upload or JSON payload with image_url.
    """
    image_bytes, _ = await resolve_image_bytes(request)
    result = quality_service.evaluate_quality(image_bytes)
    return result
