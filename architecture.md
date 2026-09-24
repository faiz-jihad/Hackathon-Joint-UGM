# RETIVA --- Architecture Specification

## 1. Purpose

RETIVA is a reliability-first, AI-assisted diabetic retinopathy (DR)
screening platform. The architecture is designed for a healthcare
product that can start as a hackathon MVP and evolve toward real-world
healthcare deployment without becoming tightly coupled to a cloud,
database, storage vendor, or AI model provider.

RETIVA is a screening-support system, not an autonomous diagnostic
system. Clinical decisions remain with authorized healthcare
professionals.

## 2. Architectural Principles

1.  **Reliability-first** --- image quality and model reliability are
    first-class parts of the screening workflow.
2.  **Human-in-the-loop** --- uncertain cases can be routed to human
    review.
3.  **Provider-agnostic** --- infrastructure providers can be replaced
    without rewriting domain logic.
4.  **API-first** --- mobile, web dashboard, and future integrations
    communicate through versioned APIs.
5.  **Modular monolith + AI microservice** --- avoid premature
    microservices while keeping AI independently deployable.
6.  **Security by design** --- least privilege, auditability, secure
    image access, data minimization, and secrets management.
7.  **Traceability** --- screening results retain model and pipeline
    versions.
8.  **Interoperability-ready** --- future healthcare integrations are
    isolated behind adapters.
9.  **No autonomous clinical decision-making** --- AI does not prescribe
    treatment or independently determine referral destinations.
10. **Portable infrastructure** --- PostgreSQL, object storage, and AI
    services are accessed through application interfaces rather than
    provider-specific calls.

## 3. High-Level Architecture

``` text
                         RETIVA
                            |
          +-----------------+-----------------+
          |                                   |
       Flutter                            Next.js
    Patient App                         Web / API
                                              |
                                      +-------+-------+
                                      |               |
                                  Domain Layer   Application Layer
                                      |               |
                                      +-------+-------+
                                              |
                                  Infrastructure Adapters
                         +------------+--------+----------+
                         |            |                   |
                     PostgreSQL   Object Storage       AI Client
                         |            |                   |
                      Prisma      S3-compatible          FastAPI
                                                   EfficientNet-B3
```

### Runtime flow

``` text
Patient / Healthcare Worker
            |
         Flutter/Web
            |
        RETIVA API
            |
       Screening Service
            |
     +------+------+
     |             |
 Quality Gate    AI Client
     |             |
     |          FastAPI
     |             |
     |       EfficientNet-B3
     |             |
     +------+------+
            |
     Reliability Gate
       /     |      \
 RETAKE  HUMAN REVIEW  ANALYZE
                    |
             Result + Explainability
                    |
          Recommendation Engine
                    |
           Referral / Follow-up
```

## 4. Core Components

### 4.1 Flutter Mobile App

Responsibilities: - Patient authentication and profile. - Diabetes
profile. - Screening initiation. - Fundus image upload/capture
workflow. - Patient-friendly result presentation. - Screening history. -
Follow-up status. - Referral/facility information. - Notifications.

Flutter must not contain authoritative clinical rules. It consumes API
responses from the backend.

### 4.2 Next.js Application and API

Responsibilities: - Authentication and authorization. - Patient and
healthcare-worker workflows. - Domain/application services. - REST
API. - Healthcare dashboard. - Screening orchestration. - Recommendation
and referral workflow. - Follow-up management. - Audit events. -
Integration adapters.

Next.js is the product/application core. It does not directly execute
the Python AI model.

### 4.3 PostgreSQL + Prisma

PostgreSQL stores structured transactional data: - users - patients -
diabetes profiles - screenings - quality checks - AI results - human
reviews - recommendations - facilities - referrals - follow-ups - model
versions - audit logs

Retinal image binaries are not stored as PostgreSQL BLOBs. Store images
in object storage and retain secure object keys/metadata in PostgreSQL.

### 4.4 Object Storage

Use an S3-compatible abstraction.

Required operations: - upload - get signed URL - delete - exists

The domain layer should call an `ImageStorage` interface rather than a
provider SDK directly.

### 4.5 FastAPI AI Service

Responsibilities: - Image quality inference. - DR classification. -
Reliability signals. - Calibration/reliability processing. - Grad-CAM
generation. - Model version reporting.

Initial model: - EfficientNet-B3 - 5 classes: No DR, Mild, Moderate,
Severe, Proliferative DR.

FastAPI should be independently deployable and replaceable.

## 5. Domain Modules

``` text
Patient
DiabetesProfile
Screening
RetinalImage
QualityCheck
AIResult
ReliabilityAssessment
HumanReview
Recommendation
Facility
Referral
FollowUp
Notification
ModelVersion
AuditLog
```

## 6. Repository Structure

``` text
retiva/
├── mobile/
│   └── Flutter application
│
├── web/
│   ├── app/
│   │   └── api/
│   │       └── v1/
│   ├── domain/
│   │   ├── patient/
│   │   ├── screening/
│   │   ├── referral/
│   │   ├── follow-up/
│   │   └── recommendation/
│   ├── application/
│   ├── infrastructure/
│   │   ├── database/
│   │   ├── storage/
│   │   ├── ai/
│   │   ├── notification/
│   │   └── healthcare/
│   └── prisma/
│       └── schema.prisma
│
├── ai-service/
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── services/
│   │   └── schemas/
│   ├── models/
│   └── tests/
│
├── docs/
├── docker-compose.yml
└── README.md
```

## 7. API Design

Base path:

``` text
/api/v1
```

Core resources:

``` text
POST   /patients
GET    /patients/:id
PATCH  /patients/:id

POST   /patients/:id/diabetes-profile
GET    /patients/:id/screenings

POST   /screenings
GET    /screenings/:id
POST   /screenings/:id/image
POST   /screenings/:id/start

GET    /screenings/:id/result
POST   /screenings/:id/review

GET    /recommendations/:id
GET    /facilities
GET    /facilities/:id

POST   /referrals
GET    /referrals/:id

GET    /follow-ups
POST   /follow-ups
PATCH  /follow-ups/:id
```

The API contract should describe RETIVA concepts rather than
provider-specific infrastructure.

## 8. Screening State Machine

``` text
CREATED
   |
IMAGE_UPLOADED
   |
QUALITY_CHECK
   |-------------------- FAIL -----------------> RETAKE_REQUIRED
   |
  PASS
   |
AI_ANALYZED
   |---------------- LOW RELIABILITY ---------> HUMAN_REVIEW
   |
RELIABLE
   |
SCREENING_COMPLETED
   |
FOLLOW_UP_REQUIRED
   |
REFERRAL_RECOMMENDED
   |
FOLLOW_UP_COMPLETED
```

Not every screening must reach referral. The workflow depends on
screening output and authorized healthcare review.

## 9. AI Contract

Example:

``` json
{
  "screening_id": "scr_123",
  "model_version": "efficientnet-b3-v1",
  "quality": {
    "passed": true,
    "score": 0.94
  },
  "prediction": {
    "class": "moderate_dr",
    "probability": 0.87
  },
  "reliability": {
    "status": "human_review",
    "score": 0.61
  },
  "explanation": {
    "type": "gradcam",
    "available": true
  }
}
```

The backend, not the client, decides which workflow state is
authoritative.

## 10. Provider-Agnostic Design

### Database

``` text
Domain Service
      |
Repository Interface
      |
Prisma Adapter
      |
PostgreSQL
```

### Storage

``` text
Screening Service
      |
ImageStorage Interface
      |
S3CompatibleStorage
```

Possible future implementations: - AWS S3 - Cloudflare R2 - private
S3-compatible storage - another compliant object-storage service

### AI

``` text
Screening Service
      |
AIClient Interface
      |
FastAPIAIClient
      |
FastAPI
```

The AI implementation can later change without rewriting the screening
domain.

### Healthcare integrations

``` text
Referral Service
      |
HealthcareIntegration Interface
      |
Mock / Local Provider
      |
Future external healthcare integration
```

No fake production integration should be claimed.

## 11. Security Architecture

-   TLS for all network communication.
-   Role-based access control.
-   Object storage private by default.
-   Signed URLs for controlled image access.
-   Patient-level authorization.
-   Facility/scope authorization for healthcare workers.
-   Environment-based secret management.
-   Input validation.
-   Rate limiting.
-   Audit logs.
-   Data minimization.
-   Encryption at rest where supported.
-   Model and pipeline version tracking.
-   No credentials in source control.

Roles: - PATIENT - HEALTHCARE_WORKER - ADMIN

## 12. Auditability

Record important events:

``` text
PATIENT_CREATED
IMAGE_UPLOADED
QUALITY_CHECK_COMPLETED
AI_INFERENCE_COMPLETED
HUMAN_REVIEW_COMPLETED
RECOMMENDATION_CREATED
REFERRAL_CREATED
FOLLOW_UP_UPDATED
```

Each event should include actor, action, resource, timestamp, and
relevant non-sensitive metadata.

## 13. Deployment Evolution

### Development

``` text
Flutter
Next.js
PostgreSQL
FastAPI
Local/S3-compatible storage
```

### Hackathon prototype

``` text
Flutter
      |
Next.js on Vercel
      |
Managed PostgreSQL
      |
FastAPI on container service
      |
Object Storage
```

### Future production

The same logical architecture can move to enterprise/private
infrastructure. Provider-specific changes should be limited to
infrastructure adapters and deployment configuration.

## 14. Non-Goals

RETIVA does not: - autonomously diagnose a patient; - prescribe
medication; - replace an ophthalmologist; - let an LLM override safety
rules; - let AI autonomously select a hospital; - claim direct JKN/BPJS
or SATUSEHAT integration without an authorized implementation.

## 15. Architecture Decision Summary

The recommended architecture is **Next.js modular application +
PostgreSQL/Prisma + object storage + FastAPI AI microservice + Flutter
client**.

This provides enough separation for a serious healthcare product while
avoiding premature microservice complexity.
