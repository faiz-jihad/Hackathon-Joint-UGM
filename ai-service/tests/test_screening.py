import io
import pytest
import numpy as np
from PIL import Image
from fastapi.testclient import TestClient

def test_health_check_endpoint(client: TestClient):
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert data["service"] == "retiva-ai-service"
    assert "model" in data

def test_model_info_endpoint(client: TestClient):
    resp = client.get("/api/v1/model/info")
    assert resp.status_code == 200
    data = resp.json()
    assert data["model_name"] == "EfficientNet-B3"
    assert len(data["classes"]) == 5
    assert "No DR" in data["classes"]
    assert "Proliferative DR" in data["classes"]

def test_screen_good_fundus_image(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    data = resp.json()

    assert data["status"] in ("ANALYZE", "HUMAN_REVIEW")
    assert data["quality"]["passed"] is True
    assert data["prediction"] is not None
    assert data["prediction"]["predicted_class"] in [
        "No DR", "Mild", "Moderate", "Severe", "Proliferative DR"
    ]
    assert data["prediction"]["confidence"] > 0.0
    assert len(data["prediction"]["probabilities"]) == 5
    assert data["explainability"] is not None
    assert data["explainability"]["available"] is True
    assert "safety_notice" in data

def test_screen_blurry_image_stops_at_quality_gate(client: TestClient, blurry_fundus_image):
    files = {"image": ("blurry.jpg", io.BytesIO(blurry_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    data = resp.json()

    # Core requirement: If quality fails, status must be RETAKE and prediction must be None
    assert data["status"] == "RETAKE"
    assert data["quality"]["passed"] is False
    assert data["prediction"] is None
    assert data["explainability"] is None
    assert data["reliability"]["status"] == "RETAKE"

def test_screen_invalid_file_type_returns_structured_error(client: TestClient):
    files = {"image": ("document.pdf", io.BytesIO(b"%PDF-1.4 test"), "application/pdf")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 400
    data = resp.json()
    assert "error" in data
    assert data["error"]["code"] == "INVALID_IMAGE"

def test_quality_check_endpoint(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/quality/check", files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["passed"] is True
    assert data["decision"] == "ANALYZE"
    assert "checks" in data

def test_screen_non_fundus_image(client: TestClient):
    # Valid JPEG image of a plain white canvas (non-fundus scene)
    white_img = np.full((500, 500, 3), 250, dtype=np.uint8)
    buf = io.BytesIO()
    Image.fromarray(white_img).save(buf, format="JPEG")
    files = {"image": ("non_fundus.jpg", io.BytesIO(buf.getvalue()), "image/jpeg")}
    
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "RETAKE"
    assert data["quality"]["passed"] is False
    assert data["prediction"] is None
    assert data["explainability"] is None

def test_gradcam_endpoint(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/explainability/gradcam", files=files)
    assert resp.status_code == 200
    data = resp.json()
    assert data["available"] is True
    assert data["heatmap_url"].startswith("data:image/")
    assert data["overlay_url"].startswith("data:image/")

