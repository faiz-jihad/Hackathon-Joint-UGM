import time
import uuid
from typing import Optional, Union, Tuple
from PIL import Image
import numpy as np
from app.core.config import settings
from app.core.logging import log_screening_event
from app.models.efficientnet import efficientnet_b3
from app.services.quality_service import quality_service
from app.services.reliability_service import reliability_service
from app.services.gradcam_service import gradcam_service
from app.schemas.screening import (
    ScreeningResponse,
    PredictionResult,
    ModelMetadata,
    ExplainabilityResult,
    SAFETY_DISCLAIMER
)
from app.schemas.quality import QualityCheckResult
from app.schemas.reliability import ReliabilityResult

class InferenceService:
    """
    Core Pipeline Coordinator implementing the RETIVA Reliability-First Workflow:
        Fundus Image
            ↓
        Image Quality Gate (RETAKE if low quality)
            ↓
        EfficientNet-B3 (Skipped if quality fails)
            ↓
        Reliability Gate (RETAKE | HUMAN_REVIEW | ANALYZE)
            ↓
        Grad-CAM (Isolated error-handling)
            ↓
        Screening Result
    """
    def __init__(self):
        self.model_metadata = ModelMetadata(
            name=settings.MODEL_NAME,
            version=settings.MODEL_VERSION,
            classes=settings.CLASSES
        )

    def run_screening_pipeline(
        self,
        image_bytes: bytes,
        screening_id: Optional[str] = None,
        request_id: Optional[str] = None
    ) -> ScreeningResponse:
        start_time = time.perf_counter()
        active_id = screening_id or f"scr_{uuid.uuid4().hex[:10]}"

        # Step 1: Image Quality Gate Evaluation
        quality_result: QualityCheckResult = quality_service.evaluate_quality(image_bytes)

        # Step 2: Quality Gate Enforcement (Section 6 & 13)
        # If quality fails, bypass classifier inference completely to prevent hallucinated predictions
        if not quality_result.passed:
            reliability_result: ReliabilityResult = reliability_service.evaluate_reliability(
                quality=quality_result,
                prediction=None
            )
            elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

            log_screening_event(
                screening_id=active_id,
                model_version=settings.MODEL_VERSION,
                processing_time_ms=elapsed_ms,
                quality_passed=False,
                reliability_status="RETAKE",
                request_id=request_id,
                extra_details="Bypassed classifier due to quality gate failure"
            )

            return ScreeningResponse(
                screening_id=active_id,
                status="RETAKE",
                quality=quality_result,
                prediction=None,
                reliability=reliability_result,
                explainability=None,
                model=self.model_metadata,
                safety_notice=SAFETY_DISCLAIMER,
                processing_time_ms=elapsed_ms,
                model_name=settings.MODEL_NAME,
                model_version=settings.MODEL_VERSION,
                pipeline_version=settings.PIPELINE_VERSION
            )

        # Step 3: EfficientNet-B3 Classification
        prediction_result, feature_map = efficientnet_b3.predict(image_bytes)

        # Step 4: Reliability Gate Evaluation
        reliability_result: ReliabilityResult = reliability_service.evaluate_reliability(
            quality=quality_result,
            prediction=prediction_result
        )

        # Step 5: Explainability (Grad-CAM)
        # Isolated execution: failure will never crash the screening result
        explainability_result: Optional[ExplainabilityResult] = None
        if settings.GRADCAM_ENABLED:
            explainability_result = gradcam_service.generate_heatmap(
                image_input=image_bytes,
                feature_map=feature_map,
                target_class_idx=prediction_result.class_index
            )

        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

        # Step 6: Audit-compliant logging
        log_screening_event(
            screening_id=active_id,
            model_version=settings.MODEL_VERSION,
            processing_time_ms=elapsed_ms,
            quality_passed=True,
            reliability_status=reliability_result.status,
            request_id=request_id,
            extra_details=f"Class={prediction_result.predicted_class}, Conf={prediction_result.confidence}"
        )

        return ScreeningResponse(
            screening_id=active_id,
            status=reliability_result.status,
            quality=quality_result,
            prediction=prediction_result,
            reliability=reliability_result,
            explainability=explainability_result,
            model=self.model_metadata,
            safety_notice=SAFETY_DISCLAIMER,
            processing_time_ms=elapsed_ms,
            model_name=settings.MODEL_NAME,
            model_version=settings.MODEL_VERSION,
            pipeline_version=settings.PIPELINE_VERSION
        )

inference_service = InferenceService()
