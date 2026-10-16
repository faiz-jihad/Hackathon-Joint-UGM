# RETIVA Web & Core API Gateway

### *Next.js 14 App Router • Clean Architecture • Tele-Ophthalmology Portal • Care Companion AI*

[![Next.js](https://img.shields.io/badge/Framework-Next.js_14_App_Router-000000?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/Language-TypeScript_Strict_Mode-3178C6?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org/)
[![Database](https://img.shields.io/badge/Database-PostgreSQL_16_%2B_Prisma_ORM-336791?style=for-the-badge&logo=postgresql)](prisma/schema.prisma)
[![Storage](https://img.shields.io/badge/Storage-Zero--BLOB_S3--Compatible-EA580C?style=for-the-badge&logo=amazons3)](infrastructure/storage)
[![Tests](https://img.shields.io/badge/Tests-63%2F63_Automated_Invariants_Passed-10B981?style=for-the-badge)](scripts)

---

## 1. Ikhtisar Subsistem Web & Gateway

Direktori `web/` merupakan inti (*core gateway & application portal*) dari ekosistem **RETIVA**. Subsistem ini menjalankan dua fungsi krusial:

1. **Central API Gateway & Business Engine**:
   - Mengorkestrasi seluruh alur kerja klinis, validasi NIK 16 digit, autentikasi multi-peran (Nakes FKTP, Dokter Spesialis Sp.M, Administrator), manajemen rekam medis longitudinal, dan integrasi internal ke FastAPI AI Service.
   - Mengisolasi klien mobile dan browser dari basis data langsung melalui batasan arsitektur yang ketat.
2. **Tele-Ophthalmology Web Portal**:
   - Konsol klinis berbasis web bagi dokter spesialis mata (Sp.M) untuk meninjau antrean kasus borderline (*Human-in-the-Loop*), menganalisis overlay atensi Grad-CAM, mengonfirmasi/mengoreksi diagnosis, dan menandatangani resume medis digital.
   - Portal administrasi direktori fasilitas kesehatan sekunder/tersier (RSUD, RS Mata, status BPJS Kesehatan) dan audit log kepatuhan hukum medis non-repudiation.
3. **Agentic AI Care Companion**:
   - Asisten pra & pasca-konsultasi untuk edukasi nutrisi rendah indeks glikemik (GI) ramah kantong Indonesia, deteksi tanda bahaya retina darurat (red flags), konfirmasi resume dokter, dan pengingat kontrol berkala.
4. **Distribusi Android APK & Demo Accounts**:
   - Beranda (`/`) menyediakan tautan langsung unduh APK Android mobile client: [`public/retiva-app.apk`](public/retiva-app.apk).
   - Akun demo bawaan siap pakai:
     - **Admin**: `admin@gmail.com` / `password`
     - **Dokter Sp.M**: `dr.harianto@retiva.id` / `password`
     - **Nakes**: `nakes.siti@puskesmas.go.id` / `password`

---

## 2. Pola Arsitektur: Clean Architecture (Hexagonal / Ports & Adapters)

Modul web dirancang dengan prinsip pemisahan tanggung jawab mutlak:

```text
web/
├── domain/                      # [Core Inner Layer] Aturan Medis & Entitas Bisnis Murni
│   ├── entities/                # User, Patient, Screening, ClinicalRecommendation, AuditLog
│   ├── rules/                   # Perdami 2024 Decision Matrix, Geodesic Distance Engine
│   └── care-companion/          # UrgentSymptomChecker, CareStateMachine, BudgetNutritionEngine
│
├── application/                 # [Use Cases Layer] Alur Kerja Operasional Spesifik
│   ├── auth/                    # Login, Register, Password Reset, OAuth
│   ├── patient/                 # Intake, Verifikasi NIK, Diabetes Profiling
│   ├── screening/               # Bilateral Orchestrator, Quality Gate Dispatcher, AI Forwarder
│   ├── referral/                # Faskes Nearest Matching, SPK ICD-10 Generator
│   ├── review/                  # Specialist Tele-Adjudication & Finalization
│   └── care-companion/          # Care Companion Orchestrator & Action Dispatcher
│
├── infrastructure/              # [Adapters Layer] Integrasi Eksternal & Pustaka Pihak Ketiga
│   ├── database/                # Prisma PostgreSQL Client & Repositories
│   ├── storage/                 # S3-Compatible Zero-BLOB Storage Adapter (AWS S3, MinIO, Presigned URLs)
│   ├── ai/                      # HTTP Client ke FastAPI Microservice (Port 8003)
│   ├── security/                # Bcrypt Password Hashing, JWT Token Issuer, Rate Limiter
│   └── email/                   # Nodemailer Provider (Reset Password, Notifikasi Rujukan)
│
└── app/                         # [Interface / Controllers Layer] Next.js 14 App Router
    ├── api/v1/                  # 53 REST API Endpoints Terstruktur
    ├── (auth)/                  # Halaman Login, Registrasi, Lupa Kata Sandi
    ├── (dashboard)/             # Konsol Dokter Spesialis Mata, Antrean Review, Direktori Faskes
    └── care-companion/          # Antarmuka Interaktif Pasien & Care Companion
```

---

## 3. Katalog REST API v1 (53 Endpoints)

Semua endpoint beroperasi di bawah prefiks `/api/v1/*` dengan *Role-Based Access Control* (RBAC) dan validasi skema Zod:

| Modul Domain | Rute Endpoint | Metode | Hak Akses | Deskripsi Fungsional |
| :--- | :--- | :---: | :---: | :--- |
| **Autentikasi & Akun** | `/api/v1/auth/register` | `POST` | Public | Registrasi akun baru (Nakes / Dokter / Admin) |
| | `/api/v1/auth/login` | `POST` | Public | Login akun & penerbitan token JWT |
| | `/api/v1/auth/me` | `GET` | Authenticated | Profil & wewenang pengguna aktif |
| | `/api/v1/auth/reset-password` | `POST` | Public | Permohonan reset kata sandi via email |
| | `/api/v1/auth/google` | `GET` | Public | Inisiasi alur Single Sign-On Google OAuth |
| | `/api/v1/auth/google/callback` | `GET` | Public | Callback pertukaran token Google OAuth |
| **Manajemen Pasien** | `/api/v1/patients` | `GET`, `POST` | Nakes / Sp.M | Daftar pasien (filter NIK) & pendaftaran pasien baru |
| | `/api/v1/patients/[id]` | `GET`, `PUT` | Nakes / Sp.M | Detail demografi & pembaruan data pasien |
| | `/api/v1/patients/[id]/diabetes-profile` | `GET`, `POST`, `PUT` | Nakes / Sp.M | Profil riwayat diabetes & metabolik pasien |
| **Profil Diabetes** | `/api/v1/diabetes-profiles` | `GET`, `POST` | Nakes / Sp.M | Manajemen profil diabetes terpisah |
| **Alur Skrining Retina** | `/api/v1/screenings` | `GET`, `POST` | Nakes / Sp.M | Buat sesi skrining baru dengan informed consent |
| | `/api/v1/screenings/direct-screen` | `POST` | Nakes / Sp.M | **Unified Endpoint**: Upload & inferensi instan |
| | `/api/v1/screenings/[id]` | `GET` | Nakes / Sp.M | Detail komprehensif sesi skrining bilateral |
| | `/api/v1/screenings/[id]/images` | `POST` | Nakes / Sp.M | Registrasi metadata citra fundus & SHA-256 hash |
| | `/api/v1/screenings/[id]/images/[imageId]/url` | `GET` | Nakes / Sp.M | Ambil presigned time-limited image URL (15 min) |
| | `/api/v1/screenings/[id]/quality-check` | `POST` | Nakes / Sp.M | Eksekusi OpenCV Quality Gate bilateral |
| | `/api/v1/screenings/[id]/analyze` | `POST` | Nakes / Sp.M | Inferensi 5-kelas ICDR & evaluasi keandalan |
| | `/api/v1/screenings/[id]/ai-result` | `GET` | Nakes / Sp.M | Ambil hasil inferensi model AI yang tersimpan |
| **Telaah Dokter Sp.M** | `/api/v1/reviews/pending` | `GET` | Dokter Sp.M | Antrean skrining borderline (Confidence < 85%) |
| | `/api/v1/reviews/[screeningId]` | `GET`, `POST` | Dokter Sp.M | Formulir adjudikasi resmi dokter spesialis mata |
| **Rekomendasi Klinis** | `/api/v1/recommendations/[screeningId]` | `GET` | Nakes / Sp.M | Lembar rekomendasi Perdami 2024 & jadwal kontrol |
| **Faskes Rujukan & BPJS**| `/api/v1/facilities` | `GET`, `POST` | Nakes / Sp.M | Direktori RS rujukan mata & status BPJS |
| | `/api/v1/facilities/nearest` | `GET` | Nakes / Sp.M | Pencarian RS terdekat via kalkulasi Haversine |
| | `/api/v1/facilities/match` | `POST` | Nakes / Sp.M | Pencocokan cerdas faskes rujukan multi-kriteria |
| **Surat Pengantar (SPK)**| `/api/v1/referrals` | `GET`, `POST` | Nakes / Sp.M | Penerbitan SPK rujukan resmi berstandar ICD-10 |
| | `/api/v1/referrals/[id]` | `GET`, `PUT` | Nakes / Sp.M | Pelacakan status kehadiran pasien di RS rujukan |
| **Jadwal Follow-Up** | `/api/v1/follow-ups` | `GET`, `POST` | Nakes / Sp.M | Penjadwalan kontrol berkala di FKTP/FKRTL |
| | `/api/v1/follow-ups/[id]` | `PUT` | Nakes / Sp.M | Konfirmasi kehadiran jadwal kontrol pasien |
| **Riwayat Longitudinal** | `/api/v1/history/patient/[patientId]` | `GET` | Nakes / Sp.M | Timeline funduskopi longitudinal antar-tahun |
| | `/api/v1/history/patients/[patientId]` | `GET` | Nakes / Sp.M | Endpoint alias jamak untuk kompatibilitas mobile |
| **Agentic AI Care Companion** | `/api/v1/care-companion/urgent-check` | `POST` | Authenticated | Deteksi gejala darurat mata (kilatan cahaya, tirai hitam) |
| | `/api/v1/care-companion/state` | `GET`, `POST` | Authenticated | Status state machine perjalanan perawatan pasien |
| | `/api/v1/care-companion/consultation-summary` | `GET`, `POST` | Nakes / Sp.M | Ringkasan konsultasi dokter terstruktur |
| | `/api/v1/care-companion/consultation-summary/[id]/confirm`| `POST` | Pasien / Sp.M | Konfirmasi persetujuan resume medis oleh dokter |
| | `/api/v1/care-companion/meal-plan/generate` | `POST` | Authenticated | Rekomendasi nutrisi harian rendah GI ramah budget IDR |
| | `/api/v1/care-companion/meal-plan/replace-meal`| `POST` | Authenticated | Penggantian menu makan dengan rekalkulasi budget instan |
| | `/api/v1/care-companion/reminders` | `GET`, `POST` | Authenticated | Pengingat jadwal minum obat & jadwal kontrol retina |
| | `/api/v1/care-companion/reminders/[id]` | `PUT`, `DELETE` | Authenticated | Konfirmasi konsumsi obat atau hapus pengingat |
| | `/api/v1/care-companion/progress` | `GET` | Authenticated | Metrik kepatuhan gaya hidup & riwayat evaluasi |
| | `/api/v1/care-companion/orchestrator` | `POST` | Authenticated | Orkestrasi dialog multi-turn dengan riwayat audit |
| **Master Data Medis** | `/api/v1/master/meals` | `GET`, `POST` | Admin / Sp.M | Bank data resep makanan diabetes bergizi lokal |
| | `/api/v1/master/meals/[id]` | `PUT`, `DELETE` | Admin / Sp.M | Perubahan data gizi, harga IDR, & kategori menu |
| | `/api/v1/master/questions` | `GET`, `POST` | Admin / Sp.M | Bank pertanyaan screening anamnesis pra-konsultasi |
| | `/api/v1/master/questions/[id]` | `PUT`, `DELETE` | Admin / Sp.M | Manajemen pertanyaan terstandar dokter mata |
| **Verifikasi Dokter** | `/api/v1/doctor-verifications` | `GET`, `POST` | Admin / Sp.M | Verifikasi legalitas SIP/NIP dokter spesialis |
| **Tata Kelola Model AI** | `/api/v1/models` | `GET`, `POST` | Admin / Sp.M | Registrasi metadata model inferensi baru |
| | `/api/v1/models/active` | `GET` | Authenticated | Metadata model yang saat ini aktif digunakan |
| | `/api/v1/models/[id]` | `GET` | Admin / Sp.M | Rincian arsitektur, parameter, & checksum bobot |
| | `/api/v1/models/[id]/activate` | `POST` | Administrator | Pergantian versi model aktif secara dinamis |
| **Manajemen Pengguna** | `/api/v1/users` | `GET` | Administrator | Katalog seluruh tenaga medis & staf terdaftar |
| | `/api/v1/users/[id]` | `GET`, `PUT` | Administrator | Pembaruan peran, faskes penugasan, dan status |
| **Jejak Audit Forensik**| `/api/v1/audit-logs` | `GET` | Administrator | Log non-repudiation (Aktor, NIP, IP, Timestamp) |
| **Kesehatan Sistem** | `/api/v1/health` | `GET` | Public | Liveness check (Web Gateway, Database, AI Service) |

---

## 4. Invarian Keamanan Medis & Regulasi

1. **Zero-BLOB Storage Invariant**:
   - Basis data PostgreSQL **tidak pernah menyimpan file biner gambar**.
   - Citra fundus disimpan di bucket S3 terisolasi (`retiva-fundus-images`) dengan checksum SHA-256 (64 hex characters) sebagai bukti integritas data.
   - Dokter dan nakes hanya mengakses citra melalui *time-limited presigned URL* (masa kedaluwarsa 15 menit).
2. **Kepatuhan Rekam Medis Elektronik (Permenkes No. 24/2022)**:
   - Setiap mutasi rekam medik wajib mencatat identitas aktor, NIP/SIP, peran, alamat IP klien, dan catatan waktu berpresisi *microsecond* ke dalam tabel `audit_logs`.
   - Data historis bersifat *append-only* (tidak dapat dihapus atau ditimpa sembarangan).
3. **Kepatuhan Perlindungan Data Pribadi (UU PDP No. 27/2022)**:
   - Wajib *informed consent* eksplisit sebelum inisiasi pengambilan foto retina.
   - Kata sandi di-hash menggunakan **bcrypt** (*cost factor 12*).
   - Seluruh token otentikasi menggunakan JSON Web Token (JWT) dengan signature rahasia berkekuatan tinggi.
4. **Pertahanan Berlapis (Defense in Depth)**:
   - Header keamanan HTTP: `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`.
   - *In-memory rate limiter* untuk mencegah serangan brute-force pada endpoint otentikasi.

---

## 5. Menjalankan Subsistem Web Secara Lokal

### 5.1 Prasyarat
- Node.js `>= 18.x` (Direkomendasikan v20 LTS / v22 LTS)
- PostgreSQL `>= 15.x` (Lokal pada port 5432 atau Cloud Neon.tech / Supabase)

### 5.2 Konfigurasi Lingkungan (`web/.env`)
Salin file `.env.example` ke `web/.env`:
```bash
cp .env.example web/.env
```

Pastikan variabel utama terisi:
```env
# Koneksi Basis Data
DATABASE_URL="postgresql://retiva:retivapassword@localhost:5432/retiva_db?schema=public"

# URL Layanan AI FastAPI
AI_SERVICE_URL="http://localhost:8003"

# Kunci JWT & Keamanan
JWT_SECRET="retiva_super_secure_jwt_secret_key_minimum_32_characters"

# Konfigurasi Storage S3 / MinIO
S3_ENDPOINT="http://localhost:9000"
S3_ACCESS_KEY="minioadmin"
S3_SECRET_KEY="minioadminpassword"
S3_BUCKET_NAME="retiva-fundus-images"
S3_REGION="us-east-1"
```

### 5.3 Inisialisasi Database Prisma
```bash
cd web
npm install

# Generate Prisma Client TypeScript
npx prisma generate

# Sinkronisasikan skema ke database
npx prisma db push

# (Opsional) Isi database dengan data demo faskes dan pasien
npx prisma db seed
```

### 5.4 Menjalankan Server Pengembangan
```bash
npm run dev
```
Portal Web & API Gateway aktif di: `http://localhost:3000`

---

## 6. Verifikasi Pengujian Otomatis

Subsistem Web dilengkapi pengujian otomatis arsitektur yang komprehensif:

```bash
# Menjalankan Master Test Suite (38 Invariants Arsitektural)
npm run test:master

# Menjalankan Test Suite Care Companion AI (25 Invariants)
npm run test:care-companion

# Menjalankan uji bertahap (Phase 1 s/d Phase 5)
npm run test:phase1  # Identity, RBAC, NIK 16-Digit
npm run test:phase2  # Zero-BLOB Storage, SHA-256 Checksums
npm run test:phase3  # AI Model Registry & Inference Pipeline
npm run test:phase4  # Specialist Review & Perdami Rules
npm run test:phase5  # Non-Repudiation Audit Trail & Security
```

**Hasil Verifikasi: 63 / 63 Invariant Passed (100% Green)**.
