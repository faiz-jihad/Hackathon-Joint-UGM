import io
import json
import pytest
from fastapi.testclient import TestClient

def test_safety_disclaimer_mandatory_and_accurate(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    data = resp.json()

    assert "safety_notice" in data
    expected_notice = (
        "The screening result indicates that further assessment may be appropriate. "
        "This result is not a diagnosis. Please consult a healthcare professional."
    )
    assert data["safety_notice"] == expected_notice

def test_response_never_contains_diagnosis_claim(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    data = resp.json()

    # Rule: diagnosis: true is strictly forbidden
    assert "diagnosis" not in data or data.get("diagnosis") is not True

    # Check full payload text for prohibited clinical claims
    payload_str = json.dumps(data).lower()
    prohibited_terms = [
        "diagnosis: true",
        "you are diagnosed",
        "we diagnose",
        "prescribe",
        "prescription",
        "take insulin",
        "take medication"
    ]
    for term in prohibited_terms:
        assert term not in payload_str, f"Prohibited clinical claim found: {term}"

def test_response_contains_no_emojis(client: TestClient, good_fundus_image):
    files = {"image": ("fundus.jpg", io.BytesIO(good_fundus_image), "image/jpeg")}
    resp = client.post("/api/v1/screen", files=files)
    assert resp.status_code == 200
    content = resp.text

    # Verify no unicode emojis in response
    for char in content:
        # Common emoji codepoint ranges
        cp = ord(char)
        is_emoji = (
            0x1F600 <= cp <= 0x1F64F or  # Emoticons
            0x1F300 <= cp <= 0x1F5FF or  # Misc symbols and pictographs
            0x1F680 <= cp <= 0x1F6FF or  # Transport and map
            0x1F900 <= cp <= 0x1F9FF or  # Supplemental symbols
            0x2600 <= cp <= 0x26FF       # Misc symbols
        )
        assert not is_emoji, f"Emoji character detected: {char} (U+{cp:X})"
