import math
import numpy as np
from typing import Dict, Optional, Tuple
from app.core.config import settings
from app.schemas.quality import QualityCheckResult
from app.schemas.screening import PredictionResult
from app.schemas.reliability import ReliabilityResult

class ReliabilityGateService:
    """
    Reliability Gate Service (Section 7).
    Determines whether a screening outcome can be classified automatically (ANALYZE),
    demands human clinical review (HUMAN_REVIEW), or requires re-capturing the image (RETAKE).

    Evaluation metrics:
      1. Primary Confidence: Top-1 softmax probability.
      2. Decision Margin: Difference between top-1 and top-2 class probabilities.
      3. Shannon Entropy: Measure of predictive dispersion across the 5 ICDR classes.
      4. Image Quality Score: Propagated from Image Quality Gate.
    """
    def __init__(self):
        self.confidence_threshold = settings.RELIABILITY_THRESHOLD
        self.margin_threshold = settings.RELIABILITY_MARGIN_THRESHOLD
        self.max_entropy = settings.RELIABILITY_MAX_ENTROPY

    def calculate_entropy(self, probabilities: Dict[str, float]) -> float:
        """
        Calculates Shannon entropy (base 2) for the discrete class probability distribution.
        For 5 classes, max entropy is log2(5) ~= 2.3219.
        """
        vals = [p for p in probabilities.values() if p > 1e-7]
        if not vals:
            return 0.0
        entropy = -sum(p * math.log2(p) for p in vals)
        return round(float(entropy), 4)

    def calculate_margin(self, probabilities: Dict[str, float]) -> float:
        """
        Calculates difference between top-1 and top-2 class probability.
        A low margin signals class ambiguity (e.g. Mild vs Moderate).
        """
        sorted_probs = sorted(probabilities.values(), reverse=True)
        if len(sorted_probs) < 2:
            return 1.0
        margin = sorted_probs[0] - sorted_probs[1]
        return round(float(margin), 4)

    def evaluate_reliability(
        self,
        quality: QualityCheckResult,
        prediction: Optional[PredictionResult] = None
    ) -> ReliabilityResult:
        thresholds = {
            "reliability_threshold": self.confidence_threshold,
            "margin_threshold": self.margin_threshold,
            "max_entropy": self.max_entropy,
            "quality_threshold": settings.QUALITY_THRESHOLD,
        }

        # 1. Quality Gate Check Failure -> Immediate RETAKE
        if not quality.passed or prediction is None:
            return ReliabilityResult(
                status="RETAKE",
                score=round(quality.score * 0.5, 4),
                confidence=None,
                margin=None,
                entropy=None,
                thresholds=thresholds,
                message="Image quality is insufficient for clinical evaluation. Please retake the fundus photograph.",
                reason=quality.reason or "Failed quality gate checks.",
                confidence_threshold=self.confidence_threshold,
                quality_threshold=settings.QUALITY_THRESHOLD,
            )

        # 2. Extract metrics from prediction
        confidence = prediction.confidence
        margin = self.calculate_margin(prediction.probabilities)
        entropy = self.calculate_entropy(prediction.probabilities)

        # Composite score combining confidence, margin, low entropy, and image quality
        # Max entropy for 5 classes is ~2.32
        norm_entropy = max(0.0, 1.0 - (entropy / 2.3219))
        composite_score = round(
            0.40 * confidence + 0.25 * margin + 0.15 * norm_entropy + 0.20 * quality.score,
            4
        )
        composite_score = max(0.0, min(1.0, composite_score))

        # 3. Assess criteria for ANALYZE vs HUMAN_REVIEW
        reasons = []
        is_confident = confidence >= self.confidence_threshold
        is_decisive = margin >= self.margin_threshold
        is_low_entropy = entropy <= self.max_entropy

        if not is_confident:
            reasons.append(f"Confidence {confidence:.2f} is below threshold {self.confidence_threshold:.2f}.")
        if not is_decisive:
            reasons.append(f"Decision margin {margin:.2f} between top-2 classes is below threshold {self.margin_threshold:.2f}.")
        if not is_low_entropy:
            reasons.append(f"Prediction entropy {entropy:.2f} exceeds ambiguity threshold {self.max_entropy:.2f}.")

        if is_confident and is_decisive and is_low_entropy:
            status = "ANALYZE"
            message = (
                "The screening result indicates that further assessment may be appropriate. "
                "This result is not a diagnosis. Please consult a healthcare professional."
            )
            reason = "Prediction confidence, margin, and entropy satisfy clinical reliability thresholds."
        else:
            status = "HUMAN_REVIEW"
            # Section 7 exact clinical guidance message
            message = "The image can be processed, but the AI result requires review by a healthcare professional."
            reason = " ".join(reasons)

        return ReliabilityResult(
            status=status,
            score=composite_score,
            confidence=confidence,
            margin=margin,
            entropy=entropy,
            thresholds=thresholds,
            message=message,
            reason=reason,
            confidence_threshold=self.confidence_threshold,
            quality_threshold=settings.QUALITY_THRESHOLD,
        )

reliability_service = ReliabilityGateService()
