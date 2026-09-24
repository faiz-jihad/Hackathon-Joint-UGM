from typing import Optional
from fastapi import APIRouter, Request, Header, HTTPException, status
from app.api.utils import resolve_image_bytes
from app.services.inference_service import inference_service
from app.schemas.screening import ScreeningResponse

router = APIRouter(prefix="/api/v1", tags=["Screening Pipeline"])

@router.post("/screen", response_model=ScreeningResponse)
async def screen_fundus_image(
    request: Request,
    x_request_id: Optional[str] = Header(None, alias="X-Request-ID")
):
    """
    Main RETIVA Screening Pipeline:
        Fundus Image (multipart/form-data or application/json)
            ↓
        Image Quality Gate (RETAKE if blurry, underexposed, or low-res)
            ↓
        EfficientNet-B3 Inference (Bypassed if quality fails)
            ↓
        Reliability Gate (RETAKE | HUMAN_REVIEW | ANALYZE)
            ↓
        Grad-CAM Heatmap & Overlay
            ↓
        Screening Result
    """
    image_bytes, screening_id = await resolve_image_bytes(request)

    response = inference_service.run_screening_pipeline(
        image_bytes=image_bytes,
        screening_id=screening_id,
        request_id=x_request_id
    )

    return response
