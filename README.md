# RETIVA — Platform Skrining Retinopati Diabetik Nasional

RETIVA (*Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*) adalah sistem pendukung keputusan klinis (*Clinical Decision Support System* / CDSS) berbasis kecerdasan buatan dan kendali mutu citra yang dirancang khusus untuk memfasilitasi skrining komplikasi diabetes melitus pada mata di Fasilitas Kesehatan Tingkat Pertama (FKTP / Puskesmas) dan Fasilitas Kesehatan Rujukan Tingkat Lanjutan (FKRTL / Rumah Sakit).

> **Prinsip Utama**: *"Retiva adalah alur kerja skrining diabetes yang terpercaya yang kebetulan menggunakan AI, bukan model AI yang dibungkus antarmuka kesehatan."*

RETIVA diposisikan secara tegas sebagai **screening support tool**, bukan alat penegak diagnosis definitif, dan **bukan pengganti dokter spesialis mata**.

---

## 1. Alur Klinis Skrining (Clinical Pipeline)

```text
Kedatangan Pasien di FKTP
      |
Pemeriksaan Profil Diabetes & Informed Consent
      |
Pemotretan Funduskopi Digital Bilateral (OD / OS)
      |
Kendali Mutu Citra Otomatis (Quality Gate)
   |-- GAGAL (Buram / Gelap / Artefak) --> Pengambilan Foto Ulang (Retake Required)
   |-- LOLOS (Sharpness >= 0.40, Illumination, Field of View 45°)
         |
Inferensi Model AI (EfficientNet-B3 5-Class ICDR)
         |
Evaluasi Keandalan Klinis (Reliability Gate)
   |-- KEANDALAN RENDAH / BORDERLINE --> Antrean Telaah Spesialis Mata (Human-in-the-Loop)
   |-- KEANDALAN TINGGI
         |
Rekomendasi Klinis Deterministik (Pedoman Perdami & Konsensus ADA 2024)
         |
Pencocokan Faskes Rujukan & Perhitungan Jarak Geodesik (BPJS/JKN-ready)
         |
Penerbitan Surat Pengantar Rujukan (SPK) & Riwayat Longitudinal Pasien
```

---

## 2. Arsitektur dan Komponen Sistem

RETIVA menerapkan **Clean Architecture (Ports & Adapters / Modular Monolith)** dengan pemisahan tegas antara logika domain medis dan infrastruktur:

* **Web Portal & Backend API**: Next.js 14 App Router, TypeScript, Vanilla CSS Design System (tanpa ketergantungan utility framework eksternal, desain klinis tenang, bebas emoji).
* **Database & ORM**: PostgreSQL, Prisma ORM (18 model relasional medis).
* **Penyimpanan Citra (Zero-BLOB Storage)**: S3-Compatible Object Storage (AWS S3, MinIO, Cloudflare R2). Basis data relasional tidak pernah menyimpan BLOB citra; hanya menyimpan storage key privat dan hash integritas SHA-256.
* **Layanan AI (Microservice)**: FastAPI (Python), EfficientNet-B3 PyTorch/ONNX, OpenCV Quality Evaluator, PyTorch Grad-CAM.
* **Aplikasi Klien Mobile**: Flutter (untuk operasional lapangan nakes).
* **Keamanan & Kepatuhan**: Hash bcrypt, token JWT, HTTP Security Headers rumah sakit (CSP, HSTS, X-Frame-Options DENY), in-memory rate limiting, dan non-repudiation audit trail.

---

## 3. Fitur Utama Web Portal

Antarmuka web dirancang sesuai spesifikasi `design.md`:

1. **Dashboard Alur Kerja**:
   - Pemantauan metrik harian: jumlah skrining selesai, kebutuhan foto ulang, antrean telaah dokter, dan rujukan aktif.
   - Tabel antrean skrining retina aktif dengan filter kendali mutu dan tingkat keandalan.
   - Ringkasan pedoman skrining nasional Perdami & ADA 2024.
2. **Skrining Baru (OD/OS)**:
   - Registrasi data demografis (NIK 16 digit, nama, usia) dan profil diabetes (tipe DM, durasi, HbA1c, terapi).
   - Verifikasi informed consent sesuai UU Perlindungan Data Pribadi (UU PDP No. 27/2022).
   - Pengambilan citra bilateral (Mata Kanan / Oculus Dexter dan Mata Kiri / Oculus Sinister).
   - Uji Quality Gate instan dengan umpan balik visual objektif (indeks ketajaman, pencahayaan, cakupan makula).
   - Analisis model 5 kelas ICDR (No DR, Mild NPDR, Moderate NPDR, Severe NPDR, PDR) beserta probabilitas detail.
   - Rekomendasi tindakan klinis dan interval kontrol otomatis.
3. **Portal Telaah Dokter Spesialis Mata (Human-in-the-Loop)**:
   - Split viewer: Inspeksi citra fundus resolusi tinggi vs peta aktivasi Grad-CAM (heatmap gradien atensi arsitektur konvolusi).
   - Disclaimer wajib: *Grad-CAM adalah konteks aktivasi model AI dan bukan bukti patologis mutlak*.
   - Formulir ajudikasi resmi: Konfirmasi temuan AI, koreksi derajat DR (*clinical override*), atau permintaan foto ulang.
   - Catatan klinis dokter penelaah yang terikat pada NIP/SIP dan tanda tangan digital audit trail.
4. **Direktori Pasien & Riwayat Longitudinal**:
   - Pencarian real-time berdasarkan NIK atau nama pasien.
   - Timeline longitudinal perkembangan lesi retina pasien antar-tahun untuk deteksi dini progresivitas retinopati.
   - Pendaftaran pasien baru langsung dari direktori.
5. **Jaringan Faskes Rujukan & BPJS**:
   - Katalog fasilitas kesehatan rujukan sekunder/tersier (RSUP Dr. Sardjito, RS Khusus Mata Dr. Yap, dll.).
   - Perhitungan jarak geodesik (*Haversine distance*) otomatis dari koordinat faskes primer.
   - Status penerimaan rujukan BPJS Kesehatan / JKN.
   - Penerbitan Surat Pengantar Rujukan (SPK) elektronik berstandar ICD-10 (`E11.319`).
6. **Tata Kelola, Model Registry & Log Audit**:
   - Registry model AI aktif (arsitektur EfficientNet-B3, bobot SHA-256, target input 300x300 RGB, AUC-ROC 0.941).
   - Catatan jejak audit non-repudiation tak terbantahkan untuk setiap aksi operator, inferensi, ajudikasi, dan rujukan.

---

## 4. Panduan Menjalankan Sistem (Quickstart)

### 4.1 Prasyarat
- Node.js >= 18.x (Direkomendasikan Node.js v20.x atau v22.x)
- Docker & Docker Compose (Opsional, untuk PostgreSQL & MinIO lokal)
- Python 3.10+ (Opsional, untuk AI Service lokal)

### 4.2 Menjalankan AI Service (FastAPI Microservice - Port 8003)
```bash
# Masuk ke direktori ai-service
cd ai-service

# Buat dan aktifkan virtual environment (Python 3.11+)
python -m venv .venv
# Linux/macOS: source .venv/bin/activate | Windows: .venv\Scripts\activate

# Pasang dependensi
pip install -r requirements.txt

# Jalankan server inferensi AI (Port 8003)
uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload
```
Layanan AI aktif di: **`http://localhost:8003`** (Dokumentasi Swagger: `http://localhost:8003/docs`).

### 4.3 Menjalankan Web Portal & API Gateway (Next.js - Port 3000)
```bash
# Masuk ke direktori web
cd web

# Salin konfigurasi environment
cp .env.example .env

# Pasang dependensi
npm install

# Buat prisma client
npx prisma generate

# Jalankan server pengembangan
npm run dev
```

Aplikasi web dapat diakses di browser pada: **`http://localhost:3000`**.

### 4.4 Menjalankan Seluruh Sistem via Docker Compose
```bash
# Menjalankan PostgreSQL, MinIO Storage, FastAPI AI Service (8003), dan Next.js Web (3000)
docker compose up -d
```

---

## 5. Pengujian Otomatis & Verifikasi Invariant

RETIVA dilengkapi dengan master test runner komprehensif yang memverifikasi 38/38 batasan arsitektural dan medis (100% pass):

```bash
# Menjalankan seluruh rangkaian uji Phase 1 s/d Phase 5
npm test

# Atau uji per-fase:
npm run test:phase1   # User Auth, Patient Demographics & Diabetes Profile
npm run test:phase2   # Storage Abstraction, Zero-BLOB Invariant & Quality Gate
npm run test:phase3   # AI Model Registry, 5-Class Inference & Reliability Gate
npm run test:phase4   # Human Review, Perdami Rules, Geodesic Referral & Follow-up
npm run test:phase5   # Non-Repudiation Audit Trail, Model Governance & Security Hardening
```

---

## 6. Kepatuhan Regulasi & Keamanan Medis

1. **Integritas Citra Zero-BLOB**: Tidak ada file gambar mentah yang disimpan dalam PostgreSQL. Hanya metadata, storage key privat, dan hash SHA-256 yang tersimpan.
2. **Presigned Time-Limited URLs**: Akses citra fundus berbatas waktu (10-15 menit) menggunakan HMAC cryptographic signature.
3. **Keputusan Deterministik**: Penentuan interval kontrol dan urgensi rujukan dieksekusi oleh mesin aturan berbasis konsensus Perdami/ADA 2024, bukan inferensi bebas LLM.
4. **Log Audit Non-Repudiation**: Memenuhi ketentuan Permenkes No. 24 Tahun 2022 tentang Rekam Medis Elektronik dan UU Perlindungan Data Pribadi No. 27 Tahun 2022.
5. **Pertahanan Berlapis (Defense-in-Depth)**: Rate limiting anti-brute force, enkripsi password bcrypt dengan cost factor 12, dan HTTP Security Headers tingkat rumah sakit.

---

## 7. Indeks Dokumentasi Lengkap

Dokumentasi teknis dan operasional sistem RETIVA tersedia secara mendalam pada folder `docs/`:

* **[Panduan Pengguna & Operasional Klinis (USER_GUIDE.md)](docs/user-guide/USER_GUIDE.md)**: Panduan langkah-demi-langkah bagi tenaga kesehatan FKTP dan dokter spesialis mata FKRTL.
* **[Spesifikasi Arsitektur Sistem (ARCHITECTURE.md)](docs/architecture/ARCHITECTURE.md)**: Rincian Clean Architecture, domain entities, ports & adapters, dan diagram sekuensial.
* **[Spesifikasi REST API v1 (API_V1.md)](docs/api/API_V1.md)**: Dokumentasi 31 rute endpoint API beserta skema permintaan, respons, dan kode galat.
* **[Spesifikasi OpenAPI 3.0 (openapi.json)](docs/api/openapi.json)**: Definisi standar OAS 3.0 untuk interoperabilitas Swagger / Postman.
* **[Panduan Kepatuhan Keamanan & Regulasi (SECURITY_COMPLIANCE.md)](docs/security/SECURITY_COMPLIANCE.md)**: Analisis kepatuhan UU PDP No. 27/2022, Permenkes 24/2022, ISO 27001, dan mitigasi risiko medis.
