# RETIVA — Platform Skrining Retinopati Diabetik Nasional
### *Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*

[![Test Invariants](https://img.shields.io/badge/Master_Tests-38%2F38_Passed_(100%25)-success?style=flat-square&logo=checkmarx)](scripts/test-master.ts)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2F_Ports_%26_Adapters-blue?style=flat-square)](docs/architecture/ARCHITECTURE.md)
[![Web & API](https://img.shields.io/badge/Web_Core-Next.js_14_App_Router-black?style=flat-square&logo=next.js)](web)
[![AI Microservice](https://img.shields.io/badge/AI_Service-FastAPI_%2F_EfficientNet--B3-009688?style=flat-square&logo=fastapi)](ai-service)
[![Database](https://img.shields.io/badge/Database-PostgreSQL_16_%2B_Prisma_ORM-336791?style=flat-square&logo=postgresql)](web/prisma/schema.prisma)
[![Storage](https://img.shields.io/badge/Storage-Zero--BLOB_S3--Compatible-orange?style=flat-square&logo=amazons3)](infrastructure/storage)
[![Compliance](https://img.shields.io/badge/Compliance-Permenkes_24%2F2022_%7C_UU_PDP_27%2F2022-indigo?style=flat-square)](docs/security/SECURITY_COMPLIANCE.md)

---

**RETIVA** adalah platform sistem pendukung keputusan klinis (*Clinical Decision Support System* / CDSS) terintegrasi berbasis kecerdasan buatan dan kendali mutu citra bilateral yang dirancang khusus untuk memfasilitasi penapisan (*screening*) komplikasi mikrovaskular diabetes melitus pada mata di Fasilitas Kesehatan Tingkat Pertama (FKTP / Puskesmas / Klinik Pratama) dan Fasilitas Kesehatan Rujukan Tingkat Lanjutan (FKRTL / Rumah Sakit Spesialis Mata).

> **Prinsip Utama Arsitektur Medis:**  
> *"Retiva adalah alur kerja skrining diabetes yang terpercaya yang kebetulan menggunakan AI — bukan model AI yang dibungkus antarmuka kesehatan."*  
> **Reliability Before Prediction**: Model kecerdasan buatan memiliki hak dan kewajiban klinis untuk *abstain* (menolak prediksi / memicu eskalasi telaah spesialis) apabila citra masukan buram atau probabilitas inferensi berada dalam zona ketidakpastian (*uncertainty margin*).

RETIVA diposisikan secara tegas sebagai **screening support tool**, bukan alat penegak diagnosis otonom, dan **bukan pengganti dokter spesialis mata (Sp.M)**. Keputusan klinis definitif tetap berada di bawah wewenang dokter berizin praktik resmi.

---

## 1. Alur Klinis Skrining (Clinical Pipeline & State Machine)

Sistem mengorkestrasi alur penapisan dari intake pasien hingga rujukan rujukan berstandar ICD-10:

```text
               +-------------------------------------------+
               |  Kedatangan Pasien di FKTP / Puskesmas    |
               +-------------------------------------------+
                                     |
                                     v
               +-------------------------------------------+
               | Verifikasi NIK (16-Digit) & Profil DM     |
               | Informed Consent Bilateral (UU PDP 2022)  |
               +-------------------------------------------+
                                     |
                                     v
               +-------------------------------------------+
               | Pemotretan Funduskopi Digital (OD / OS)   |
               +-------------------------------------------+
                                     |
                                     v
               +-------------------------------------------+
               |   Kendali Mutu Citra (Quality Gate)       |
               |   - Indeks Ketajaman Laplacian >= 0.40    |
               |   - Keseimbangan Pencahayaan Kanal Hijau  |
               |   - Cakupan Field of View (FOV) >= 45°    |
               +-------------------------------------------+
                               /           \
                 [GAGAL MUTU] /             \ [LOLOS MUTU]
                             v               v
               +---------------+   +------------------------------------+
               | RETAKE FOTO   |   | Inferensi AI (EfficientNet-B3)     |
               | (Instruksi    |   | 5 Kelas Keparahan ICDR             |
               |  Nakes Aktif) |   +------------------------------------+
               +---------------+                     |
                                                     v
                                   +------------------------------------+
                                   | Evaluasi Keandalan Klinis          |
                                   | (Reliability Gate)                 |
                                   | - Confidence Score >= 0.85         |
                                   | - Top-1 vs Top-2 Margin >= 0.20    |
                                   +------------------------------------+
                                         /                    \
                        [BORDERLINE /   /                      \ [HIGH RELIABILITY]
                         LOW CONFIDENCE]                        v
                                       v             +----------------------+
                        +----------------------+     | Rekomendasi Klinis   |
                        | Antrean Telaah       |     | Deterministik        |
                        | Spesialis Mata       |     | (Perdami & ADA 2024) |
                        | (Human-in-the-Loop & |     +----------------------+
                        |  Grad-CAM Heatmap)   |                |
                        +----------------------+                v
                                       \             +----------------------+
                                        \            | Pencocokan Faskes    |
                                         ----->      | Rujukan Geodesik     |
                                                     | (Haversine & BPJS)   |
                                                     +----------------------+
                                                                |
                                                                v
                                                     +----------------------+
                                                     | Penerbitan SPK (RME) |
                                                     | Riwayat Longitudinal |
                                                     +----------------------+
```

---

## 2. Arsitektur dan Komponen Sistem

RETIVA menerapkan **Clean Architecture (Ports & Adapters / Modular Monolith)** dengan pemisahan mutlak antara aturan domain medis, orkestrasi aplikasi, dan infrastruktur eksternal:

```text
                           RETIVA PLATFORM
                                  |
           +----------------------+----------------------+
           |                                             |
     Web Portal & Core API                         AI Microservice
     (Next.js 14 + TypeScript)                    (FastAPI + Python 3.11)
           |                                             |
   +-------+-------+                                     |
   | Domain Layer  |                                     |
   | (Pure Logic)  |                                     |
   +-------+-------+                                     |
           |                                             |
   +-------+-------+                                     |
   | Application   | <--- Internal Service Call ------>  |
   | (Use Cases)   |      (Port 8003, HMAC Token)        |
   +-------+-------+                                     |
           |                                             |
   +-------+---------------+                             |
   | Infrastructure        |                             |
   | Adapters              |                             |
   +---+-------+-------+---+                             |
       |       |       |                                 |
       v       v       v                                 v
   PostgreSQL S3/MinIO Bcrypt/JWT                  PyTorch / ONNX / TFLite
   (Prisma 18) (Zero-BLOB) (Security)              (EfficientNet-B3 + Grad-CAM)
```

### Rincian Komponen:
1. **Web Portal & API Gateway (`web/`)**:
   - Next.js 14 App Router, React 18, TypeScript (Strict Mode).
   - Antarmuka berbasis Vanilla CSS Design System tanpa dependensi utility UI pihak ketiga, dirancang tenang, profesional, dan bebas emoji sesuai standar klinis.
2. **Layanan Inferensi AI (`ai-service/`)**:
   - FastAPI microservice (Python 3.11+), Uvicorn ASGI server.
   - Arsitektur model EfficientNet-B3 dengan *Multi-Format Model Loader* (PyTorch `.pt`/`.pth`, ONNX `.onnx`, TensorFlow Lite `.tflite`, serta modul *Dynamic Heuristic Engine* sebagai fallback dev/testing tanpa GPU).
   - Pipeline evaluasi kualitas gambar berbasis OpenCV dan visualisasi interpretatif Grad-CAM (*fail-safe execution*).
3. **Database & ORM (`web/prisma/`)**:
   - PostgreSQL 16 dengan Prisma ORM mencakup 18 model relasional medis ternormalisasi.
4. **Penyimpanan Citra Medis (`Zero-BLOB Storage`)**:
   - Penyimpanan berbasis S3-Compatible Object Storage (AWS S3, MinIO, atau Cloudflare R2).
   - **Zero-BLOB Invariant**: Basis data PostgreSQL tidak pernah menyimpan BLOB citra; hanya menyimpan storage key privat, metadata teknis, dan hash integritas kriptografis SHA-256 (64 hex).
   - Akses citra fundus hanya menggunakan *presigned time-limited URL* dengan masa kedaluwarsa 15 menit.
5. **Klien Mobile Tenaga Kesehatan (`mobile/`)**:
   - Arsitektur Flutter untuk operasional kader dan perawat di posyandu/puskesmas pembantu.
   - *Strict Network Boundary*: Mobile client hanya berkomunikasi dengan Core API (`/api/v1/*`), tanpa akses langsung ke basis data maupun FastAPI.

---

## 3. Skala Klasifikasi ICDR & Mesin Aturan Perdami/ADA 2024

RETIVA mengadopsi standar internasional *International Clinical Diabetic Retinopathy* (ICDR) 5 tingkat dan menerjemahkannya ke rekomendasi klinis deterministik:

| Derajat ICDR | Istilah Medis | Temuan Patologis Khas Funduskopi | Risiko Progresivitas | Tindakan & Rekomendasi Alur (Perdami & ADA 2024) | Urgensi |
| :---: | :--- | :--- | :---: | :--- | :---: |
| **0** | **No DR** | Tidak ditemukan lesi mikroretina; makula dan diskus optikus tenang. | < 5% / tahun | Skrining ulang rutin tahunan (12 bulan) di FKTP; kendali glikemik & HbA1c standar. | `LOW` |
| **1** | **Mild NPDR** | Mikroaneurisma terisolasi fokal; tanpa eksudat atau perdarahan luas. | 5% – 15% / tahun | Monitoring berkala 6–12 bulan di FKTP; konseling gaya hidup dan optimalisasi terapi DM. | `LOW` |
| **2** | **Moderate NPDR** | Mikroaneurisma multipel, perdarahan bercak (*dot-blot*), *cotton-wool spots*, belum memenuhi kriteria 4-2-1. | 15% – 27% / tahun | Rujukan elektif ke Dokter Spesialis Mata (Sp.M) di FKRTL dalam kurun 3–6 bulan; evaluasi funduskopi lanjutan. | `MEDIUM` |
| **3** | **Severe NPDR** | Memenuhi kriteria **4-2-1**: (a) Perdarahan berat 4 kuadran; (b) *Venous beading* 2 kuadran; atau (c) IRMA 1 kuadran. | 50% – 75% / tahun | **Rujukan Cepat (2–4 minggu)** ke Spesialis Retina FKRTL; evaluasi fotokoagulasi laser argon panretina (PRP). | `HIGH` |
| **4** | **PDR** | Neovaskularisasi retina/diskus (NVD/NVE), perdarahan vitreus pra-retina, atau ablasio retina traksional. | > 75% / tahun | **Rujukan Darurat (< 1–2 minggu)** ke Pusat Rujukan Mata Tersier; intervensi anti-VEGF intravitreal atau vitreoretinal surgery. | `CRITICAL` |

---

## 4. Matriks Peran Pengguna (Role-Based Access Control)

Sistem menerapkan RBAC ketat sesuai hierarki operasional pelayanan kesehatan:

| Peran (*Role*) | Akses Dashboard | Input Pasien & Profil DM | Eksekusi Skrining Bilateral | Telaah & Override Spesialis | Tata Kelola Model & Audit |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`ADMIN`** | ✅ Penuh | ✅ Lihat | ❌ | ❌ | ✅ Konfigurasi & Audit Trail |
| **`OPHTHALMOLOGIST`** | ✅ Klinis | ✅ Lihat/Cari | ✅ (Supervisi) | ✅ Ajudikasi Resmi & SPK | ✅ Pantau Metrik Akurasi |
| **`HEALTHCARE_WORKER`** | ✅ Operasional | ✅ Registrasi | ✅ Upload & Quality Check | ❌ (Hanya Lihat Status) | ❌ |
| **`PATIENT`** | ❌ Portal Staf | ❌ (Hanya Profil Mandiri) | ❌ | ❌ | ❌ |

---

## 5. Ringkasan Endpoint REST API v1 (31 Endpoints)

REST API v1 diimplementasikan secara terstruktur di bawah rute `/api/v1/*` dengan respons format JSON konsisten:

| Domain Modul | Rute Endpoint | Metode HTTP | Deskripsi Fungsional Medis |
| :--- | :--- | :---: | :--- |
| **Autentikasi & Akun** | `/api/v1/auth/register` | `POST` | Registrasi akun nakes / dokter / administrator baru. |
| | `/api/v1/auth/login` | `POST` | Login dengan verifikasi password hash bcrypt dan penerbitan JWT. |
| | `/api/v1/auth/me` | `GET` | Mendapatkan data profil dan wewenang pengguna yang sedang aktif. |
| **Manajemen Pasien** | `/api/v1/patients` | `GET` / `POST` | Katalog pasien (pencarian NIK/nama) & pendaftaran pasien baru. |
| | `/api/v1/patients/[id]` | `GET` / `PUT` | Rincian data demografis pasien dan riwayat medis terkait. |
| **Profil Diabetes Melitus** | `/api/v1/diabetes-profiles` | `GET` / `POST` | Daftar riwayat metabolik & pencatatan HbA1c/tipe terapi baru. |
| | `/api/v1/diabetes-profiles/[id]` | `GET` / `PUT` | Pembaruan data tekanan darah, durasi DM, dan terapi aktif. |
| **Alur Skrining Bilateral** | `/api/v1/screenings` | `GET` / `POST` | Inisiasi alur skrining baru dengan informed consent UU PDP. |
| | `/api/v1/screenings/[id]` | `GET` | Detail status skrining, kedua citra mata (OD/OS), dan hasil CDSS. |
| | `/api/v1/screenings/[id]/images` | `POST` | Registrasi metadata citra fundus dan verifikasi checksum SHA-256. |
| | `/api/v1/screenings/[id]/quality` | `POST` | Eksekusi evaluasi Quality Gate bilateral (ketajaman, kontras, FOV). |
| | `/api/v1/screenings/[id]/analyze` | `POST` | Permintaan inferensi model AI 5 kelas dan evaluasi Reliability Gate. |
| | `/api/v1/screenings/[id]/complete` | `POST` | Finalisasi alur skrining dan penguncian rekam medik. |
| **Telaah Dokter Spesialis** | `/api/v1/reviews/pending` | `GET` | Antrean skrining dengan keandalan rendah atau kasus borderline. |
| | `/api/v1/reviews/[id]` | `GET` / `POST` | Formulir ajudikasi resmi dokter spesialis mata (konfirmasi/override). |
| **Rekomendasi Medis** | `/api/v1/recommendations` | `POST` | Evaluasi aturan deterministik Perdami & ADA 2024. |
| | `/api/v1/recommendations/[screeningId]` | `GET` | Mengambil lembar rekomendasi dan interval kontrol terjadwal. |
| **Faskes Rujukan & BPJS** | `/api/v1/facilities` | `GET` / `POST` | Direktori RS rujukan mata beserta koordinat dan status BPJS. |
| | `/api/v1/facilities/nearest` | `GET` | Pencarian faskes terdekat berbasis kalkulasi geodesik Haversine. |
| **Surat Pengantar Rujukan** | `/api/v1/referrals` | `GET` / `POST` | Penerbitan dan pelacakan Surat Pengantar Rujukan (SPK) ICD-10. |
| | `/api/v1/referrals/[id]` | `GET` / `PUT` | Pembaruan status kehadiran pasien di fasilitas kesehatan rujukan. |
| **Jadwal Kontrol Follow-Up** | `/api/v1/follow-ups` | `GET` / `POST` | Penjadwalan kontrol berkala di FKTP atau FKRTL. |
| | `/api/v1/follow-ups/[id]` | `PUT` | Konfirmasi kehadiran kontrol atau penyesuaian jadwal pasien. |
| **Riwayat Longitudinal** | `/api/v1/history/patient/[id]` | `GET` | Timeline riwayat funduskopi multi-tahun untuk analisis progresivitas lesi. |
| **Tata Kelola Model AI** | `/api/v1/models` | `GET` / `POST` | Registrasi versi model (bobot hash, arsitektur, parameter). |
| | `/api/v1/models/active` | `GET` | Mengambil metadata model inferensi yang sedang aktif bertugas. |
| | `/api/v1/models/[id]/activate` | `POST` | Pergantian versi model inferensi aktif secara dinamis. |
| **Jejak Audit Non-Repudiation** | `/api/v1/audit-logs` | `GET` | Log audit forensik mencatat identitas aktor, IP, peran, dan riwayat aksi. |

---

## 6. Struktur Direktori Proyek

```text
retiva-monorepo/
├── .env.example                     # Templat variabel lingkungan sistem
├── docker-compose.yml               # Orkestrasi PostgreSQL, MinIO, AI-Service, dan Web
├── package.json                     # Root monorepo workspace scripts
│
├── ai-service/                      # Layanan Inferensi Kecerdasan Buatan (FastAPI)
│   ├── app/
│   │   ├── api/routes.py            # Rute endpoint REST AI (/quality, /predict, /gradcam)
│   │   ├── core/config.py           # Konfigurasi ambang batas mutu dan keandalan
│   │   ├── models/
│   │   │   ├── efficientnet.py      # Definisi arsitektur EfficientNet-B3 PyTorch
│   │   │   └── model_loader.py      # Multi-Format Model Loader (PyTorch, ONNX, TFLite)
│   │   └── services/
│   │       ├── quality_service.py   # Analisis OpenCV: Laplacian blur, FOV, pencahayaan
│   │       ├── reliability_service.py # Evaluasi margin keyakinan dan entropi distribusi
│   │       ├── gradcam_service.py   # Peta atensi gradien konvolusi Grad-CAM
│   │       └── inference_service.py # Koordinator alur inferensi aman
│   ├── requirements.txt             # Dependensi Python
│   └── Dockerfile                   # Kontainerisasi AI microservice
│
├── web/                             # Aplikasi Web Portal & Core Backend API (Next.js 14)
│   ├── app/                         # Next.js 14 App Router
│   │   ├── api/v1/                  # 31 Rute REST API Controller
│   │   ├── globals.css              # Design tokens dan sistem layout klinis
│   │   ├── layout.tsx               # Root layout aplikasi web
│   │   └── page.tsx                 # Entrypoint Dashboard Alur Kerja Terpadu
│   ├── application/                 # Clean Architecture: Application Layer (Use Cases)
│   │   ├── auth/                    # Layanan pendaftaran dan autentikasi
│   │   ├── patient/                 # Manajemen demografi dan profil DM
│   │   ├── screening/               # Orkestrator alur mutu, inferensi, dan penutupan
│   │   ├── review/                  # Telaah human-in-the-loop dokter spesialis
│   │   ├── recommendation/          # Eksekutor rekomendasi klinis
│   │   └── referral/                # Logika rujukan geodesik dan follow-up
│   ├── domain/                      # Clean Architecture: Domain Layer (Pure TypeScript)
│   │   ├── auth/                    # Entity User, Role, Value Objects
│   │   ├── patient/                 # Entity Patient, NIK Validator, Diabetes Profile
│   │   ├── screening/               # Entity Screening, RetinalImage, QualityCheck, AIResult
│   │   ├── model-version/           # Entity ModelVersion & Hash Checksum
│   │   ├── recommendation/          # RecommendationRulesEngine (Perdami/ADA Rules)
│   │   ├── facility/                # Entity Facility, Geodesic Calculator (Haversine)
│   │   ├── referral/                # Entity Referral & ICD-10 Coding
│   │   └── audit/                   # Entity AuditLog (Non-Repudiation Schema)
│   ├── infrastructure/              # Clean Architecture: Adapters & External Drivers
│   │   ├── ai/                      # HTTP Client ke FastAPI AI Microservice
│   │   ├── persistence/             # Prisma Repositories (PostgreSQL)
│   │   ├── security/                # Bcrypt, JWT, Rate Limiter, HTTP Security Headers
│   │   └── storage/                 # S3-Compatible Object Storage Adapter (Presigned URLs)
│   ├── components/                  # Komponen Antarmuka Klinis Reusable
│   │   ├── DashboardView.tsx        # Pemantauan metrik antrean harian
│   │   ├── ScreeningWorkflowView.tsx# Wizard skrining bilateral OD/OS & Quality Gate
│   │   ├── OphthalmologistReviewView.tsx # Split viewer (Fundus vs Grad-CAM heatmap)
│   │   ├── PatientsDirectoryView.tsx# Pencarian NIK & Timeline Longitudinal
│   │   ├── ReferralsFacilityView.tsx# Katalog RS Mata & Perhitungan Jarak Geodesik
│   │   └── AuditRegistryView.tsx    # Jejak audit forensik dan tata kelola model
│   ├── prisma/
│   │   └── schema.prisma            # 18 Model Skema Relasional Medis
│   └── scripts/
│       ├── test-master.ts           # Unified Master Test Suite (38/38 Invariants)
│       └── test-phase1.ts s/d test-phase5.ts # Pengujian unit per fase
│
├── mobile/                          # Klien Aplikasi Mobile (Flutter)
│   └── README.md                    # Panduan arsitektur dan batasan boundary mobile
│
└── docs/                            # Dokumentasi Lengkap Sistem & Standar Medis
    ├── clinical/                    # Spesifikasi Klinis & CDSS Perdami/ADA 2024
    ├── architecture/                # Dokumen Detail Clean Architecture & Ports-and-Adapters
    ├── api/                         # Spesifikasi API v1 & Skema OpenAPI 3.0
    ├── security/                    # Kepatuhan Keamanan, UU PDP No. 27/2022, & Permenkes 24/2022
    └── user-guide/                  # Panduan Operasional Nakes FKTP & Dokter Spesialis FKRTL
```

---

## 7. Panduan Menjalankan Sistem (Quickstart)

### 7.1 Prasyarat Sistem
- **Node.js**: Versi `>= 18.x` (Direkomendasikan Node.js v20 LTS atau v22 LTS)
- **Python**: Versi `>= 3.10` (Direkomendasikan Python 3.11 untuk AI Microservice)
- **Docker & Docker Compose**: (Opsional, untuk PostgreSQL & MinIO lokal instan)

---

### 7.2 Menjalankan via Docker Compose (Metode Paling Cepat)
Untuk menjalankan PostgreSQL, MinIO Object Storage, FastAPI AI Service, dan Web Portal secara bersamaan:

```bash
# Menjalankan seluruh kontainer dalam mode background
docker compose up -d

# Memeriksa status kontainer aktif
docker compose ps
```
- Web Portal: **`http://localhost:3000`**
- AI Service: **`http://localhost:8003`** (Dokumentasi Swagger: `http://localhost:8003/docs`)
- MinIO Storage Console: **`http://localhost:9001`** (User: `minioadmin`, Password: `minioadminpassword`)

---

### 7.3 Menjalankan Pengembangan Lokal (Manual Step-by-Step)

#### Langkah 1: Konfigurasi Variabel Lingkungan
Salin file `.env.example` dari root ke folder `web/.env`:
```bash
# Pada direktori root monorepo:
cp .env.example web/.env
```
Pastikan pengaturan koneksi database dan URL AI service sesuai:
```env
DATABASE_URL="postgresql://retiva:retivapassword@localhost:5432/retiva_db?schema=public"
JWT_SECRET="retiva-healthcare-jwt-secret-replace-in-production-min-32-chars"
STORAGE_ENDPOINT="http://localhost:9000"
STORAGE_BUCKET="retiva-fundus-images"
STORAGE_ACCESS_KEY="minioadmin"
STORAGE_SECRET_KEY="minioadminpassword"
AI_SERVICE_URL="http://localhost:8003"
AI_INTERNAL_SECRET="retiva-internal-secret-token"
```

#### Langkah 2: Menjalankan AI Service (FastAPI — Port 8003)
```bash
# Masuk ke direktori AI Service
cd ai-service

# Buat virtual environment
python -m venv .venv

# Aktifkan virtual environment
# Windows (PowerShell):
.venv\Scripts\Activate.ps1
# Linux / macOS:
source .venv/bin/activate

# Pasang pustaka dependensi
pip install -r requirements.txt

# Jalankan server FastAPI pada port 8003
uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload
```
> *Catatan*: Layanan AI dilengkapi *Dynamic Model Loader* yang tetap beroperasi mulus menggunakan evaluasi heuristik deterministik jika bobot model PyTorch/ONNX lokal belum diunduh.

#### Langkah 3: Menjalankan Web Portal & Core API (Next.js — Port 3000)
Buka terminal baru di direktori root atau `web`:
```bash
# Masuk ke direktori web
cd web

# Pasang dependensi Node.js
npm install

# Sinkronisasi skema basis data Prisma
npx prisma generate
npx prisma db push

# Jalankan server pengembangan Next.js
npm run dev
```
Buka browser Anda dan akses aplikasi pada: **`http://localhost:3000`**.

---

## 8. Pengujian Otomatis & Verifikasi Invariant Medis

RETIVA dilengkapi dengan master test runner komprehensif (`web/scripts/test-master.ts`) yang memverifikasi **38 dari 38 batasan arsitektural dan invariant medis (100% Pass Rate)**:

```bash
# Menjalankan seluruh pengujian end-to-end (Phase 1 s/d Phase 5)
npm test

# Atau jalankan langsung dari folder web:
npm run test:master
```

### Rincian Cakupan Invariant Medis yang Diverifikasi:

```text
▶ [PHASE 1] Identity, Authorization & Patient Demographics (11/11 Passed)
  ✅ Bcrypt Password Hashing & Salt Verification (Cost 12)
  ✅ Bcrypt Incorrect Password Rejection
  ✅ Ophthalmologist Role Assignment (RBAC Boundary)
  ✅ JWT Token Signing & Medical Claims Decodability
  ✅ Patient Age Dynamic Computation from Date of Birth
  ✅ Invalid NIK Format Rejection (Strict 16-Digit Indonesia Rule)
  ✅ Valid NIK & Patient Demographic Entity Integrity
  ✅ Diabetes Profile Creation & HbA1c Parameter Validation
  ✅ High-Risk Glycemic Status Flagging (HbA1c > 8.0%)
  ✅ Controlled Glycemic Target Verification (HbA1c < 7.0%)
  ✅ Bilateral Informed Consent Verification (UU PDP No. 27/2022)

▶ [PHASE 2] Storage Abstraction, Zero-BLOB Invariant & Quality Gate (8/8 Passed)
  ✅ Zero-BLOB Invariant: Object Storage Key Generated (No DB BLOBs)
  ✅ Zero-BLOB Invariant: Strict SHA-256 Checksum Validation (64 Hex)
  ✅ Presigned URL Expiration Enforcement (15-Minute Time Limit)
  ✅ Quality Gate: Sharpness Laplacian Evaluation (Pass >= 0.40)
  ✅ Quality Gate: Blurry Retinal Image Rejection (Fail < 0.40)
  ✅ Quality Gate: Illumination Balance Evaluation (Green Channel)
  ✅ Quality Gate: Retake Required Flagging on Blurry Images
  ✅ Bilateral Retinal Image Association (OD Oculus Dexter & OS Oculus Sinister)

▶ [PHASE 3] AI Model Registry, 5-Class Inference & Reliability Gate (7/7 Passed)
  ✅ Model Registry: Active EfficientNet-B3 Model Metadata Retrieval
  ✅ Model Registry: Inactive & Deprecated Version Segregation
  ✅ AI 5-Class Inference: Softmax Probability Distribution Sums to 1.0
  ✅ AI 5-Class Inference: Precise Severity Mapping to ICDR Scale
  ✅ Reliability Gate: High Confidence Detection (>= 0.85 & Margin >= 0.20)
  ✅ Reliability Gate: Low Confidence Flagging (Uncertainty Routing)
  ✅ Reliability Gate: Borderline Entropy Flagging (Near-Tie Classification)

▶ [PHASE 4] Specialist Review, Perdami Rules, Geodesic Referral & Follow-up (8/8 Passed)
  ✅ Human Review Queue: Automatic Routing on Low Reliability / Borderline
  ✅ Human Review: Ophthalmologist Adjudication & Clinical Override
  ✅ Perdami Rule: No DR Routine 12-Month Interval Determination
  ✅ Perdami Rule: Mild NPDR 6-Month Control & Glycemic Optimization
  ✅ Perdami Rule: Severe NPDR / PDR Urgent Specialist Referral
  ✅ Geodesic Distance Computation (Haversine Formula Spherical Earth)
  ✅ Facility Matching: Nearest Tertiary Facility with BPJS Active Coverage
  ✅ Electronic Referral Letter (SPK) Generation with ICD-10 Coding (E11.319)

▶ [PHASE 5] Audit Trail, Model Activation, Security Hardening (4/4 Passed)
  ✅ Audit Log: Non-Repudiation Immutable Record Creation
  ✅ Audit Log: Actor Role, IP Address, and Action Metadata Binding
  ✅ Security: In-Memory Rate Limiter Throttling (Anti-Brute Force)
  ✅ Security: Hospital HTTP Security Headers (CSP, HSTS, X-Frame-Options DENY)
```

Untuk menjalankan pengujian parsial per fase:
```bash
npm run test:phase1   # Identitas, RBAC, NIK & Profil Diabetes
npm run test:phase2   # Zero-BLOB Storage, SHA-256 Checksums, Quality Gate
npm run test:phase3   # Registry Model, Inferensi 5-Kelas, Reliability Gate
npm run test:phase4   # Human Review, Aturan Perdami, Rujukan Geodesik & Follow-up
npm run test:phase5   # Non-Repudiation Audit Trail, Model Governance & Security
```

---

## 9. Kepatuhan Regulasi & Standar Keamanan Medis

1. **Prinsip Nol-Penyimpanan Citra di Database (Zero-BLOB Invariant)**:  
   Basis data relasional PostgreSQL tidak pernah menampung file citra mentah. Gambar hanya disimpan di object storage terisolasi dengan penamaan *hash partition* yang tidak dapat ditebak.
2. **Tautan Akses Berbatas Waktu (Presigned HMAC URLs)**:  
   Setiap tampilan citra retina pada portal web dokter menggunakan URL presigned bertanda tangan kriptografis dengan masa kedaluwarsa 15 menit, mencegah kebocoran tautan publik.
3. **Log Audit Non-Repudiation (Tak Terbantahkan)**:  
   Setiap aksi klinis (pengambilan foto, penilaian mutu, inferensi AI, perubahan derajat oleh dokter spesialis, hingga penerbitan rujukan) dicatat dalam tabel `audit_logs` bersama identitas pengguna, NIP/SIP, peran, alamat IP, dan catatan waktu *microsecond*. Memenuhi ketentuan **Permenkes No. 24 Tahun 2022 tentang Rekam Medis Elektronik**.
4. **Kepatuhan Perlindungan Data Pribadi (UU PDP No. 27/2022)**:  
   Pencatatan data sensitif kesehatan pasien dilindungi dengan informed consent bilateral eksplisit, enkripsi kata sandi menggunakan bcrypt (*cost factor 12*), dan pemisahan data kredensial dari profil medis.
5. **Pertahanan Berlapis (Defense-in-Depth)**:  
   Penerapan HTTP Security Headers tingkat rumah sakit (*Content-Security-Policy*, *Strict-Transport-Security*, *X-Frame-Options DENY*, *X-Content-Type-Options nosniff*), serta *in-memory sliding window rate limiter* untuk menangkal serangan brute-force.

---

## 10. Indeks Dokumentasi Lengkap Proyek

Dokumentasi spesifikasi teknis, klinis, dan arsitektur RETIVA tersedia secara mendalam pada folder `docs/` dan folder komponen terkait:

* 🩺 **[Spesifikasi Klinis & CDSS (CLINICAL_SPECIFICATION.md)](docs/clinical/CLINICAL_SPECIFICATION.md)**: Konsensus Perdami 2024, skala keparahan ICDR, formula kendali mutu (Quality Gate), dan mesin aturan deterministik rujukan.
* 🏛️ **[Spesifikasi Arsitektur Sistem (ARCHITECTURE.md)](docs/architecture/ARCHITECTURE.md)**: Cetak biru Clean Architecture, perancangan domain model, pola Ports & Adapters, dan diagram sekuensial interaksi sistem.
* 🌐 **[Spesifikasi REST API v1 (API_V1.md)](docs/api/API_V1.md)**: Panduan 31 rute endpoint API beserta parameter permintaan, contoh respons JSON, dan skema kode status galat.
* 📄 **[Spesifikasi Standar OpenAPI 3.0 (openapi.json)](docs/api/openapi.json)**: Definisi format standar OAS 3.0 untuk pengujian otomatis menggunakan Postman / Swagger UI.
* 🛡️ **[Panduan Keamanan & Regulasi (SECURITY_COMPLIANCE.md)](docs/security/SECURITY_COMPLIANCE.md)**: Analisis komprehensif pemenuhan UU PDP No. 27/2022, Permenkes No. 24/2022, standar ISO 27001, serta audit trail non-repudiation.
* 📖 **[Panduan Pengguna & Alur Kerja (USER_GUIDE.md)](docs/user-guide/USER_GUIDE.md)**: Tata laksana pengoperasian antarmuka web bagi tenaga kesehatan FKTP dan dokter spesialis mata FKRTL.
* 🧠 **[Panduan AI Microservice (ai-service/README.md)](ai-service/README.md)**: Dokumentasi teknis model EfficientNet-B3, multi-format loader (PyTorch, ONNX, TFLite), Quality Evaluator OpenCV, dan Grad-CAM interpretability.
* 📱 **[Arsitektur Klien Mobile (mobile/README.md)](mobile/README.md)**: Prinsip batas jaringan (network boundary) klien Flutter untuk petugas lapangan di Puskesmas.
* 📋 **[Product Requirements Document (PRD.md)](prd.md)** & **[UX Design Specification (design.md)](design(1).md)**: Dokumen visi produk awal dan pedoman desain antarmuka klinis bebas distraksi visual.

---

## 11. Lisensi dan Hak Cipta

RETIVA dikembangkan untuk kompetisi Hackathon dan inovasi transformasi digital kesehatan nasional Indonesia.  
Hak cipta © 2026 Tim Pengembang RETIVA. Seluruh hak cipta dilindungi undang-undang.
