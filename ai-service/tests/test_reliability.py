import pytest
from app.services.reliability_service import reliability_service
from app.schemas.quality import QualityCheckResult, QualityChecks, QualitySubCheck
from app.schemas.screening import PredictionResult

def make_mock_quality(passed: bool, score: float = 0.85) -> QualityCheckResult:
    return QualityCheckResult(
        passed=passed,
        score=score,
        checks=QualityChecks(
            blur=QualitySubCheck(passed=passed, score=score),
            brightness=QualitySubCheck(passed=passed, score=score),
            field_of_view=QualitySubCheck(passed=passed, score=score),
            dimensions=QualitySubCheck(passed=passed, score=1.0),
        ),
        decision="ANALYZE" if passed else "RETAKE"
    )

def test_high_confidence_triggers_analyze():
    quality = make_mock_quality(passed=True, score=0.90)
    prediction = PredictionResult(
        class_="Moderate",
        class_index=2,
        confidence=0.88,
        probabilities={
            "No DR": 0.01,
            "Mild": 0.04,
            "Moderate": 0.88,
            "Severe": 0.05,
            "Proliferative DR": 0.02
        },
        model_version="0.1.0",
        inference_time_ms=25.0
    )
    result = reliability_service.evaluate_reliability(quality, prediction)
    assert result.status == "ANALYZE"
    assert result.score >= 0.75
    assert result.confidence == 0.88
    assert result.margin >= 0.70

def test_low_confidence_triggers_human_review():
    quality = make_mock_quality(passed=True, score=0.85)
    prediction = PredictionResult(
        class_="Mild",
        class_index=1,
        confidence=0.45,
        probabilities={
            "No DR": 0.20,
            "Mild": 0.45,
            "Moderate": 0.20,
            "Severe": 0.10,
            "Proliferative DR": 0.05
        },
        model_version="0.1.0",
        inference_time_ms=22.0
    )
    result = reliability_service.evaluate_reliability(quality, prediction)
    assert result.status == "HUMAN_REVIEW"
    assert "review by a healthcare professional" in result.message.lower()

def test_borderline_margin_triggers_human_review():
    quality = make_mock_quality(passed=True, score=0.85)
    # Even if confidence is relatively high (e.g. 0.82), if margin is small
    prediction = PredictionResult(
        class_="Moderate",
        class_index=2,
        confidence=0.81,
        probabilities={
            "No DR": 0.01,
            "Mild": 0.02,
            "Moderate": 0.81,
            "Severe": 0.75,  # synthetic close margin
            "Proliferative DR": 0.01
        },
        model_version="0.1.0",
        inference_time_ms=20.0
    )
    # Normalize probabilities
    total = sum(prediction.probabilities.values())
    prediction.probabilities = {k: v / total for k, v in prediction.probabilities.items()}
    prediction.confidence = max(prediction.probabilities.values())

    result = reliability_service.evaluate_reliability(quality, prediction)
    # The margin will be (0.81 - 0.75) / total = ~0.038 < 0.15 threshold -> triggers HUMAN_REVIEW
    assert result.status == "HUMAN_REVIEW"
    assert result.margin < 0.15

def test_failed_quality_triggers_retake():
    quality = make_mock_quality(passed=False, score=0.30)
    result = reliability_service.evaluate_reliability(quality, prediction=None)
    assert result.status == "RETAKE"
    assert "retake" in result.message.lower()
