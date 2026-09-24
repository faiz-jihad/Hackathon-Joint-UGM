import logging
import sys
import json
import time
from typing import Optional, Any, Dict

# Create custom structured formatter
class StructuredFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        if hasattr(record, "screening_id"):
            log_data["screening_id"] = record.screening_id
        if hasattr(record, "model_version"):
            log_data["model_version"] = record.model_version
        if hasattr(record, "processing_time_ms"):
            log_data["processing_time_ms"] = record.processing_time_ms
        if hasattr(record, "quality_result"):
            log_data["quality_result"] = record.quality_result
        if hasattr(record, "reliability_result"):
            log_data["reliability_result"] = record.reliability_result
        if hasattr(record, "error_code"):
            log_data["error_code"] = record.error_code

        return json.dumps(log_data)

def setup_logger(name: str = "retiva-ai") -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(StructuredFormatter())
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    return logger

logger = setup_logger()

def log_screening_event(
    screening_id: str,
    model_version: str,
    processing_time_ms: float,
    quality_passed: bool,
    reliability_status: str,
    request_id: Optional[str] = None,
    error_code: Optional[str] = None,
    extra_details: Optional[str] = None,
):
    """
    Audit-compliant event logger per Section 15.
    STRICT PRIVACY: Never logs raw patient images or personal health information.
    """
    record = logging.LogRecord(
        name="retiva-ai.screening",
        level=logging.INFO if not error_code else logging.WARNING,
        pathname=__file__,
        lineno=0,
        msg=f"Screening evaluation complete: status={reliability_status}, quality={quality_passed}" + (f" ({extra_details})" if extra_details else ""),
        args=(),
        exc_info=None,
    )
    record.request_id = request_id or screening_id
    record.screening_id = screening_id
    record.model_version = model_version
    record.processing_time_ms = round(processing_time_ms, 2)
    record.quality_result = "PASSED" if quality_passed else "FAILED"
    record.reliability_result = reliability_status
    if error_code:
        record.error_code = error_code

    logger.handle(record)
