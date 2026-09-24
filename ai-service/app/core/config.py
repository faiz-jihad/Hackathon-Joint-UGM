import os
from typing import List

class Settings:
    # Service Environment & Networking
    APP_ENV: str = os.getenv("APP_ENV", "development")
    PORT: int = int(os.getenv("PORT", "8003"))
    HOST: str = os.getenv("HOST", "0.0.0.0")

    # Model Configuration
    MODEL_NAME: str = os.getenv("MODEL_NAME", "EfficientNet-B3")
    MODEL_VERSION: str = os.getenv("MODEL_VERSION", "0.1.0")
    MODEL_PATH: str = os.getenv("MODEL_PATH", "models/efficientnet_b3/model.tflite")
    MODEL_METADATA_PATH: str = os.getenv("MODEL_METADATA_PATH", "models/efficientnet_b3/metadata.json")
    PIPELINE_VERSION: str = os.getenv("PIPELINE_VERSION", "retiva-pipeline-v1.2")

    # Target Classification Classes
    CLASSES: List[str] = [
        "No DR",
        "Mild",
        "Moderate",
        "Severe",
        "Proliferative DR",
    ]

    # Image Quality Gate Thresholds (Configurable, Section 5 & 19)
    QUALITY_THRESHOLD: float = float(os.getenv("QUALITY_THRESHOLD", "0.80"))
    QUALITY_BLUR_THRESHOLD: float = float(os.getenv("QUALITY_BLUR_THRESHOLD", "0.65"))
    QUALITY_BRIGHTNESS_MIN: float = float(os.getenv("QUALITY_BRIGHTNESS_MIN", "0.20"))
    QUALITY_BRIGHTNESS_MAX: float = float(os.getenv("QUALITY_BRIGHTNESS_MAX", "0.85"))
    QUALITY_FOV_MIN: float = float(os.getenv("QUALITY_FOV_MIN", "0.60"))
    MIN_IMAGE_DIMENSION: int = int(os.getenv("MIN_IMAGE_DIMENSION", "300"))
    MAX_IMAGE_SIZE_MB: int = int(os.getenv("MAX_IMAGE_SIZE_MB", "10"))

    # Reliability Gate Thresholds (Section 7 & 19)
    RELIABILITY_THRESHOLD: float = float(os.getenv("RELIABILITY_THRESHOLD", "0.80"))
    RELIABILITY_MARGIN_THRESHOLD: float = float(os.getenv("RELIABILITY_MARGIN_THRESHOLD", "0.15"))
    RELIABILITY_MAX_ENTROPY: float = float(os.getenv("RELIABILITY_MAX_ENTROPY", "1.25"))

    # Explainability (Section 8 & 19)
    GRADCAM_ENABLED: bool = os.getenv("GRADCAM_ENABLED", "true").lower() in ("true", "1", "yes")

    # Security
    INTERNAL_API_SECRET: str = os.getenv("INTERNAL_API_SECRET", "")

settings = Settings()
