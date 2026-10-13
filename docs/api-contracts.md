# RETIVA Canonical API Contracts Specification

**Version**: 1.0.0  
**Base URL**: `http://localhost:3000/api/v1` (Backend) | `http://localhost:8000/api/v1` (AI Service)  
**Spec Standard**: RESTful / JSON / RFC 7807 Compliant  
**Auditor**: Senior Software Architect & Full-Stack Engineer  
**Date**: October 2026  

---

## 1. Global Conventions & Standards

### 1.1 Response Envelopes

All RETIVA API responses strictly follow a uniform envelope structure:

#### Success Response (`2xx`)
```json
{
  "success": true,
  "statusCode": 200,
  "data": { ... },
  "meta": {
    "total": 120,
    "limit": 20,
    "offset": 0
  }
}
```

#### Error Response (`4xx` / `5xx`)
```json
{
  "success": false,
  "statusCode": 400,
  "error": {
    "code": "VALIDATION_ERROR | UNAUTHORIZED | FORBIDDEN | NOT_FOUND | CONFLICT | INTERNAL_ERROR",
    "message": "Human readable clinical explanation.",
    "details": {
      "nik": ["NIK must be exactly 16 digits"]
    }
  }
}
```

### 1.2 Authentication Headers
- **Client to Backend**: `Authorization: Bearer <jwt-token>`
- **Clinical Web Internal**: `x-retiva-clinical: true` (Internal browser session validation)
- **Backend to FastAPI AI Service**: `X-Internal-Secret: <AI_INTERNAL_SECRET>` (Default: `retiva-internal-secret-token`)

---

## 2. Authentication & User Management Endpoints

### 2.1 Login
- **Route**: `POST /api/v1/auth/login`
- **Auth**: Public
- **Rate Limit**: Max 5 requests / minute per IP.
- **Request Body**:
  ```json
  {
    "email": "dr.spm@retina.hospital.id",
    "password": "Password123!"
  }
  ```
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "statusCode": 200,
    "data": {
      "user": {
        "id": "c0a80123-7b4c-4e89-b221-123456789abc",
        "email": "dr.spm@retina.hospital.id",
        "fullName": "dr. Hendra Sp.M(K)",
        "role": "OPHTHALMOLOGIST",
        "createdAt": "2026-10-10T08:00:00.000Z"
      },
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
  ```

### 2.2 Current User Profile
- **Route**: `GET /api/v1/auth/me`
- **Auth**: Bearer Token (Any authenticated user)
- **Response** (`200 OK`): Returns User entity without password hash.

---

## 3. Patient & Diabetes Profile Endpoints

### 3.1 Patient Search & Pagination
- **Route**: `GET /api/v1/patients?query=Sutrisno&limit=20&offset=0`
- **Auth**: Bearer Token (`role: HEALTHCARE_WORKER | OPHTHALMOLOGIST | ADMIN`)
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "statusCode": 200,
    "data": [
      {
        "id": "e2a1b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
        "nik": "3201015504850001",
        "fullName": "Bapak Sutrisno",
        "birthDate": "1970-08-20T00:00:00.000Z",
        "gender": "MALE",
        "phone": "081234567890",
        "address": "Kabupaten Sleman, D.I. Yogyakarta",
        "emergencyContact": "081987654321",
        "createdAt": "2026-10-11T09:30:00.000Z"
      }
    ],
    "meta": { "total": 1, "limit": 20, "offset": 0 }
  }
  ```

### 3.2 Patient Registration (Atomic with Diabetes Profile)
- **Route**: `POST /api/v1/patients`
- **Auth**: Bearer Token (`role: HEALTHCARE_WORKER | OPHTHALMOLOGIST | ADMIN`)
- **Request Body**:
  ```json
  {
    "nik": "3201015504850002",
    "fullName": "Ibu Siti Rahayu",
    "birthDate": "1975-03-12",
    "gender": "FEMALE",
    "phone": "081398765432",
    "address": "Kota Yogyakarta",
    "emergencyContact": "081234567899",
    "diabetesProfile": {
      "diabetesType": "TYPE_2",
      "yearOfDiagnosis": 2017,
      "currentTreatment": "ORAL_MEDICATION",
      "lastHbA1c": 8.4,
      "systolicBp": 135,
      "diastolicBp": 85,
      "isSmoker": false,
      "notes": "Kontrol rutin di Puskesmas Jetis"
    }
  }
  ```
- **Response** (`201 Created`): Returns created Patient object.

### 3.3 Get / Upsert Diabetes Profile
- **Route**: `GET /api/v1/patients/[id]/diabetes-profile`
- **Route**: `PUT /api/v1/patients/[id]/diabetes-profile`
- **Auth**: Bearer Token (`role: HEALTHCARE_WORKER | OPHTHALMOLOGIST | ADMIN`)

---

## 4. Screening & AI Inference Endpoints

### 4.1 Direct Mobile & Edge AI Screening (Synchronized Coordinator)
- **Route**: `POST /api/v1/screenings/direct-screen`
- **Content-Type**: `multipart/form-data`
- **Auth**: Bearer Token or `x-retiva-clinical` header
- **Form Fields**:
  - `image`: Binary fundus image (JPEG / PNG, max 15MB)
  - `eye_position`: `"OD"` (Right Eye) | `"OS"` (Left Eye)
  - `patient_id`: UUID of patient
  - `notes`: Optional clinical notes
- **Transactional Side Effects**:
  1. Computes SHA-256 hash.
  2. Stores binary in MinIO/S3 private bucket.
  3. Executes FastAPI AI inference (`POST /api/v1/screen`).
  4. Evaluates Quality Gate (Laplacian focus) & Reliability Gate (Confidence threshold).
  5. Evaluates Perdami 2024 / ADA 2024 Recommendation Rules Engine.
  6. Atomically inserts `Screening`, `RetinalImage`, `QualityCheck`, `AIResult`, `ReliabilityAssessment`, `Recommendation`, and `AuditLog` in PostgreSQL.
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "statusCode": 200,
    "data": {
      "screening_id": "7f8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d",
      "quality": {
        "passed": true,
        "score": 0.88,
        "is_blurry": false,
        "sharpness_score": 142.5,
        "issues": []
      },
      "classification": {
        "dr_class": "MODERATE_DR",
        "confidence": 0.89,
        "probabilities": {
          "NO_DR": 0.02,
          "MILD_DR": 0.05,
          "MODERATE_DR": 0.89,
          "SEVERE_DR": 0.03,
          "PROLIFERATIVE_DR": 0.01
        }
      },
      "reliability": {
        "status": "ANALYZE",
        "score": 0.89,
        "reason": "Evaluasi reliabilitas klinis lengkap."
      },
      "recommendation": {
        "summary": "Ditemukan retinopati diabetik non-proliferatif derajat sedang (mikroaneurisma multipel, perdarahan dot-blot ringan). Disarankan rujukan berkala ke Sp.M.",
        "recommended_action": "REFERRAL_ROUTINE",
        "urgency_level": "MEDIUM",
        "referral_indicated": true,
        "clinical_guideline": "PERDAMI 2024 / ADA 2024"
      }
    }
  }
  ```

### 4.2 Standard Multi-Stage Screening Lifecycle
- `POST /api/v1/screenings`: Initialize screening session (Status: `CREATED`).
- `POST /api/v1/screenings/[id]/images`: Upload bilateral fundus images (OD/OS) with SHA-256 checksum (Status: `IMAGE_UPLOADED`).
- `POST /api/v1/screenings/[id]/quality-check`: Execute Quality Gate. If blurry -> `RETAKE_REQUIRED`.
- `POST /api/v1/screenings/[id]/analyze`: Execute AI Classification and Reliability Gate. If confidence < 0.85 -> `HUMAN_REVIEW`, else `AI_ANALYZED`.
- `GET /api/v1/screenings/[id]`: Retrieve full screening dossier including images, quality, AI results, and recommendation.

---

## 5. Specialist Adjudication & Clinical Review

### 5.1 Pending Reviews Queue
- **Route**: `GET /api/v1/reviews/pending?limit=20&offset=0`
- **Auth**: Bearer Token (`role: OPHTHALMOLOGIST | ADMIN`)
- **Response** (`200 OK`): List of screenings awaiting human confirmation.

### 5.2 Adjudicate / Confirm Screening
- **Route**: `POST /api/v1/reviews/[screeningId]/adjudicate`
- **Auth**: Bearer Token (`role: OPHTHALMOLOGIST | ADMIN`)
- **Request Body**:
  ```json
  {
    "confirmedClass": "MODERATE_DR",
    "notes": "Konfirmasi NPDR derajat sedang. Tampak mikroaneurisma di kuadran temporal.",
    "overrideAi": false
  }
  ```
- **Response** (`200 OK`): Advances screening status to `COMPLETED` and records Non-Repudiation Audit Log.

---

## 6. Facilities & Geodesic Matching

### 6.1 Geodesic Nearest Facilities (Mobile & Web)
- **Route**: `GET /api/v1/facilities/nearest?lat=-7.7828&lng=110.3712&maxDistanceKm=50&requireBpjs=true`
- **Auth**: Any authenticated user
- **Computation**: Haversine distance formula ($R=6371\text{ km}$).
- **Response** (`200 OK`):
  ```json
  {
    "success": true,
    "statusCode": 200,
    "data": [
      {
        "id": "fac-01",
        "name": "RS Mata Dr. Yap Yogyakarta",
        "type": "HOSPITAL_A",
        "address": "Jl. Cik Di Tiro No.5, Terban, Gondokusuman, Yogyakarta",
        "latitude": -7.7828,
        "longitude": 110.3712,
        "contactPhone": "0274-562054",
        "hasRetinaSubspecialist": true,
        "bpjsCovered": true,
        "distanceKm": 1.3
      }
    ]
  }
  ```

---

## 7. Referrals & Follow-Ups

### 7.1 Create Clinical Referral
- **Route**: `POST /api/v1/referrals`
- **Auth**: Bearer Token (`role: HEALTHCARE_WORKER | OPHTHALMOLOGIST | ADMIN`)
- **Request Body**:
  ```json
  {
    "screeningId": "7f8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d",
    "facilityId": "fac-01",
    "urgencyLevel": "MEDIUM",
    "clinicalNotes": "Rujukan terencana untuk pemeriksaan slit-lamp biomicroscopy & funduskopi lanjutan."
  }
  ```
- **Response** (`201 Created`): Creates Referral with 30-day legal validity window.

### 7.2 Patient Screening History (Singular & Plural)
- **Route**: `GET /api/v1/history/patient/[patientId]` (Mobile Client Canonical)
- **Route**: `GET /api/v1/history/patients/[patientId]` (Plural Alias)
- **Auth**: Bearer Token
- **Response** (`200 OK`): Chronological list of patient screening events.

---

## 8. FastAPI AI Service Endpoints (`:8000`)

### 8.1 Multi-Stage Quality & Screening Inference
- **Route**: `POST /api/v1/screen`
- **Headers**: `X-Internal-Secret: retiva-internal-secret-token`
- **Content-Type**: `multipart/form-data`
- **Form Fields**: `image` (binary file), `screening_id` (optional string)
- **Response** (`200 OK`):
  ```json
  {
    "screening_id": "7f8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d",
    "quality": {
      "passed": true,
      "score": 0.88,
      "is_blurry": false,
      "sharpness_score": 142.5,
      "issues": []
    },
    "classification": {
      "dr_class": "Moderate",
      "confidence": 0.89,
      "probabilities": {
        "No DR": 0.02,
        "Mild": 0.05,
        "Moderate": 0.89,
        "Severe": 0.03,
        "Proliferative DR": 0.01
      }
    },
    "reliability": {
      "status": "ANALYZE",
      "score": 0.89,
      "reason": "Evaluasi reliabilitas klinis lengkap."
    }
  }
  ```

### 8.2 Health & Model Registry
- `GET /api/v1/health`: Returns service uptime, PyTorch device (CPU/CUDA), and loaded model weights.
- `GET /api/v1/models/active`: Returns metadata of the currently active model (e.g. `efficientnet-b3-v1.0.0`).
