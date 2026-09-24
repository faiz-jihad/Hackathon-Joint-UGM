import pytest
from app.services.quality_service import quality_service

def test_good_fundus_image_passes(good_fundus_image):
    result = quality_service.evaluate_quality(good_fundus_image)
    assert result.passed is True
    assert result.decision == "ANALYZE"
    assert result.score >= 0.70
    assert result.checks.blur.passed is True
    assert result.checks.brightness.passed is True
    assert result.checks.field_of_view.passed is True
    assert result.checks.dimensions.passed is True

def test_blurry_image_triggers_retake(blurry_fundus_image):
    result = quality_service.evaluate_quality(blurry_fundus_image)
    assert result.passed is False
    assert result.decision == "RETAKE"
    assert result.checks.blur.passed is False
    assert "blur" in result.reason.lower() or "fokus" in result.reason.lower()

def test_dark_image_triggers_retake(dark_fundus_image):
    result = quality_service.evaluate_quality(dark_fundus_image)
    assert result.passed is False
    assert result.decision == "RETAKE"
    assert result.checks.brightness.passed is False

def test_small_image_triggers_retake(small_image):
    result = quality_service.evaluate_quality(small_image)
    assert result.passed is False
    assert result.decision == "RETAKE"
    assert result.checks.dimensions.passed is False
    assert "resolusi" in result.reason.lower() or "resolution" in result.reason.lower()

def test_corrupt_image_triggers_retake(non_image_bytes):
    result = quality_service.evaluate_quality(non_image_bytes)
    assert result.passed is False
    assert result.decision == "RETAKE"
    assert "corrupted" in result.reason.lower() or "not a valid" in result.reason.lower()
