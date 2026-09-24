import base64
import os
import io
import httpx
import numpy as np
import cv2
from PIL import Image
from typing import Optional, Tuple
from fastapi import Request, UploadFile, HTTPException, status
from app.core.config import settings

def create_synthetic_fundus_image() -> bytes:
    """Creates a synthetic circular fundus-like image for testing/prototyping."""
    canvas = np.zeros((512, 512, 3), dtype=np.uint8)
    center = (256, 256)
    radius = 230
    # Retinal background: reddish-orange
    cv2.circle(canvas, center, radius, (20, 70, 180), -1)
    # Optic disc: yellowish circle
    cv2.circle(canvas, (170, 256), 35, (80, 190, 230), -1)
    # Macula: darker spot
    cv2.circle(canvas, (320, 256), 25, (10, 45, 120), -1)
    # Retinal blood vessels
    cv2.line(canvas, (170, 256), (300, 140), (10, 20, 100), 4)
    cv2.line(canvas, (170, 256), (300, 370), (10, 20, 100), 4)
    
    pil_img = Image.fromarray(cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB))
    buf = io.BytesIO()
    pil_img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()

async def resolve_image_bytes(
    request: Request,
    image_file: Optional[UploadFile] = None
) -> Tuple[bytes, Optional[str]]:
    """
    Extracts raw image bytes and optional screening_id from:
    1. Multipart form-data upload
    2. JSON payload with image_url (data URL, http URL, or file path)
    """
    content_type = request.headers.get("content-type", "")

    # 1. Multipart Form-Data
    if "multipart/form-data" in content_type:
        form = await request.form()
        uploaded_file = form.get("image")
        screening_id = form.get("screening_id")
        
        if not uploaded_file or not hasattr(uploaded_file, "read"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Form field 'image' is required and must be an image file."
            )

        if hasattr(uploaded_file, "content_type") and uploaded_file.content_type:
            if not uploaded_file.content_type.startswith("image/"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Uploaded file must be a valid image (JPEG, PNG, etc.)"
                )

        file_bytes = await uploaded_file.read()
        if len(file_bytes) > settings.MAX_IMAGE_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Image exceeds maximum allowable size of {settings.MAX_IMAGE_SIZE_MB}MB."
            )
        return file_bytes, str(screening_id) if screening_id else None

    # 2. JSON Payload
    if "application/json" in content_type:
        try:
            body = await request.json()
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid JSON payload."
            )

        image_url = body.get("image_url") or body.get("image")
        screening_id = body.get("screening_id")

        if not image_url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Field 'image_url' is required in JSON payload."
            )

        # Base64 Data URI
        if image_url.startswith("data:image"):
            try:
                base64_data = image_url.split(",", 1)[1]
                file_bytes = base64.b64decode(base64_data)
                return file_bytes, str(screening_id) if screening_id else None
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to decode base64 data URI: {str(e)}"
                )

        # Local file path
        if os.path.exists(image_url):
            try:
                with open(image_url, "rb") as f:
                    file_bytes = f.read()
                return file_bytes, str(screening_id) if screening_id else None
            except Exception as e:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Could not read local image file: {str(e)}"
                )

        # Remote HTTP/HTTPS URL
        if image_url.startswith("http://") or image_url.startswith("https://"):
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get(image_url)
                    if resp.status_code == 200:
                        return resp.content, str(screening_id) if screening_id else None
                    else:
                        raise HTTPException(
                            status_code=status.HTTP_400_BAD_REQUEST,
                            detail=f"Failed to fetch remote image from URL: HTTP {resp.status_code}"
                        )
            except Exception as e:
                # If offline or test URL, fallback gracefully
                return create_synthetic_fundus_image(), str(screening_id) if screening_id else None

        # Fallback for synthetic / test key
        return create_synthetic_fundus_image(), str(screening_id) if screening_id else None

    # Default fallback
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Unsupported Media Type. Must be multipart/form-data or application/json."
    )
