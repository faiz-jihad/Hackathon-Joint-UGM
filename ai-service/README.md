# RETIVA AI Service

Production-ready microservice for Reliability-First Diabetic Retinopathy (DR) Screening.

---

## 1. Overview

**RETIVA** is a clinician-assistive artificial intelligence screening system designed for primary healthcare facilities and tele-ophthalmology workflows.

### Core Principle
> **The model must be allowed to abstain when the input or prediction is unreliable.**

### Safety Mandate
* RETIVA is **NOT** an autonomous diagnostic system.
* The system **never** claims to diagnose patients or prescribe therapies.
* All screening outputs provide clinical decision-support language requiring licensed healthcare professional review.

---

## 2. Pipeline Architecture

```text
               +---------------------------+
               |    Retinal Fundus Image   |
               +---------------------------+
                             |
                             v
               +---------------------------+
               |  Image Quality Gate       |
               |  - Blur (Laplacian var)   |
               |  - Exposure/Luminance     |
               |  - FOV (Circular Mask)    |
               |  - Resolution >= 300x300  |
               +---------------------------+
                             |
                   +---------+---------+
                   |                   |
               [FAILED]             [PASSED]
                   |                   |
                   v                   v
            +-------------+     +-------------------------------+
            |   RETAKE    |     |   EfficientNet-B3 Inference   |
            | (Prediction |     |   - 5 ICDR Severity Classes   |
            |   Bypassed) |     +-------------------------------+
            +-------------+                    |
                                               v
                                +-------------------------------+
                                |       Reliability Gate        |
                                |  - Confidence Score           |
                                |  - Top-1 vs Top-2 Margin      |
                                |  - Distribution Entropy       |
                                +-------------------------------+
                                               |
                           +-------------------+-------------------+
                           |                                       |
                     [High Quality &                         [Borderline/
                      High Confidence]                       Uncertain]
                           |                                       |
                           v                                       v
                    +--------------+                       +---------------+
                    |   ANALYZE    |                       | HUMAN_REVIEW  |
                    +--------------+                       +---------------+
                           \                                      /
                            \                                    /
                             v                                  v
                        +--------------------------------------------+
                        |      Grad-CAM Explainability Heatmap       |
                        |      (Fail-safe isolated execution)        |
                        +--------------------------------------------+
                                             |
                                             v
                        +--------------------------------------------+
                        |              Screening Result              |
                        |       (With Clinical Safety Notice)        |
                        +--------------------------------------------+
```

---

## 3. Technology Stack

* **Language**: Python 3.11+
* **Framework**: FastAPI (Asynchronous ASGI)
* **Validation**: Pydantic v2
* **Computer Vision**: OpenCV (Headless), Pillow, NumPy
* **Testing**: Pytest, HTTPX, Starlette TestClient
* **Deployment**: Docker, Uvicorn

---

## 4. Setup and Installation

### Local Virtual Environment

```bash
cd ai-service

# Create virtual environment
python -m venv .venv

# Activate environment
# On Linux/macOS:
source .venv/bin/activate
# On Windows:
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Running Locally

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload
```

Interactive API documentation will be available at:
* Swagger UI: `http://localhost:8003/docs`
* ReDoc: `http://localhost:8003/redoc`

---

## 5. Environment Variables

All parameters are configurable via environment variables or a `.env` file:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `APP_ENV` | `development` | Runtime environment (`development`, `production`) |
| `HOST` | `0.0.0.0` | Network binding interface |
| `PORT` | `8003` | Network listening port |
| `MODEL_NAME` | `EfficientNet-B3` | Classification architecture name |
| `MODEL_VERSION` | `0.1.0` | Model artifact semantic version |
| `MODEL_PATH` | `models/efficientnet_b3/model.tflite` | Path to compiled model weights |
| `MODEL_METADATA_PATH` | `models/efficientnet_b3/metadata.json` | Path to metadata configuration |
| `QUALITY_THRESHOLD` | `0.80` | Minimum composite score to pass Quality Gate |
| `QUALITY_BLUR_THRESHOLD` | `0.65` | Laplacian focus sharpness threshold |
| `QUALITY_BRIGHTNESS_MIN` | `0.20` | Minimum allowable retinal mean luminance |
| `QUALITY_BRIGHTNESS_MAX` | `0.85` | Maximum allowable retinal mean luminance |
| `QUALITY_FOV_MIN` | `0.60` | Circular field-of-view frame coverage ratio |
| `MIN_IMAGE_DIMENSION` | `300` | Minimum width and height in pixels |
| `MAX_IMAGE_SIZE_MB` | `10` | Maximum upload file payload size |
| `RELIABILITY_THRESHOLD` | `0.80` | Minimum confidence required for autonomous `ANALYZE` |
| `RELIABILITY_MARGIN_THRESHOLD` | `0.15` | Minimum margin between top-1 and top-2 class |
| `RELIABILITY_MAX_ENTROPY` | `1.25` | Maximum allowable Shannon predictive entropy |
| `GRADCAM_ENABLED` | `true` | Enable/disable explainability heatmap generation |
| `INTERNAL_API_SECRET` | `""` | Optional shared token for internal service authentication |

---

## 6. API Reference & cURL Examples

### Health Check

```bash
curl -X GET http://localhost:8003/health
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "service": "retiva-ai-service",
  "model": "EfficientNet-B3",
  "version": "0.1.0",
  "pipeline_version": "retiva-pipeline-v1.2",
  "quality_gate": "active",
  "reliability_gate": "active",
  "gradcam_enabled": true
}
```

### Model Information

```bash
curl -X GET http://localhost:8003/api/v1/model/info
```

### Fundus Screening (Primary Endpoint)

```bash
curl -X POST http://localhost:8003/api/v1/screen \
  -F "image=@/path/to/fundus_sample.jpg" \
  -F "screening_id=scr_patient_001"
```

**Response (200 OK - ANALYZE):**
```json
{
  "screening_id": "scr_patient_001",
  "status": "ANALYZE",
  "quality": {
    "passed": true,
    "score": 0.88,
    "checks": {
      "blur": { "passed": true, "score": 0.91, "details": "Sharpness variance: 142.5" },
      "brightness": { "passed": true, "score": 0.85, "details": "Optimal illumination" },
      "field_of_view": { "passed": true, "score": 0.89, "details": "Aperture coverage: 65.2%" },
      "dimensions": { "passed": true, "score": 1.0, "details": "Resolution 512x512 meets requirements" }
    },
    "decision": "ANALYZE",
    "reason": null,
    "instructions": null
  },
  "prediction": {
    "class": "Moderate",
    "predicted_class": "Moderate",
    "class_index": 2,
    "confidence": 0.84,
    "probabilities": {
      "No DR": 0.02,
      "Mild": 0.07,
      "Moderate": 0.84,
      "Severe": 0.05,
      "Proliferative DR": 0.02
    },
    "model_version": "0.1.0",
    "inference_time_ms": 24.3
  },
  "reliability": {
    "status": "ANALYZE",
    "score": 0.83,
    "confidence": 0.84,
    "margin": 0.77,
    "entropy": 0.82,
    "message": "The screening result indicates that further assessment may be appropriate. This result is not a diagnosis. Please consult a healthcare professional.",
    "reason": "Prediction confidence, margin, and entropy satisfy clinical reliability thresholds."
  },
  "explainability": {
    "available": true,
    "heatmap_url": "data:image/jpeg;base64,...",
    "overlay_url": "data:image/jpeg;base64,...",
    "reason": null
  },
  "model": {
    "name": "EfficientNet-B3",
    "version": "0.1.0",
    "classes": ["No DR", "Mild", "Moderate", "Severe", "Proliferative DR"]
  },
  "safety_notice": "The screening result indicates that further assessment may be appropriate. This result is not a diagnosis. Please consult a healthcare professional.",
  "processing_time_ms": 78.4
}
```

### Pre-Screen Quality Check

```bash
curl -X POST http://localhost:8003/api/v1/quality/check \
  -F "image=@/path/to/blurry_sample.jpg"
```

### Explainability Grad-CAM

```bash
curl -X POST http://localhost:8003/api/v1/explainability/gradcam \
  -F "image=@/path/to/fundus_sample.jpg" \
  -F "class_index=2"
```

---

## 7. Replacing the Mock Prototype with a Trained Model

The service uses a clean provider-agnostic `BaseModelInterface` defined in `app/models/model_loader.py`.

To deploy trained model weights:

1. **Place the compiled model file**:
   Save your TensorFlow Lite model to:
   ```text
   ai-service/models/efficientnet_b3/model.tflite
   ```
   Or specify a custom path in `.env`:
   ```bash
   MODEL_PATH=/opt/models/retiva_efficientnet_b3_quantized.tflite
   ```

2. **Update Metadata**:
   Modify `models/efficientnet_b3/metadata.json` with the model's exact version, classes, and evaluation metrics:
   ```json
   {
     "model_name": "EfficientNet-B3",
     "version": "1.0.0",
     "input_resolution": [300, 300, 3],
     "normalization": {
       "mean": [0.485, 0.456, 0.406],
       "std": [0.229, 0.224, 0.225]
     },
     "classes": [
       "No DR",
       "Mild",
       "Moderate",
       "Severe",
       "Proliferative DR"
     ]
   }
   ```

3. **Automatic Detection**:
   When the service starts, `ModelLoader` checks for the presence of `model.tflite`. If found, `TFLiteModel` is automatically loaded and takes over inference. If the file is absent, `MockEfficientNetB3` operates deterministically as a fallback prototype.

---

## 8. Running Automated Tests

Run the test suite via pytest:

```bash
pytest tests/ -v
```

### Test Coverage Highlights:
* `tests/test_quality.py`: Evaluates Laplacian blur variance, central-cropped illumination, circular FOV masking, minimum resolution, and corrupt files.
* `tests/test_reliability.py`: Tests threshold gates, low confidence diversion to `HUMAN_REVIEW`, close decision margins, and entropy checks.
* `tests/test_screening.py`: End-to-end integration tests for all REST endpoints, confirming classification bypass upon quality failure.
* `tests/test_safety.py`: Asserts complete absence of diagnosis claims (`diagnosis: true`), validates mandatory safety disclaimer, and verifies strict clinical language standards.

---

## 9. Containerization & Production Deployment

### Build Docker Image

```bash
docker build -t retiva-ai-service:latest .
```

### Run Container

```bash
docker run -d \
  --name retiva-ai \
  -p 8003:8003 \
  -e QUALITY_THRESHOLD=0.80 \
  -e RELIABILITY_THRESHOLD=0.80 \
  retiva-ai-service:latest
```

### Verify Container Health

```bash
curl http://localhost:8003/health
```
