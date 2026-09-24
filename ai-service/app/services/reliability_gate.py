from app.schemas.screening import ReliabilityResult, PredictionResult, QualityAssessment
from app.config import settings

class ReliabilityGateService:
    def __init__(self):
        self.conf_threshold = settings.RELIABILITY_HIGH_THRESHOLD
        self.low_threshold = settings.RELIABILITY_LOW_THRESHOLD
        self.quality_threshold = settings.QUALITY_PASS_THRESHOLD

    def assess_reliability(
        self,
        quality: QualityAssessment,
        prediction: PredictionResult
    ) -> ReliabilityResult:
        """
        After inference, assesses whether the result is clinically reliable.
        High confidence & good quality -> 'analyze'
        Low confidence or borderline probability between classes -> 'human_review'
        Degraded image -> 'retake'
        """
        if not quality.passed:
            return ReliabilityResult(
                status="retake",
                score=quality.overall_score,
                confidence_threshold=self.conf_threshold,
                quality_threshold=self.quality_threshold,
                reason="Citra tidak memenuhi kualifikasi mutu minimum."
            )

        composite_score = round(0.7 * prediction.confidence + 0.3 * quality.overall_score, 2)

        if prediction.confidence >= self.conf_threshold:
            status = "analyze"
            reason = "Hasil inferensi memiliki tingkat keyakinan tinggi dan mutu citra optimal."
        elif prediction.confidence >= self.low_threshold:
            status = "human_review"
            reason = "Hasil klasifikasi berada di ambang batas ketidakpastian. Diperlukan telaah dokter spesialis mata."
        else:
            status = "human_review"
            reason = "Keyakinan inferensi rendah. Verifikasi langsung oleh dokter spesialis mata diwajibkan."

        return ReliabilityResult(
            status=status,
            score=composite_score,
            confidence_threshold=self.conf_threshold,
            quality_threshold=self.quality_threshold,
            reason=reason
        )
