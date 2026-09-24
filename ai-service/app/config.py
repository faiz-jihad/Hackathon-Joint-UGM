import os

class Settings:
    MODEL_NAME: str = os.getenv("MODEL_NAME", "efficientnet-b3")
    MODEL_VERSION: str = os.getenv("MODEL_VERSION", "efficientnet-b3-v1.0.0")
    PIPELINE_VERSION: str = os.getenv("PIPELINE_VERSION", "retiva-pipeline-v1.0")
    INTERNAL_API_SECRET: str = os.getenv("INTERNAL_API_SECRET", "retiva-internal-secret-token")
    
    # Versioned & Configurable Quality & Reliability Thresholds
    QUALITY_PASS_THRESHOLD: float = float(os.getenv("QUALITY_PASS_THRESHOLD", "0.75"))
    RELIABILITY_HIGH_THRESHOLD: float = float(os.getenv("RELIABILITY_HIGH_THRESHOLD", "0.85"))
    RELIABILITY_LOW_THRESHOLD: float = float(os.getenv("RELIABILITY_LOW_THRESHOLD", "0.60"))

settings = Settings()
