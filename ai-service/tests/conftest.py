import io
import pytest
import numpy as np
import cv2
from PIL import Image
from fastapi.testclient import TestClient
from app.main import app

def make_fundus_image(size=(512, 512), blur=False, dark=False) -> bytes:
    """Generates synthetic fundus photography array."""
    h, w = size
    canvas = np.zeros((h, w, 3), dtype=np.uint8)
    center = (w // 2, h // 2)
    radius = int(min(h, w) * 0.45)

    if dark:
        # Heavily underexposed (luminance < 0.10)
        cv2.circle(canvas, center, radius, (5, 10, 20), -1)
    else:
        # Standard retinal fundus (orange-reddish body)
        cv2.circle(canvas, center, radius, (20, 80, 210), -1)
        # Optic disc
        disc_x = int(center[0] - radius * 0.4)
        cv2.circle(canvas, (disc_x, center[1]), int(radius * 0.2), (80, 200, 240), -1)
        # Macula
        macula_x = int(center[0] + radius * 0.3)
        cv2.circle(canvas, (macula_x, center[1]), int(radius * 0.15), (10, 45, 130), -1)
        # High frequency vessels (creates sharp edges for Laplacian variance)
        for i in range(-3, 4):
            cv2.line(canvas, (disc_x, center[1]), (w - 20, center[1] + i * 40), (10, 30, 110), 3)
            cv2.line(canvas, (disc_x, center[1]), (20, center[1] + i * 40), (10, 30, 110), 2)

    if blur:
        # Heavy Gaussian blur to simulate severe out-of-focus capture
        canvas = cv2.GaussianBlur(canvas, (45, 45), 25)

    pil_img = Image.fromarray(cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB))
    buf = io.BytesIO()
    pil_img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def good_fundus_image():
    return make_fundus_image(size=(512, 512), blur=False, dark=False)

@pytest.fixture
def blurry_fundus_image():
    return make_fundus_image(size=(512, 512), blur=True, dark=False)

@pytest.fixture
def dark_fundus_image():
    return make_fundus_image(size=(512, 512), blur=False, dark=True)

@pytest.fixture
def small_image():
    return make_fundus_image(size=(120, 120), blur=False, dark=False)

@pytest.fixture
def non_image_bytes():
    return b"This is not a fundus image, just plain text bytes."
