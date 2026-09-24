import time
import io
import numpy as np
from PIL import Image
from typing import Dict, Tuple, Optional, Union
from app.core.config import settings
from app.models.model_loader import model_loader
from app.schemas.screening import PredictionResult

class EfficientNetB3:
    """
    EfficientNet-B3 Diabetic Retinopathy Classifier.
    - Native Resolution: 300x300x3
    - Classes (5-class ICDR):
        0: 'No DR'
        1: 'Mild'
        2: 'Moderate'
        3: 'Severe'
        4: 'Proliferative DR'
    """
    def __init__(self):
        self.metadata = model_loader.get_metadata()
        self.classes = self.metadata.get("classes", settings.CLASSES)
        self.version = self.metadata.get("version", settings.MODEL_VERSION)
        self.input_size = (300, 300)

    def preprocess(self, image: Union[Image.Image, np.ndarray, bytes]) -> np.ndarray:
        """
        Isolated and configurable fundus preprocessing pipeline.
        Ensures consistent input tensor dimensions and normalization.
        """
        if isinstance(image, bytes):
            image = Image.open(io.BytesIO(image))
        elif isinstance(image, np.ndarray):
            image = Image.fromarray(image)

        # Convert to RGB color space
        if image.mode != "RGB":
            image = image.convert("RGB")

        # Resize to EfficientNet-B3 resolution using high-quality Lanczos interpolation
        resized = image.resize(self.input_size, Image.Resampling.LANCZOS)
        
        # Convert to float32 normalized in [0, 1]
        img_array = np.array(resized, dtype=np.float32) / 255.0

        # Expand batch dimension -> (1, 300, 300, 3)
        tensor = np.expand_dims(img_array, axis=0)
        return tensor

    def predict(
        self,
        image: Union[Image.Image, np.ndarray, bytes]
    ) -> Tuple[PredictionResult, Optional[np.ndarray]]:
        """
        Runs model inference.
        Returns:
            - PredictionResult
            - feature_map (for Grad-CAM explainability)
        """
        start_time = time.perf_counter()
        tensor = self.preprocess(image)

        # Run inference via loaded model
        probs, feature_map = model_loader.model.predict(tensor)
        inference_time_ms = round((time.perf_counter() - start_time) * 1000, 2)

        # Class index and confidence
        class_idx = int(np.argmax(probs))
        confidence = round(float(probs[class_idx]), 4)
        predicted_class = self.classes[class_idx]

        # Probability dictionary mapped to exact classes
        prob_dict = {}
        for idx, cls_name in enumerate(self.classes):
            prob_dict[cls_name] = round(float(probs[idx]), 4)

        result = PredictionResult(
            class_=predicted_class,
            class_index=class_idx,
            confidence=confidence,
            probabilities=prob_dict,
            raw_probabilities=prob_dict,
            model_version=self.version,
            inference_time_ms=inference_time_ms,
        )

        return result, feature_map

efficientnet_b3 = EfficientNetB3()
