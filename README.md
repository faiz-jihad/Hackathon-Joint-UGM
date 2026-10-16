# RETIVA — Platform Skrining Retinopati Diabetik Nasional

### *Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*

[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2F_Ports_%26_Adapters-0284C7?style=for-the-badge)](docs/architecture/ARCHITECTURE.md)
[![Web & Gateway](https://img.shields.io/badge/Web_Core-Next.js_14_App_Router-000000?style=for-the-badge&logo=next.js)](web)
[![Mobile Client](https://img.shields.io/badge/Mobile_Client-Flutter_3.x_%7C_Dart_3.x-02569B?style=for-the-badge&logo=flutter)](mobile)
[![AI Microservice](https://img.shields.io/badge/AI_Service-FastAPI_%2F_EfficientNet--B3-009688?style=for-the-badge&logo=fastapi)](ai-service)
[![Android APK](https://img.shields.io/badge/Download_APK-v1.0.0_(22.8_MB)-3DDC84?style=for-the-badge&logo=android)](web/public/retiva-app.apk)
[![Database](https://img.shields.io/badge/Database-PostgreSQL_16_%2B_Prisma_ORM-336791?style=for-the-badge&logo=postgresql)](web/prisma/schema.prisma)
[![Storage](https://img.shields.io/badge/Storage-Zero--BLOB_S3--Compatible-EA580C?style=for-the-badge&logo=amazons3)](infrastructure/storage)
[![Full-Stack Tests](https://img.shields.io/badge/Verification-103%2F103_Tests_Passed_(100%25)-10B981?style=for-the-badge)](docs/test-report.md)
[![Compliance](https://img.shields.io/badge/Compliance-Permenkes_24%2F2022_%7C_UU_PDP_27%2F2022-0D9488?style=for-the-badge)](docs/security/SECURITY_COMPLIANCE.md)

---

## 🎯 PANDUAN PENGUJIAN JURI (JURY QUICK EVALUATION GUIDE)

> **Selamat Datang Dewan Juri Hackathon Joint UGM!**  
> Kami telah menyiapkan **3 cara tercepat** bagi Bapak/Ibu Juri untuk langsung menguji fungsionalitas sistem RETIVA, mulai dari instalasi aplikasi mobile fisik, eksplorasi web portal klinis, hingga eksekusi pengujian otomatis.

---

### 📱 OPSI 1: Uji Aplikasi Mobile via Android APK (Paling Cepat & Nyata)

File instalasi APK Flutter telah dibuild dalam mode **Release (ARM64)** dan siap diinstall di smartphone Android:

* **File APK di Repository:** [`web/public/retiva-app.apk`](web/public/retiva-app.apk) (Ukuran: **22.8 MB**)
* **Unduh via Web Portal:** Buka [`http://localhost:3000`](http://localhost:3000) lalu klik tombol **"Download APK"** pada banner beranda.
* **Instalasi ke Smartphone (via ADB):**
  ```bash
  adb install web/public/retiva-app.apk
  ```
  *(Atau cukup kirim/copy file `retiva-app.apk` ke HP Android Anda dan tap untuk menginstall).*

> 💡 **Smart Offline Demo Fallback:**  
> Aplikasi mobile RETIVA dilengkapi fitur **Smart Offline Fallback**. Juri dapat langsung menguji alur lengkap skrining, Quality Gate penolakan foto buram, visualisasi heatmap Grad-CAM, hingga penerbitan SPK rujukan **bahkan tanpa perlu menyalakan backend**! Aplikasi otomatis beralih ke simulasi respon medis berstandar Perdami 2024 jika server backend tidak terdeteksi.

---

### 💻 OPSI 2: Akses Web Portal & Akun Demo Siap Pakai

Buka browser ke alamat: **`http://localhost:3000`**

Halaman awal mengusung antarmuka **Character Select Screen** modern retro-klinis. Juri dapat langsung memilih peran atau login menggunakan akun demo bawaan berikut:

| Peran (Role) | Email Login | Kata Sandi | Deskripsi Fitur yang Dapat Diuji |
| :--- | :--- | :---: | :--- |
| **Administrator** | `admin@gmail.com` | `password` | Manajemen faskes rujukan, tata kelola model AI, registrasi pengguna, dan jejak audit non-repudiation. |
| **Dokter Spesialis Mata (Sp.M)** | `dr.harianto@retiva.id` | `password` | **Antrean Human Review (`/reviews/pending`)**, telaah kasus *borderline*, overlay Grad-CAM, dan persetujuan resume medis digital. |
| **Dokter Spesialis Mata (Sp.M 2)**| `dr.anindita@retiva.id` | `password` | Ajudikasi medis sekunder dan peninjauan resume rujukan FKRTL. |
| **Nakes Puskesmas** | `nakes.siti@puskesmas.go.id` | `password` | Intake pasien dengan NIK 16 digit, skrining bilateral, dan penerbitan SPK rujukan ICD-10 (`E11.319`). |
| **Pasien Demo** | NIK: `3404015508750001` | - | Data rekam medis longitudinal Bapak Sutrisno (riwayat skrining tahunan). |

---

### ⚡ OPSI 3: Menjalankan Sistem Lokal (1-Click / Terminal)

#### Cara A: One-Click Windows Runner (Paling Praktis)
1. Cukup klik ganda file **`start-local.bat`** di direktori utama repository.
2. Skrip otomatis menyalin `.env`, menyalakan FastAPI AI Service (port 8003), dan Next.js Web Gateway (port 3000).

#### Cara B: Docker Compose
```bash
cp .env.example web/.env
docker compose up -d
```

#### Cara C: Eksekusi Manual via Terminal
```bash
# Terminal 1: Web & Gateway
cd web
npm install
npx prisma generate
npx prisma db push
npm run dev

# Terminal 2: AI Microservice
cd ai-service
python -m venv .venv
.venv\Scripts\activate          # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8003 --reload
```

---

### 🧪 OPSI 4: Verifikasi Uji Otomatis (103/103 Tests Passed - 100%)

Juri dapat memvalidasi seluruh invarian logika medis, keamanan rekam medis, dan kepatuhan regulasi secara instan:

```bash
# 1. Uji Master Core API (38 Invarian Medis, Zero-BLOB, dan Audit Trail)
npm run test:master

# 2. Uji Agentic AI Care Companion (25 Invarian Red-Flags, Glikemik Rendah, dan State Machine)
npm run test:care-companion

# 3. Uji Klien Mobile Flutter (20 Unit & Widget Tests)
cd mobile && flutter test

# 4. Uji FastAPI AI Service (20 Pytest: OpenCV Quality Gate & EfficientNet-B3)
cd ai-service && pytest
```

---

## 📑 Daftar Isi

1. [Ringkasan Eksekutif & Latar Belakang Klinis](#1-ringkasan-eksekutif--latar-belakang-klinis)
2. [Prinsip Medis & Batasan Keselamatan Klinis](#2-prinsip-medis--batasan-keselamatan-klinis)
3. [Alur Klinis & 3 Cabang State Machine](#3-alur-klinis--3-cabang-state-machine)
4. [Arsitektur Sistem & Komponen Terintegrasi](#4-arsitektur-sistem--komponen-terintegrasi)
5. [Agentic AI Care Companion (Pra & Pasca-Konsultasi)](#5-agentic-ai-care-companion-pra--pasca-konsultasi)
6. [Implementasi Klien Mobile Flutter (Figma 1:1 Mapping)](#6-implementasi-klien-mobile-flutter-figma-11-mapping)
7. [Skala Klasifikasi ICDR & Mesin Aturan Perdami/ADA 2024](#7-skala-klasifikasi-icdr--mesin-aturan-perdamiada-2024)
8. [Algoritma AI, Kendali Mutu Citra & Interpretabilitas](#8-algoritma-ai-kendali-mutu-citra--interpretabilitas)
9. [Katalog REST API v1 Terpadu (53 Endpoints)](#9-katalog-rest-api-v1-terpadu-53-endpoints)
10. [Struktur Direktori Repositori Monorepo](#10-struktur-direktori-repositori-monorepo)
11. [Panduan Instalasi & Eksekusi Sistem (Quickstart)](#11-panduan-instalasi--eksekusi-sistem-quickstart)
12. [Panduan Deployment Produksi & Setup SSL Otomatis](#12-panduan-deployment-produksi--setup-ssl-otomatis)
13. [Verifikasi Otomatis Menyeluruh (Full-Stack 103/103 Passed)](#13-verifikasi-otomatis-menyeluruh-full-stack-103103-passed)
14. [Kepatuhan Regulasi & Standar Keamanan Medis](#14-kepatuhan-regulasi--standar-keamanan-medis)
15. [Panduan Demonstrasi & Skenario Uji Klinis](#15-panduan-demonstrasi--skenario-uji-klinis)
16. [Indeks Dokumentasi Lengkap Proyek](#16-indeks-dokumentasi-lengkap-proyek)
17. [Lisensi dan Hak Cipta](#17-lisensi-dan-hak-cipta)

---

## 1. Ringkasan Eksekutif & Latar Belakang Klinis

**RETIVA** (*Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*) adalah platform sistem pendukung keputusan klinis (*Clinical Decision Support System* / CDSS) terintegrasi berbasis kecerdasan buatan, kendali mutu citra bilateral (*Quality Gate*), tele-adjudikasi *Human-in-the-Loop*, dan pendamping perawatan agen AI (*Agentic AI Care Companion*). Platform ini dirancang khusus untuk mendesentralisasi penapisan (*screening*) komplikasi mikrovaskular diabetes melitus pada retina mata dari rumah sakit rujukan ke Fasilitas Kesehatan Tingkat Pertama (FKTP / Puskesmas / Klinik Pratama).

### Urgensi Masalah Retinopati Diabetik di Indonesia:

* **Prevalensi Diabetes Melitus**: Menurut *International Diabetes Federation* (IDF) 2021, Indonesia menempati peringkat ke-5 dunia dengan lebih dari **19,5 juta penderita diabetes melitus**, dan diproyeksikan melonjak melebihi 28 juta jiwa pada tahun 2045.
* **Risiko Kebutaan Permanen**: Sekitar 1 dari 3 penderita diabetes akan mengalami retinopati diabetik (DR). Retinopati diabetik merupakan penyebab utama kebutaan yang dapat dicegah hingga 90% jika dideteksi pada fase awal (No DR / Mild NPDR).
* **Disparitas Dokter Spesialis Mata**: Jumlah dokter spesialis mata (Sp.M) di Indonesia hanya berkisar ~3.000 dokter untuk 278 juta penduduk (rasio ~1:92.000, jauh di bawah standar WHO 1:50.000), dengan lebih dari 65% terkonsentrasi di kota-kota besar pulau Jawa.
* **Solusi RETIVA**: Memfasilitasi tenaga kesehatan di FKTP untuk melakukan pemotretan funduskopi digital bilateral dengan kendali mutu seketika, inferensi keparahan berstandar ICDR, rekomendasi rujukan deterministik berstandar Perdami/ADA 2024, eskalasi otomatis ke dokter spesialis mata jika terjadi ketidakpastian, dan edukasi mandiri pasien pasca-skrining melalui AI Care Companion.

---

## 2. Prinsip Medis & Batasan Keselamatan Klinis

> ⚠️ **Pernyataan Batasan Klinis (Clinical Safety Mandate):**  
> **RETIVA adalah sistem pendukung keputusan penapisan (Screening Decision Support Tool), BUKAN alat penegak diagnosis definitif otonom, dan BUKAN pengganti dokter spesialis mata (Sp.M).**  
> Keputusan terapeutik, tindakan operatif, dan diagnosis definitif rekam medis tetap berada sepenuhnya di bawah tanggung jawab dokter yang memiliki Surat Izin Praktik (SIP) sah.

### Prinsip Utama Arsitektur Medis:

1. **"Retiva adalah alur kerja skrining diabetes yang terpercaya yang kebetulan menggunakan AI — bukan model AI yang dibungkus antarmuka kesehatan."**
2. **Reliability Before Prediction (Hak Menolak Model AI)**: Model kecerdasan buatan memiliki hak dan kewajiban klinis untuk *abstain* (menolak mengeluarkan prediksi) apabila:
   - Kualitas foto fundus buram, pencahayaan tidak seragam, atau sudut pandang (*Field of View*) tidak memenuhi syarat (memicu alur **Retake**).
   - Probabilitas inferensi berada dalam zona ketidakpastian / *borderline confidence* (memicu alur **Human Review**).
3. **Pemeriksaan Bilateral Wajib (OD & OS)**: Skrining retinopati diabetik selalu mengevaluasi kedua bola mata (*Oculus Dexter* / Mata Kanan dan *Oculus Sinister* / Mata Kiri) untuk mencegah kesalahan triase asimetris.

---

## 3. Alur Klinis & 3 Cabang State Machine

RETIVA mengorkestrasi alur penapisan dari intake pasien hingga penerbitan rujukan berstandar ICD-10 melalui 3 cabang *state machine* klinis yang deterministik:

```text
               +-------------------------------------------------------------+
               |            Kedatangan Pasien di FKTP / Puskesmas             |
               +-------------------------------------------------------------+
                                              |
                                              v
               +-------------------------------------------------------------+
               |  Verifikasi NIK (16-Digit) & Riwayat Metabolik Pasien       |
               |  Persetujuan Tindakan Bilateral (Informed Consent UU PDP)   |
               +-------------------------------------------------------------+
                                              |
                                              v
               +-------------------------------------------------------------+
               |    Pemotretan Funduskopi Digital Bilateral (OD / OS)        |
               +-------------------------------------------------------------+
                                              |
                                              v
               +-------------------------------------------------------------+
               |           KENDALI MUTU CITRA (QUALITY GATE OPENCV)          |
               |   - Indeks Ketajaman Varian Laplacian: >= 0.40               |
               |   - Keseimbangan Pencahayaan Kanal Hijau: 15% - 85%         |
               |   - Cakupan Sudut Pandang Retina (FOV): >= 45 Derajat       |
               +-------------------------------------------------------------+
                                        /           \
                          [GAGAL MUTU] /             \ [LOLOS MUTU]
                                      v               v
               +-------------------------+     +-------------------------------+
               | CABANG B: RETAKE FOTO   |     | Inferensi AI EfficientNet-B3  |
               | (Penolakan Citra Buram; |     | Klasifikasi 5 Derajat ICDR    |
               |  Instruksi Koreksi Jarak|     +-------------------------------+
               |  & Pencahayaan Nakes)   |                     |
               +-------------------------+                     v
                                               +-------------------------------+
                                               | EVALUASI KEANDALAN KLINIS     |
                                               | (RELIABILITY GATE)            |
                                               | - Confidence Score >= 0.85    |
                                               | - Top-1 vs Top-2 Margin >= 0.2|
                                               +-------------------------------+
                                                     /                   \
                                    [BORDERLINE /   /                     \ [HIGH RELIABILITY]
                                     LOW CONFIDENCE]                       v
                                                   v            +---------------------+
                                    +---------------------+     | CABANG A: NORMAL    |
                                    | CABANG C:           |     | Hasil Terverifikasi |
                                    | HUMAN REVIEW        |     | Rekomendasi Perdami |
                                    | (Eskalasi Telaah ke |     +---------------------+
                                    |  Dokter Spesialis   |                |
                                    |  Sp.M + Grad-CAM)   |                v
                                    +---------------------+     +---------------------+
                                                   \            | Pencocokan Faskes   |
                                    (Ajudikasi Sp.M)\           | Terdekat (Haversine |
                                                     ----->     | & BPJS Kesehatan)   |
                                                                +---------------------+
                                                                           |
                                                                           v
                                                                +---------------------+
                                                                | Penerbitan SPK RME  |
                                                                | ICD-10 (E11.319) &  |
                                                                | Rekam Longitudinal  |
                                                                +---------------------+
```

### Rincian 3 Cabang State Machine:

* **Cabang A: Normal / Autonomous Recommendation**: Citra lolos Quality Gate dan model memiliki keyakinan tinggi ($\ge 0.85$ dengan margin $\ge 0.20$). Sistem secara instan menyajikan kartu derajat keparahan ICDR, visualisasi heatmap Grad-CAM, jadwal kontrol rekomendasi Perdami/ADA 2024, dan daftar fasilitas kesehatan rujukan terdekat.
* **Cabang B: Retake Foto (Quality Gate Failure)**: Jika citra fundus buram, pencahayaan terlalu gelap/terang, atau bidang pandang retina tidak memenuhi syarat minimal $45^\circ$, AI **menolak melakukan prediksi**. Sistem memberikan umpan balik spesifik kepada nakes ("Lensa terlalu dekat", "Pencahayaan kurang seimbang") serta tombol *Ambil Ulang Foto*.
* **Cabang C: Human Review Pending (Reliability Gate Escalation)**: Jika citra lolos mutu tetapi tingkat keyakinan model berada di bawah ambang batas ($\text{confidence} < 0.85$ atau margin $< 0.20$), sistem menahan hasil skrining dari nakes dan mengirimkan berkas ke antrean telaah dokter spesialis mata (`/api/v1/reviews/pending`). Dokter Sp.M melakukan tele-adjudikasi dengan bantuan overlay Grad-CAM untuk mengonfirmasi atau mengoreksi derajat diagnosis.

---

## 4. Arsitektur Sistem & Komponen Terintegrasi

RETIVA mengadopsi pola **Clean Architecture (Ports & Adapters / Hexagonal Architecture)** di dalam struktur Monorepo modern:

```text
                                  +-------------------------------------------------+
                                  |                 RETIVA PLATFORM                 |
                                  +-------------------------------------------------+
                                                           |
                 +-----------------------------------------+-----------------------------------------+
                 |                                                                                   |
       [Flutter Mobile Client]                                                              [Web Portal & Core API]
     (Klien Nakes Puskesmas /                                                             (Next.js 14 App Router,
     Layar 400x854px Desain Figma)                                                        React 18, TypeScript)
                 |                                                                                   |
                 |  (HTTP/JSON REST via /api/v1/*)                                                   |
                 +------------------------------> [API GATEWAY] <------------------------------------+
                                                        |
                                            +-----------+-----------+
                                            |     DOMAIN LAYER      |
                                            | (Aturan Medis Murni)  |
                                            +-----------+-----------+
                                                        |
                                            +-----------+-----------+
                                            |   APPLICATION LAYER   | <====== Internal HTTP/HMAC ======> [FastAPI AI Service]
                                            |   (Use Cases Medis)   |         (Port 8003, Local Network)  - OpenCV Quality Gate
                                            +-----------+-----------+                                     - EfficientNet-B3 Model
                                                        |                                                 - Grad-CAM Heatmap
                                            +-----------+-----------+
                                            | INFRASTRUCTURE LAYER  |
                                            |      (Adapters)       |
                                            +-----+-----+-----+-----+
                                                  |     |     |
                                                  v     v     v
                                            PostgreSQL S3   Security
                                            (Prisma 16) (MinIO) (JWT/Bcrypt)
```

### Rincian Subsistem Utama:

1. **Aplikasi Mobile Tenaga Kesehatan ([`mobile/`](mobile/README.md))**:
   - Dibangun dengan Flutter (Dart 3.x), mereplikasi 100% rancangan Figma (400 × 854 px) untuk kader dan perawat FKTP.
   - **Multi-Environment Toggle**: Mendukung peralihan instan ke Subdomain HTTPS Resmi, VPS IP, Wi-Fi Lokal Laptop, Android Emulator, dan Fallback Offline Demo.
   - **Workstation Lengkap**: Penampil Grad-CAM interaktif (4.5x pinch-to-zoom, slider opasitas kontinu, grid anatomi), modal intake pasien NIK 16 digit, dan penerbitan SPK rujukan siap cetak/PDF.
2. **Web Portal & API Gateway Terpadu ([`web/`](web/README.md))**:
   - Next.js 14 App Router, React 18, TypeScript (Strict Mode).
   - Menyediakan **53 endpoint REST API terstruktur**, dashboard tele-adjudikasi dokter spesialis Sp.M, direktori faskes, log audit kepatuhan, dan modul Agentic AI Care Companion.
3. **Layanan Inferensi Kecerdasan Buatan ([`ai-service/`](ai-service/README.md))**:
   - FastAPI microservice (Python 3.11+), Uvicorn ASGI server (Port internal 8003).
   - Multi-Format Model Loader (PyTorch `.pt`/`.pth`, ONNX `.onnx`, TensorFlow Lite `.tflite`, dan Dynamic Heuristic Engine).
   - Pipeline evaluasi kendali mutu OpenCV dan visualisasi peta atensi Grad-CAM dengan isolasi galat (*fail-safe execution*).
4. **Basis Data Relasional & ORM ([`web/prisma/`](web/prisma/schema.prisma))**:
   - PostgreSQL 16 dengan Prisma ORM mencakup 18 model relasional medis ternormalisasi.
5. **Penyimpanan Citra Medis Objek (`Zero-BLOB Storage`)**:
   - S3-Compatible Object Storage (AWS S3, MinIO, atau Cloudflare R2).
   - **Zero-BLOB Invariant**: Citra hanya disimpan di bucket privat terisolasi dengan checksum SHA-256 (64 hex). Akses citra menggunakan *presigned time-limited URL* dengan masa kedaluwarsa 15 menit.

---

## 5. Agentic AI Care Companion (Pra & Pasca-Konsultasi)

RETIVA melangkah lebih jauh dari sekadar penapisan citra dengan menghadirkan **Agentic AI Care Companion** yang mendampingi pasien diabetes sepanjang perjalanan perawatan:

1. **Pemeriksa Gejala Darurat Retina (*Urgent Symptom Safety Evaluator*)**:
   - Mendeteksi *red-flag triggers* kedaruratan oftalmologi (seperti kilatan cahaya mendadak, bayangan tirai hitam ablasio retina, atau nyeri bola mata akut glaukoma sudut tertutup).
   - Secara tegas memblokir alur non-darurat dan menginstruksikan rujukan darurat seketika ke IGD Rumah Sakit Mata (`SEGERA_KE_IGD_RS_MATA`).
2. **Mesin State Machine Perjalanan Pasien (*Care State Machine*)**:
   - Memastikan proteksi ketat: **rencana tindak lanjut pasca-konsultasi tidak boleh diterbitkan sebelum ada konfirmasi resmi dari resume dokter spesialis mata**.
3. **Mesin Nutrisi Rendah GI Ramah Budget (*Budget-Aware Nutrition Engine*)**:
   - Menghasilkan rekomendasi pola makan harian 3 kali makan + 1 snack berbasis pangan lokal Indonesia (tempe, tahu, beras merah, ikan kembung, sayur bayam/bening) yang disesuaikan dengan batasan budget harian pasien (misal: Rp25.000 – Rp45.000/hari).
   - Mendukung pergantian menu per sesi (*meal replacement*) dengan perhitungan ulang otomatis terhadap sisa anggaran dan kalori target.
4. **Pengingat Pengobatan & Jadwal Kontrol Retinopati**:
   - Pengingat harian konsumsi obat antidiabetik oral / insulin, serta hitung mundur jadwal kontrol berkala ke dokter mata.

---

## 6. Implementasi Klien Mobile Flutter (Figma 1:1 Mapping)

| Layar / Frame Figma | Deskripsi Fungsional Medis | File Implementasi Flutter |
| :--- | :--- | :--- |
| **`01. Homepage`** | Beranda operasional nakes: ringkasan metrik skrining harian, panduan Perdami 2024, tombol skrining bilateral, dan navigasi cepat. | [`home_screen.dart`](mobile/lib/presentation/screens/home_screen.dart) |
| **`02 & 03. Upload I & II`** | Pemilihan mata bilateral (Mata Kanan `OD` vs Mata Kiri `OS`), retikel optik sudut pandang 45° FOV, dan integrasi kamera/galeri. | [`upload_fundus_screen.dart`](mobile/lib/presentation/screens/upload_fundus_screen.dart) |
| **`04 & 05. Kualitas Jelas`** | Animasi pemindaian kendali mutu: Ketajaman Laplacian (`>= 0.40`), Pencahayaan Kanal Hijau, dan Cakupan FOV Makula. | [`quality_scanning_screen.dart`](mobile/lib/presentation/screens/quality_scanning_screen.dart) |
| **`05. Kualitas Buram (Retake)`** | **Branch Retake**: Penolakan citra buram/gelap, metrik kegagalan mutu, panduan koreksi jarak lensa bagi nakes, dan tombol retake. | [`quality_failed_retake_screen.dart`](mobile/lib/presentation/screens/quality_failed_retake_screen.dart) |
| **`06–09. Analisis AI`** | Tahapan inferensi konvolusi EfficientNet-B3 5-Class ICDR dan evaluasi ambang batas keandalan (*Reliability Gate*). | [`ai_analyzing_screen.dart`](mobile/lib/presentation/screens/ai_analyzing_screen.dart) |
| **`10 & 11. Human Review`** | **Branch Human Review**: Penanganan kasus reliabilitas *borderline* (< 85%), sistem menahan prediksi dan mengalihkan ke antrean spesialis Sp.M. | [`human_review_pending_screen.dart`](mobile/lib/presentation/screens/human_review_pending_screen.dart) |
| **`11–13. Hasil & Grad-CAM`** | Kartu derajat ICDR (Derajat 0–4), skor keyakinan, diagram distribusi probabilitas, dan penampil interaktif Heatmap Grad-CAM. | [`screening_result_screen.dart`](mobile/lib/presentation/screens/screening_result_screen.dart) |
| **`14. Tindakan Lanjutan`** | Rekomendasi interval Perdami/ADA 2024 & pencocokan faskes rujukan sekunder/tersier terdekat (Haversine & BPJS Aktif). | [`clinical_recommendation_screen.dart`](mobile/lib/presentation/screens/clinical_recommendation_screen.dart) |
| **`15 & 16. Penerbitan SPK`** | Penerbitan Surat Pengantar Rujukan (SPK) elektronik resmi berstandar ICD-10 (`E11.319`) siap cetak/unduh PDF. | [`referral_letter_screen.dart`](mobile/lib/presentation/screens/referral_letter_screen.dart) |
| **`17. Riwayat Pasien`** | Pencarian NIK 16 digit pasien dan timeline visual longitudinal progresivitas lesi retina tahun ke tahun. | [`patient_history_screen.dart`](mobile/lib/presentation/screens/patient_history_screen.dart) |

---

## 7. Skala Klasifikasi ICDR & Mesin Aturan Perdami/ADA 2024

| Derajat ICDR | Istilah Medis | Temuan Patologis Khas Funduskopi | Risiko Progresivitas | Tindakan & Rekomendasi Alur (Perdami & ADA 2024) | Urgensi | Kode ICD-10 |
| :---: | :--- | :--- | :---: | :--- | :---: | :---: |
| **0** | **No DR** | Tidak ditemukan lesi mikroretina; makula dan diskus optikus tenang. | < 5% / tahun | Skrining ulang rutin tahunan (12 bulan) di FKTP; kendali glikemik & HbA1c standar. | `LOW` | `E11.9` |
| **1** | **Mild NPDR** | Mikroaneurisma terisolasi fokal; tanpa eksudat atau perdarahan luas. | 5% – 15% / tahun | Monitoring berkala 6–12 bulan di FKTP; konseling gaya hidup dan optimalisasi terapi DM. | `LOW` | `E11.319` |
| **2** | **Moderate NPDR** | Mikroaneurisma multipel, perdarahan bercak (*dot-blot*), *cotton-wool spots*, belum memenuhi kriteria 4-2-1. | 15% – 27% / tahun | Rujukan elektif ke Dokter Spesialis Mata (Sp.M) di FKRTL dalam kurun 3–6 bulan; evaluasi funduskopi lanjutan. | `MEDIUM` | `E11.319` |
| **3** | **Severe NPDR** | Memenuhi kriteria **4-2-1**: (a) Perdarahan berat 4 kuadran; (b) *Venous beading* 2 kuadran; atau (c) IRMA 1 kuadran. | 50% – 75% / tahun | **Rujukan Cepat (2–4 minggu)** ke Spesialis Retina FKRTL; evaluasi fotokoagulasi laser argon panretina (PRP). | `HIGH` | `E11.319` |
| **4** | **PDR** | Neovaskularisasi retina/diskus (NVD/NVE), perdarahan vitreus pra-retina, atau ablasio retina traksional. | > 75% / tahun | **Rujukan Darurat (< 1–2 minggu)** ke Pusat Rujukan Mata Tersier; intervensi anti-VEGF intravitreal atau vitreoretinal surgery. | `CRITICAL` | `E11.359` |

---

## 8. Algoritma AI, Kendali Mutu Citra & Interpretabilitas

* **OpenCV Quality Gate**: Menghitung varian Laplacian $\text{Var}(\nabla^2 I) \ge 0.40$, keseimbangan intensitas kanal hijau (15% - 85%), dan deteksi mask lingkaran FOV $\ge 45^\circ$.
* **EfficientNet-B3 Model**: Input resolusi $300 \times 300$ piksel, dioptimalkan untuk mendeteksi lesi mikrovaskular halus hingga neovaskularisasi.
* **Reliability Gate**: Evaluasi tingkat keyakinan ($\ge 0.85$), selisih margin kelas Top-1 vs Top-2 ($\ge 0.20$), dan Shannon entropy ($\le 1.25$).
* **Grad-CAM Explainable AI**: Peta atensi visual lesi patologis retina yang diisolasi secara fail-safe.

---

## 9. Katalog REST API v1 Terpadu (53 Endpoints)

Layanan web menyediakan 53 endpoint REST API terstruktur di bawah rute `/api/v1/*`:

1. **Autentikasi & Akun** (`/auth/register`, `/auth/login`, `/auth/me`, `/auth/reset-password`, `/auth/google`, `/auth/google/callback`)
2. **Manajemen Pasien & Profil DM** (`/patients`, `/patients/[id]`, `/patients/[id]/diabetes-profile`, `/diabetes-profiles`)
3. **Alur Skrining Bilateral** (`/screenings`, `/screenings/direct-screen`, `/screenings/[id]`, `/screenings/[id]/images`, `/screenings/[id]/images/[imageId]/url`, `/screenings/[id]/quality-check`, `/screenings/[id]/analyze`, `/screenings/[id]/ai-result`)
4. **Telaah Dokter Spesialis Mata** (`/reviews/pending`, `/reviews/[screeningId]`)
5. **Rekomendasi Medis Perdami** (`/recommendations/[screeningId]`)
6. **Fasilitas Rujukan & Geodesik** (`/facilities`, `/facilities/nearest`, `/facilities/match`)
7. **Surat Pengantar Rujukan (SPK)** (`/referrals`, `/referrals/[id]`)
8. **Jadwal Follow-Up** (`/follow-ups`, `/follow-ups/[id]`)
9. **Riwayat Longitudinal Pasien** (`/history/patient/[patientId]`, `/history/patients/[patientId]`)
10. **Agentic AI Care Companion** (`/care-companion/urgent-check`, `/care-companion/state`, `/care-companion/consultation-summary`, `/care-companion/consultation-summary/[id]/confirm`, `/care-companion/meal-plan/generate`, `/care-companion/meal-plan/replace-meal`, `/care-companion/reminders`, `/care-companion/reminders/[id]`, `/care-companion/progress`, `/care-companion/orchestrator`)
11. **Master Data Nutrisi & Pertanyaan** (`/master/meals`, `/master/meals/[id]`, `/master/questions`, `/master/questions/[id]`)
12. **Verifikasi Legalitas Dokter** (`/doctor-verifications`)
13. **Tata Kelola Model AI** (`/models`, `/models/active`, `/models/[id]`, `/models/[id]/activate`)
14. **Manajemen Pengguna** (`/users`, `/users/[id]`)
15. **Jejak Audit Forensik Non-Repudiation** (`/audit-logs`)
16. **Monitoring Kesehatan Sistem** (`/health`)

---

## 10. Struktur Direktori Repositori Monorepo

```text
retiva-monorepo/
├── .env.example                     # Templat konfigurasi lingkungan pengembangan
├── .env.production.example          # Templat konfigurasi produksi domain HTTPS
├── docker-compose.yml               # Orkestrasi Docker lokal (PostgreSQL, MinIO, AI-Service, Web)
├── docker-compose.prod.yml          # Orkestrasi Docker produksi dengan reverse proxy Nginx SSL
├── setup-ssl.sh                     # Skrip otomatisasi penerbitan sertifikat SSL Let's Encrypt Certbot
├── deploy.sh                        # Skrip deployment mandiri zero-downtime VPS
├── start-docker.bat                 # One-click runner Docker untuk Windows
├── start-local.bat                  # One-click runner mode lokal ringan tanpa Docker
├── package.json                     # Root monorepo workspace scripts
│
├── mobile/                          # Aplikasi Mobile Klien Tenaga Kesehatan (Flutter)
│   ├── pubspec.yaml                 # Dependensi Flutter (http, shared_preferences, image_picker)
│   ├── README.md                    # Dokumentasi lengkap klien mobile Flutter
│   ├── lib/                         # Kode sumber Flutter (Clean Architecture)
│   └── test/                        # 20 pengujian unit & widget antarmuka klinis
│
├── web/                             # Web Portal & Core Backend API Gateway (Next.js 14)
│   ├── app/                         # Next.js 14 App Router & 53 API Controller (/api/v1/*)
│   ├── application/                 # Clean Architecture: Use Cases
│   ├── domain/                      # Clean Architecture: Pure Entities, Rules, & Care Companion
│   ├── infrastructure/              # Adapters: Prisma PostgreSQL, S3 Storage, Security, AI Client
│   ├── prisma/schema.prisma         # 18 Model Skema Relasional Medis Ternormalisasi
│   ├── public/                      # Static assets & retiva-app.apk release binary
│   ├── README.md                    # Dokumentasi subsistem Web & API Gateway
│   └── scripts/                     # Test Suites (test-master.ts, test-care-companion.ts)
│
├── ai-service/                      # Layanan Inferensi Kecerdasan Buatan (FastAPI)
│   ├── app/                         # Routes, Quality Gate OpenCV, Model Loader, Grad-CAM
│   ├── tests/                       # 20 Pengujian Pytest
│   ├── requirements.txt             # Dependensi Python
│   └── README.md                    # Dokumentasi teknis AI microservice
│
├── nginx/                           # Konfigurasi Reverse Proxy Nginx
│   └── conf.d/                      # Template konfigurasi SSL HTTPS & HTTP
│
└── docs/                            # Dokumentasi Medis, Arsitektur, & Keamanan Mendalam
    ├── clinical/                    # Spesifikasi klinis Perdami & formula kendali mutu
    ├── architecture/                # Cetak biru arsitektur sistem
    ├── api/                         # Spesifikasi REST API v1 & openapi.json
    ├── security/                    # Kepatuhan UU PDP & Permenkes No. 24/2022
    └── user-guide/                  # Panduan pengguna nakes & dokter
```

---

## 11. Panduan Instalasi & Eksekusi Sistem (Quickstart)

| Parameter | 🐳 Opsi A: Menggunakan Docker | 💻 Opsi B: Tanpa Docker (Native Local) |
| :--- | :--- | :--- |
| **Kebutuhan RAM** | ~3.5 GB - 6 GB (Docker Engine + 4 Kontainer) | ~1 GB - 1.5 GB (Sangat Ringan) |
| **Instalasi Software** | Cukup Docker Desktop | Node.js (>= 18), Python (>= 3.10), & PostgreSQL |
| **Database** | Otomatis terpasang di kontainer PostgreSQL | PostgreSQL lokal atau Cloud (Neon/Supabase) |
| **Object Storage** | MinIO S3 otomatis dikontainerisasi | Built-in Zero-BLOB Presigned Mock bawaan |
| **Kelebihan** | 100% identik dengan environment produksi | Cepat, hemat resource, debugging instan |

---

## 12. Panduan Deployment Produksi & Setup SSL Otomatis

RETIVA siap dideploy ke server VPS (Ubuntu 22.04 / 24.04 LTS) dengan sertifikat SSL resmi Let's Encrypt:

```bash
# 1. Salin template environment produksi
cp .env.production.example .env.production

# 2. Jalankan Deployment Mandiri
bash deploy.sh

# 3. Aktifkan Sertifikat SSL HTTPS Let's Encrypt
sudo bash setup-ssl.sh
```

---

## 13. Verifikasi Otomatis Menyeluruh (Full-Stack 103/103 Passed)

Platform RETIVA dilengkapi cakupan uji otomatis komprehensif pada seluruh subsistem dengan hasil **100% Pass Rate (103 dari 103 Pengujian Berhasil)**:

```text
==============================================================================
🏁 RETIVA FULL-STACK TEST VERIFICATION SUMMARY
==============================================================================
  1. Web Core API Master Suite (test-master.ts)         : 38 / 38 Passed (100%)
     - Phase 1: Identity, Authorization, NIK 16-digit  (8/8)
     - Phase 2: Zero-BLOB Storage, SHA-256 Checksums   (7/7)
     - Phase 3: AI Model Registry, 5-Class Inference   (5/5)
     - Phase 4: Specialist Review, Perdami Rules       (9/9)
     - Phase 5: Non-Repudiation Audit Trail & Security (9/9)

  2. Agentic AI Care Companion Suite (test-care-companion.ts) : 25 / 25 Passed (100%)
     - Urgent Eye Red-Flag Safety Evaluator (Emergency vs Routine)
     - Post-Consultation State Machine Invariants
     - Budget-Aware Low-GI Indonesian Nutrition Engine
     - Dynamic Meal Replacement & Budget Recalculation
     - Care Companion Orchestrator Action Execution & Audit

  3. Flutter Mobile Client Suite (flutter test)        : 20 / 20 Passed (100%)
     - Clinical Rules, ICDR Mapping & Perdami Intervals
     - 3 Figma State Machine Branches (Normal, Retake, Human Review)
     - Workstation Screens & Interactive Grad-CAM Viewer

  4. FastAPI AI Service Suite (pytest tests)            : 20 / 20 Passed (100%)
     - OpenCV Quality Gate (Blur Laplacian, FOV, Illumination)
     - Reliability Gate (Entropy, Confidence Margin)
     - Medical Safety & Grad-CAM Fail-Safe Execution
     - End-to-End Screening Pipeline & Dynamic Fallback
==============================================================================
  TOTAL FULL-STACK VERIFIED INVARIANTS: 103 / 103 PASSED (100% GREEN)
==============================================================================
```

---

## 14. Kepatuhan Regulasi & Standar Keamanan Medis

1. **Zero-BLOB Storage Invariant**: Basis data relasional PostgreSQL tidak pernah menampung file biner citra. File disimpan di object storage terisolasi dengan penamaan berbasis hash unik.
2. **Presigned HMAC URLs (15 Menit)**: Setiap tampilan citra retina menggunakan tautan presigned berbatas waktu dengan masa kedaluwarsa 15 menit.
3. **Log Audit Non-Repudiation (Permenkes No. 24/2022)**: Setiap tindakan medis dicatat dalam tabel `audit_logs` bersama identitas aktor, NIP/SIP, peran, IP address, dan timestamp berpresisi *microsecond*.
4. **Perlindungan Data Pribadi (UU PDP No. 27/2022)**: Wajib informed consent eksplisit, enkripsi kata sandi menggunakan bcrypt (cost factor 12), dan pemisahan data kredensial dari profil medis.

---

## 15. Panduan Demonstrasi & Skenario Uji Klinis

Juri dapat mengikuti 4 skenario klinis teruji berikut untuk mengevaluasi sistem secara bertahap:

* **Skenario 1 (Cabang A: Normal / Autonomous)**:  
  Unggah foto fundus tajam $\to$ Lolos Quality Gate (Laplacian $\ge 0.40$) $\to$ Hasil Moderate NPDR Derajat 2 $\to$ Rekomendasi rujukan elektif Perdami 3-6 bulan $\to$ Penerbitan SPK rujukan berstandar ICD-10 (`E11.319`).
* **Skenario 2 (Cabang B: Retake Foto / Quality Gate Failure)**:  
  Unggah foto fundus kabur/goyang $\to$ Sistem menolak memprediksi (Laplacian $< 0.40$) $\to$ Muncul kartu edukasi koreksi jarak lensa bagi nakes $\to$ Tombol *Ambil Ulang Foto*.
* **Skenario 3 (Cabang C: Human Review / Reliability Escalation)**:  
  Kasus borderline ($\text{confidence} < 85\%$) $\to$ Sistem menahan hasil dari nakes $\to$ Masuk ke antrean web dokter spesialis Sp.M (`/reviews/pending`) $\to$ Dokter Sp.M mengadjudikasi diagnosis akhir dengan panduan heatmap Grad-CAM interaktif.
* **Skenario 4 (Agentic AI Care Companion)**:  
  Deteksi gejala darurat mata (kilatan cahaya/tirai hitam) seketika memicu alarm rujukan IGD RS Mata $\to$ Edukasi nutrisi harian rendah GI ramah budget IDR pasca-konfirmasi resume dokter spesialis.

---

## 16. Indeks Dokumentasi Lengkap Proyek

* 🌐 **[Dokumentasi Web & Core API Gateway (web/README.md)](web/README.md)**: Arsitektur Next.js 14, 53 REST API endpoints, modul Care Companion, skema Prisma, dan panduan pengujian.
* 📱 **[Dokumentasi Klien Mobile Flutter (mobile/README.md)](mobile/README.md)**: Multi-environment toggle, pemetaan 10 layar Figma, dan workstation klinis nakes.
* 🧠 **[Dokumentasi AI Microservice (ai-service/README.md)](ai-service/README.md)**: Pipeline OpenCV Quality Gate, inferensi EfficientNet-B3 5-kelas, Reliability Gate, dan Grad-CAM.
* 🩺 **[Spesifikasi Klinis & CDSS (docs/clinical/CLINICAL_SPECIFICATION.md)](docs/clinical/CLINICAL_SPECIFICATION.md)**: Konsensus Perdami 2024, skala keparahan ICDR, formula kendali mutu, dan aturan CDSS.
* 🏛️ **[Spesifikasi Arsitektur Sistem (docs/architecture/ARCHITECTURE.md)](docs/architecture/ARCHITECTURE.md)**: Cetak biru Clean Architecture, diagram sekuensial, dan ports & adapters.
* 📜 **[Kontrak API Kanonikal (docs/api-contracts.md)](docs/api-contracts.md)**: Spesifikasi DTO, envelope response, dan integrasi antar subsistem.
* 🧪 **[Laporan Pengujian Terpadu (docs/test-report.md)](docs/test-report.md)**: Log eksekusi dan bukti verifikasi 100% lulus di seluruh stack.
* 🛡️ **[Panduan Keamanan & Regulasi (docs/security/SECURITY_COMPLIANCE.md)](docs/security/SECURITY_COMPLIANCE.md)**: Kepatuhan UU PDP No. 27/2022 & Permenkes No. 24/2022.

---

## 17. Lisensi dan Hak Cipta

RETIVA dikembangkan untuk kompetisi Hackathon dan inovasi transformasi digital kesehatan nasional Indonesia.  
Hak cipta © 2026 Tim Pengembang RETIVA. Seluruh hak cipta dilindungi undang-undang.
