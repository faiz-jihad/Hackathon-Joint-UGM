
Saya sedang membangun RETIVA, sebuah platform AI-assisted diabetic retinopathy screening untuk pasien diabetes.

RETIVA bukan sekadar aplikasi klasifikasi citra retina. Produk ini memiliki alur:

Patient → Retinal Screening → Image Quality Gate → AI DR Screening → Reliability Gate → Human Review bila diperlukan → Screening Result → Recommendation → Referral → Follow-up → Screening History.

Model AI saat ini menggunakan EfficientNet-B3 untuk klasifikasi diabetic retinopathy 5 kelas:

* No DR
* Mild DR
* Moderate DR
* Severe DR
* Proliferative DR

RETIVA harus diposisikan sebagai screening support, bukan alat diagnosis dan bukan pengganti tenaga kesehatan.

## TUJUAN UTAMA

Bangun backend/API RETIVA dengan prinsip:

**"Retiva harus menjadi provider-agnostic dan healthcare-ready."**

Artinya arsitektur aplikasi tidak boleh terkunci pada:

* Vercel
* Supabase
* AWS
* Render
* Railway
* cloud provider tertentu
* object storage provider tertentu
* AI model/provider tertentu

Provider hanya dianggap sebagai infrastructure layer yang dapat diganti tanpa mengubah business/domain logic RETIVA.

Contoh:

Hari ini:
Next.js → PostgreSQL → Object Storage → FastAPI → EfficientNet-B3

Beberapa tahun kemudian:
Next.js / backend lain → PostgreSQL infrastructure lain → private healthcare storage → AI service/model baru

Business logic dan API contract RETIVA harus tetap dapat dipertahankan.

---

# STACK

Gunakan:

Frontend/mobile:

* Flutter

Web/backend:

* Next.js
* TypeScript
* REST API

Database:

* PostgreSQL
* Prisma ORM

AI:

* FastAPI
* Python
* EfficientNet-B3

Storage:

* S3-compatible object storage abstraction

Architecture:

* Modular architecture
* Domain-driven separation sederhana
* Repository pattern
* Service layer
* Adapter pattern
* Dependency inversion

Jangan overengineering. Ini masih prototype/hackathon, tetapi fondasinya harus bisa berkembang menjadi production healthcare platform.

---

# ARSITEKTUR

Gunakan konsep:

Flutter
↓
RETIVA API
↓
Application / Domain Layer
↓
Infrastructure Adapters
├── PostgreSQL
├── Object Storage
├── AI Service
├── Notification Service
└── Facility Data Provider

AI:

RETIVA API
↓
AI Client Adapter
↓
FastAPI
↓
EfficientNet-B3

Jangan membuat domain/business logic mengetahui detail provider.

Contoh YANG TIDAK BOLEH:

screeningService()
↓
supabase.from("screenings").insert(...)

Contoh YANG DIINGINKAN:

screeningService()
↓
screeningRepository.create(...)

Kemudian:

screeningRepository
↓
Prisma
↓
PostgreSQL

---

# DOMAIN UTAMA RETIVA

Buat domain berikut:

1. Patient
2. Diabetes Profile
3. Screening
4. Retinal Image
5. Image Quality Check
6. AI Result
7. Reliability Assessment
8. Human Review
9. Recommendation
10. Facility
11. Referral
12. Follow-up
13. Screening History
14. Model Version
15. Audit Log
16. Notification

---

# SCREENING WORKFLOW

Implementasikan state machine:

CREATED
↓
IMAGE_UPLOADED
↓
QUALITY_CHECK
├── FAIL → RETAKE_REQUIRED
↓ PASS
AI_ANALYZED
├── LOW_RELIABILITY → HUMAN_REVIEW
↓
SCREENING_COMPLETED
↓
FOLLOW_UP_REQUIRED
↓
REFERRAL_RECOMMENDED
↓
FOLLOW_UP_COMPLETED

Pastikan setiap perubahan status dapat dicatat dalam audit trail.

---

# IMAGE QUALITY GATE

AI pipeline harus memiliki quality gate sebelum klasifikasi.

Jika kualitas gambar tidak memenuhi threshold:

RETIVA → RETAKE_REQUIRED

Contoh alasan:

* image blurry
* terlalu gelap
* terlalu terang
* fundus tidak terlihat cukup
* crop/FOV tidak memadai

Jangan menjalankan DR classification sebagai hasil final jika quality gate gagal.

---

# RELIABILITY GATE

Setelah AI melakukan inference, hasil tidak boleh langsung dianggap valid.

Reliability Gate harus menghasilkan:

ANALYZE
HUMAN_REVIEW
atau RETAKE

Contoh:

quality_passed = true
confidence = 0.52
reliability = low

→ HUMAN_REVIEW

Sedangkan:

quality_passed = true
confidence = 0.91
reliability = high

→ ANALYZE

Threshold harus configurable dan versioned.

Jangan hard-code threshold di banyak tempat.

---

# AI SERVICE

Next.js tidak boleh menjalankan model Python secara langsung.

Buat AI abstraction:

AIClient

dengan interface seperti:

screen(imageUrl)
checkQuality(imageUrl)
getExplainability(screeningId)

Implementasi awal:

FastAPIAIClient

FastAPI memiliki endpoint:

POST /api/v1/screen
POST /api/v1/quality-check
POST /api/v1/explainability

Response AI harus structured.

Contoh:

{
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
"status": "analyze",
"score": 0.91
}
}

Jangan membuat frontend berkomunikasi langsung dengan FastAPI.

Flow:

Flutter
↓
RETIVA API
↓
AI Client
↓
FastAPI

---

# DATABASE

Gunakan PostgreSQL + Prisma.

Minimal model:

User
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
FacilityService
FacilityInsurance
Referral
FollowUp
ModelVersion
Notification
AuditLog

Fundus image JANGAN disimpan sebagai BLOB di PostgreSQL.

Database hanya menyimpan metadata dan object storage key:

retinal_images

* id
* screening_id
* eye
* storage_key
* mime_type
* uploaded_at
* checksum

---

# STORAGE ABSTRACTION

Buat interface:

ImageStorage

methods:

upload()
getSignedUrl()
delete()
exists()

Implementasi awal:

S3CompatibleStorage

Jangan menggunakan API provider secara langsung dari domain service.

Contoh:

screeningService
↓
imageStorage.upload()

bukan:

screeningService
↓
supabase.storage.from(...)

Dengan cara ini storage dapat diganti:

S3
Cloudflare R2
Supabase Storage
AWS S3
private object storage

tanpa mengubah business logic.

---

# DATABASE ABSTRACTION

Gunakan repository:

PatientRepository
ScreeningRepository
ReferralRepository
FollowUpRepository
FacilityRepository

Domain service tidak boleh melakukan query Prisma secara langsung.

Contoh:

ScreeningService
↓
ScreeningRepository
↓
Prisma
↓
PostgreSQL

---

# FACILITY & REFERRAL

RETIVA dapat membantu pasien menemukan fasilitas untuk tindak lanjut.

Facility memiliki:

* name
* address
* latitude
* longitude
* services
* insurance information
* JKN/BPJS availability
* verification status

Tetapi:

**AI tidak boleh memilih rumah sakit secara langsung.**

Flow:

AI Screening
↓
Reliability
↓
Human Review / clinical workflow
↓
Follow-up requirement
↓
Facility Matching
↓
Referral Recommendation

Facility matching merupakan business/application logic, bukan bagian dari model AI.

JKN/BPJS status harus memiliki status yang jelas:

* ACCEPTED
* NOT_AVAILABLE
* NEEDS_CONFIRMATION

Jangan mengklaim integrasi langsung dengan database BPJS/JKN jika belum tersedia atau belum diotorisasi.

---

# API DESIGN

Gunakan:

/api/v1/patients
/api/v1/diabetes-profiles
/api/v1/screenings
/api/v1/screenings/:id
/api/v1/reviews
/api/v1/recommendations
/api/v1/facilities
/api/v1/referrals
/api/v1/follow-ups
/api/v1/history

Gunakan RESTful API dan versioning.

API contract harus independen dari database provider dan cloud provider.

---

# SECURITY

Karena RETIVA berpotensi menjadi healthcare product, siapkan fondasi:

* authentication
* role-based access control
* authorization
* audit logs
* encrypted transport
* secure object storage
* signed image URLs
* minimal patient data
* model version tracking
* access logging
* input validation
* rate limiting
* secret management melalui environment variables
* jangan hard-code credentials
* jangan expose retinal image URL secara publik

Role minimal:

PATIENT
HEALTHCARE_WORKER
ADMIN

Pastikan pasien hanya dapat mengakses datanya sendiri.

Healthcare worker hanya dapat mengakses pasien yang berada dalam scope fasilitas/otorisasi yang sesuai.

---

# MODEL VERSIONING

Jangan hanya menyimpan:

prediction = moderate_dr

Simpan juga:

model_version
confidence
reliability_score
quality_score
inference_timestamp
pipeline_version

Contoh:

model_version:
efficientnet-b3-v1

Ini penting agar hasil screening lama tetap dapat ditelusuri jika model AI berubah di masa depan.

---

# AUDITABILITY

Setiap aktivitas penting harus dapat ditelusuri:

Patient created
Image uploaded
Quality check performed
AI inference performed
Human review performed
Recommendation generated
Referral created
Follow-up updated

Simpan:

actor
action
resource
timestamp
metadata

---

# RECOMMENDATION ENGINE

Recommendation tidak boleh menjadi diagnosis.

Gunakan rules engine sederhana:

Quality failed
→ Retake

AI unreliable
→ Human Review

Screening membutuhkan pemeriksaan lebih lanjut
→ Follow-up / referral recommendation

No concerning screening finding
→ Follow-up sesuai alur yang ditentukan tenaga kesehatan

Recommendation engine harus terpisah dari AI model.

Contoh:

RecommendationEngine
↓
RecommendationRules
↓
Recommendation

Jangan membuat LLM mengambil keputusan klinis.

---

# FUTURE INTEROPERABILITY

Arsitektur harus memungkinkan integrasi masa depan dengan:

* SATUSEHAT
* fasilitas kesehatan
* sistem rekam medis
* JKN ecosystem
* notification provider
* telemedicine
* external AI model

Tetapi JANGAN membuat fake integration.

Buat abstraction/interface terlebih dahulu.

Contoh:

HealthcareIntegrationAdapter

Implementasi awal:

MockHealthcareIntegration

Future:

SATUSEHATAdapter

Dengan begitu core RETIVA tidak bergantung langsung pada sistem eksternal.

---

# REPOSITORY STRUCTURE

Gunakan monorepo:

retiva/

├── mobile/
│   └── Flutter
│
├── web/
│   ├── app/
│   │   └── api/
│   │       └── v1/
│   │
│   ├── domain/
│   │   ├── patient/
│   │   ├── screening/
│   │   ├── referral/
│   │   ├── follow-up/
│   │   └── recommendation/
│   │
│   ├── application/
│   │   ├── screening/
│   │   ├── referral/
│   │   └── follow-up/
│   │
│   ├── infrastructure/
│   │   ├── database/
│   │   ├── storage/
│   │   ├── ai/
│   │   ├── notifications/
│   │   └── healthcare/
│   │
│   ├── prisma/
│   │   └── schema.prisma
│   │
│   └── lib/
│
├── ai-service/
│   ├── app/
│   │   ├── api/
│   │   ├── models/
│   │   ├── services/
│   │   └── schemas/
│   ├── models/
│   │   └── efficientnet_b3/
│   ├── tests/
│   └── Dockerfile
│
├── docs/
│   ├── architecture/
│   ├── api/
│   └── security/
│
├── docker-compose.yml
└── README.md

---

# DEPLOYMENT

Development:

Flutter
↓
Next.js local
↓
PostgreSQL local/container
↓
FastAPI local
↓
local/object storage

Prototype:

Flutter
↓
Next.js → Vercel
↓
Managed PostgreSQL
↓
FastAPI → Cloud container
↓
Object Storage

Production healthcare:

Flutter
↓
Healthcare-grade infrastructure
↓
RETIVA API
↓
Private/managed PostgreSQL
↓
Secure Object Storage
↓
AI Service
↓
Model Registry / Model Versioning

Pastikan perpindahan deployment tidak membutuhkan perubahan pada domain logic.

---

# IMPORTANT ARCHITECTURAL RULES

1. Jangan membuat domain logic bergantung pada provider.
2. Jangan membuat API bergantung pada Supabase/Vercel/Render.
3. Jangan menyimpan retinal image sebagai BLOB di PostgreSQL.
4. Jangan expose object storage secara publik.
5. Jangan membuat frontend memanggil FastAPI secara langsung.
6. Jangan membuat AI menentukan referral facility secara langsung.
7. Jangan membuat AI memberikan diagnosis.
8. Jangan hard-code AI threshold.
9. Jangan hard-code credentials.
10. Jangan membuat fake integration dengan BPJS/JKN/SATUSEHAT.
11. Gunakan API versioning.
12. Gunakan model versioning.
13. Gunakan audit trail.
14. Pisahkan domain, application, dan infrastructure.
15. Jangan overengineering microservices; cukup modular monolith + AI microservice.
16. Semua provider harus dapat diganti melalui adapter/interface.

---

# OUTPUT YANG SAYA INGINKAN

Sebelum menulis kode:

1. Jelaskan architecture secara singkat.
2. Tampilkan dependency flow.
3. Tampilkan folder structure.
4. Tampilkan database ERD konseptual.
5. Tampilkan API endpoint list.
6. Tampilkan screening state machine.
7. Jelaskan bagian mana yang provider-agnostic.
8. Jelaskan bagaimana Retiva dapat berpindah cloud/provider tanpa mengubah domain logic.

Setelah itu baru implementasikan secara bertahap.

Prioritas:

PHASE 1

* project structure
* PostgreSQL
* Prisma
* authentication
* Patient
* DiabetesProfile

PHASE 2

* Screening
* RetinalImage
* ImageStorage abstraction
* Quality Gate

PHASE 3

* FastAPI AI service
* AIClient abstraction
* EfficientNet-B3
* Reliability Gate

PHASE 4

* Human Review
* Recommendation
* Facility
* Referral
* Follow-up

PHASE 5

* Audit Log
* Model Versioning
* Security hardening
* API documentation
* testing

Jangan membuat seluruh sistem sekaligus jika akan menghasilkan kode yang sulit dipelihara.

Setiap phase harus menghasilkan kode yang dapat dijalankan dan diuji.

Tujuan akhirnya:

**RETIVA harus terlihat seperti produk healthcare yang memiliki fondasi teknis serius, tetapi tetap sederhana untuk dikembangkan oleh tim kecil dan tidak terkunci pada satu cloud provider, database vendor, storage vendor, atau AI model.**
