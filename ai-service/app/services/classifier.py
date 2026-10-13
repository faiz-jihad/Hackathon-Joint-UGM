from typing import Dict, Optional
import math
from app.schemas.screening import PredictionResult

DR_CLASSES = [
    "NO_DR",
    "MILD_DR",
    "MODERATE_DR",
    "SEVERE_DR",
    "PROLIFERATIVE_DR"
]

from typing import Optional, Union
from app.schemas.screening import PredictionResult
from app.models.efficientnet import efficientnet_b3

DR_CLASSES = [
    "No DR",
    "Mild",
    "Moderate",
    "Severe",
    "Proliferative DR"
]

class EfficientNetB3Classifier:
    """
    Standard-compliant wrapper for EfficientNet-B3 Diabetic Retinopathy 5-Class Classifier.
    Resolution: 300x300, 5-class Softmax.
    Strictly performs real inference via loaded model weights.
    """
    def __init__(self, model_version: str = "0.1.0"):
        self.model_version = model_version

    def predict(
        self,
        image_data: Optional[bytes] = None,
        image_url: Optional[str] = None
    ) -> PredictionResult:
        if image_data is None:
            raise ValueError("image_data is required for standard clinical inference.")
        
        result, _ = efficientnet_b3.predict(image_data)
        return result

