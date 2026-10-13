# RETIVA — Platform Skrining Retinopati Diabetik Nasional

### *Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*


[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture_%2F_Ports_%26_Adapters-0284C7?style=for-the-badge)](docs/architecture/ARCHITECTURE.md)
[![Web & Gateway](https://img.shields.io/badge/Web_Core-Next.js_14_App_Router-000000?style=for-the-badge&logo=next.js)](web)
[![Mobile Client](https://img.shields.io/badge/Mobile_Client-Flutter_3.41_%2F_Dart_3.11-02569B?style=for-the-badge&logo=flutter)](mobile)
[![AI Microservice](https://img.shields.io/badge/AI_Service-FastAPI_%2F_EfficientNet--B3-009688?style=for-the-badge&logo=fastapi)](ai-service)
[![Database](https://img.shields.io/badge/Database-PostgreSQL_16_%2B_Prisma_ORM-336791?style=for-the-badge&logo=postgresql)](web/prisma/schema.prisma)
[![Storage](https://img.shields.io/badge/Storage-Zero--BLOB_S3--Compatible-EA580C?style=for-the-badge&logo=amazons3)](infrastructure/storage)
[![Compliance](https://img.shields.io/badge/Compliance-Permenkes_24%2F2022_%7C_UU_PDP_27%2F2022-4F46E5?style=for-the-badge)](docs/security/SECURITY_COMPLIANCE.md)

---

## 📑 Daftar Isi

1. [Ringkasan Eksekutif &amp; Latar Belakang Klinis](#1-ringkasan-eksekutif--latar-belakang-klinis)
2. [Prinsip Medis &amp; Batasan Keselamatan Klinis](#2-prinsip-medis--batasan-keselamatan-klinis)
3. [Alur Klinis &amp; 3 Cabang State Machine](#3-alur-klinis--3-cabang-state-machine)
4. [Arsitektur Sistem &amp; Komponen Terintegrasi](#4-arsitektur-sistem--komponen-terintegrasi)
5. [Implementasi Klien Mobile Flutter (Figma 1:1 Mapping)](#5-implementasi-klien-mobile-flutter-figma-11-mapping)
6. [Skala Klasifikasi ICDR &amp; Mesin Aturan Perdami/ADA 2024](#6-skala-klasifikasi-icdr--mesin-aturan-perdamiada-2024)
7. [Algoritma AI, Kendali Mutu Citra &amp; Interpretabilitas](#7-algoritma-ai-kendali-mutu-citra--interpretabilitas)
8. [Katalog REST API v1 Terpadu (31 Endpoints)](#8-katalog-rest-api-v1-terpadu-31-endpoints)
9. [Struktur Direktori Repositori Monorepo](#9-struktur-direktori-repositori-monorepo)
10. [Panduan Instalasi &amp; Eksekusi Sistem (Quickstart)](#10-panduan-instalasi--eksekusi-sistem-quickstart)
11. [Verifikasi Otomatis Menyeluruh (Full-Stack 78/78 Passed)](#11-verifikasi-otomatis-menyeluruh-full-stack-7878-passed)
12. [Kepatuhan Regulasi &amp; Standar Keamanan Medis](#12-kepatuhan-regulasi--standar-keamanan-medis)
13. [Panduan Demonstrasi &amp; Skenario Uji Klinis](#13-panduan-demonstrasi--skenario-uji-klinis)
14. [Indeks Dokumentasi Lengkap Proyek](#14-indeks-dokumentasi-lengkap-proyek)
15. [Lisensi dan Hak Cipta](#15-lisensi-dan-hak-cipta)

---

## 1. Ringkasan Eksekutif & Latar Belakang Klinis

**RETIVA** (*Retinopathy Evaluation, Triaging, & Intelligence Vision Architecture*) adalah platform sistem pendukung keputusan klinis (*Clinical Decision Support System* / CDSS) terintegrasi berbasis kecerdasan buatan, kendali mutu citra bilateral (*Quality Gate*), dan tele-adjudikasi *Human-in-the-Loop*. Platform ini dirancang khusus untuk mendesentralisasi penapisan (*screening*) komplikasi mikrovaskular diabetes melitus pada retina mata dari rumah sakit rujukan ke Fasilitas Kesehatan Tingkat Pertama (FKTP / Puskesmas / Klinik Pratama).

### Urgensi Masalah Retinopati Diabetik di Indonesia:

* **Prevalensi Diabetes Melitus**: Menurut *International Diabetes Federation* (IDF) 2021, Indonesia menempati peringkat ke-5 dunia dengan lebih dari **19,5 juta penderita diabetes melitus**, dan diproyeksikan melonjak melebihi 28 juta jiwa pada tahun 2045.
* **Risiko Kebutaan Permanen**: Sekitar 1 dari 3 penderita diabetes akan mengalami retinopati diabetik (DR). Retinopati diabetik merupakan penyebab utama gangguan penglihatan dan kebutaan yang sebenarnya **dapat dicegah hingga 90%** jika dideteksi pada fase awal (No DR / Mild NPDR).
* **Disparitas Tenaga Dokter Spesialis Mata**: Jumlah dokter spesialis mata (Sp.M) di Indonesia hanya berkisar ~3.000 dokter untuk 278 juta penduduk (rasio ~1:92.000, jauh di bawah rekomendasi WHO 1:50.000), dengan lebih dari 65% terkonsentrasi di kota-kota besar pulau Jawa. Akibatnya, jutaan pasien diabetes di daerah perifer tidak pernah mendapatkan pemeriksaan funduskopi tahunan sesuai standar protokol klinis.
* **Solusi RETIVA**: Memfasilitasi tenaga kesehatan di FKTP (perawat, bidan, kader terlatih) untuk melakukan pemotretan funduskopi digital bilateral dengan kendali mutu seketika, inferensi keparahan berstandar ICDR, rekomendasi rujukan deterministik berstandar Perdami/ADA 2024, serta eskalasi otomatis ke dokter spesialis mata jika terjadi ketidakpastian.

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

* **Cabang A: Normal / Autonomous Recommendation**Terjadi saat citra lolos Quality Gate dan model memiliki keyakinan tinggi ($\ge 0.85$ dengan margin $\ge 0.20$). Sistem secara instan menyajikan kartu derajat keparahan ICDR, visualisasi heatmap Grad-CAM, jadwal kontrol rekomendasi Perdami/ADA 2024, dan daftar fasilitas kesehatan rujukan terdekat.
* **Cabang B: Retake Foto (Quality Gate Failure)**Jika citra fundus buram, pencahayaan terlalu gelap/terang, atau bidang pandang retina tidak memenuhi syarat minimal $45^\circ$, AI **menolak melakukan prediksi**. Sistem memberikan umpan balik spesifik kepada tenaga kesehatan di lapangan (misal: "Lensa terlalu dekat", "Pencahayaan kurang seimbang") serta tombol *Ambil Ulang Foto*.
* **Cabang C: Human Review Pending (Reliability Gate Escalation)**
  Jika citra lolos mutu tetapi tingkat keyakinan model berada di bawah ambang batas ($\text{confidence} < 0.85$ atau selisih Top-1 vs Top-2 $< 0.20$), sistem menahan hasil skrining dari nakes dan mengirimkan berkas ke antrean telaah dokter spesialis mata (`/api/v1/reviews/pending`). Dokter Sp.M melakukan tele-adjudikasi dengan bantuan overlay Grad-CAM untuk mengonfirmasi atau mengoreksi derajat diagnosis.

---

## 4. Arsitektur Sistem & Komponen Terintegrasi

RETIVA mengadopsi pola **Clean Architecture (Ports & Adapters / Hexagonal Architecture)** di dalam struktur Monorepo modern. Arsitektur ini menjamin independensi total antara aturan bisnis medis murni (*domain layer*), alur kerja aplikasi (*use cases*), dan antarmuka infrastruktur (*adapters*):

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
                                            (Prisma 18) (MinIO) (JWT/Bcrypt)
```

### Rincian Subsistem Utama:

1. **Aplikasi Mobile Tenaga Kesehatan (`mobile/`)**:
   - Dibangun dengan Flutter (Dart 3.11), mereplikasi 100% rancangan Figma (400 × 854 px) untuk kader dan perawat FKTP.
   - **Strict Network Boundary**: Klien mobile hanya berkomunikasi dengan API Gateway Next.js (`/api/v1/*`), tanpa akses langsung ke basis data maupun layanan AI.
   - Dilengkapi resolusi host otomatis (Android Emulator `10.0.2.2:3000`, Desktop/iOS `localhost:3000`, atau IP LAN) dan mekanisme cerdas fallback demo offline.
2. **Web Portal & API Gateway Terpadu (`web/`)**:
   - Next.js 14 App Router, React 18, TypeScript (Strict Mode).
   - Menyediakan 31 endpoint REST API terstruktur, dashboard manajemen klinis bagi dokter spesialis mata, direktori faskes, dan log audit kepatuhan.
   - Desain antarmuka web klinis berbasis Vanilla CSS murni tanpa pustaka eksternal pihak ketiga yang berat.
3. **Layanan Inferensi Kecerdasan Buatan (`ai-service/`)**:
   - FastAPI microservice (Python 3.11+), Uvicorn ASGI server (Port 8003).
   - Multi-Format Model Loader (PyTorch `.pt`/`.pth`, ONNX `.onnx`, TensorFlow Lite `.tflite`, dan Heuristic Fallback Engine).
   - Pipeline evaluasi kendali mutu OpenCV dan visualisasi peta atensi Grad-CAM dengan isolasi galat (*fail-safe execution*).
4. **Basis Data & ORM Relasional (`web/prisma/`)**:
   - PostgreSQL 16 dengan Prisma ORM mencakup 18 model relasional medis ternormalisasi (User, Patient, DiabetesProfile, Screening, FundusImage, ScreeningResult, SpecialistReview, ClinicalRecommendation, ReferralFacility, ReferralLetter, FollowUpSchedule, ModelMetadata, AuditLog, dll.).
5. **Penyimpanan Citra Medis Objek (`Zero-BLOB Storage`)**:
   - S3-Compatible Object Storage (AWS S3, MinIO, atau Cloudflare R2).
   - **Zero-BLOB Invariant**: Basis data relasional tidak pernah menyimpan biner/BLOB citra. Citra hanya disimpan di bucket privat terisolasi, diidentifikasi melalui storage key unik dan hash integritas SHA-256 (64 hex).
   - Seluruh akses citra menggunakan *presigned time-limited URL* dengan masa kedaluwarsa 15 menit.

---

## 5. Implementasi Klien Mobile Flutter (Figma 1:1 Mapping)

Aplikasi mobile dirancang presisi mengikuti rancangan desain Figma (400 × 854 px) yang mencakup 3 cabang alur klinis utama:

| Layar / Frame Figma                       | Deskripsi Fungsional Medis                                                                                                                              | File Implementasi Flutter                                                                                     |
| :---------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------ |
| **`01. Homepage`**                | Beranda operasional nakes: ringkasan metrik skrining harian, panduan Perdami 2024, tombol skrining bilateral, dan navigasi cepat.                       | [`home_screen.dart`](mobile/lib/presentation/screens/home_screen.dart)                                       |
| **`02 & 03. Upload I & II`**      | Pemilihan mata bilateral (Mata Kanan`OD` vs Mata Kiri `OS`), retikel optik sudut pandang 45° FOV, dan integrasi kamera/galeri.                     | [`upload_fundus_screen.dart`](mobile/lib/presentation/screens/upload_fundus_screen.dart)                     |
| **`04 & 05. Kualitas Jelas`**     | Animasi pemindaian kendali mutu: Ketajaman Laplacian (`>= 0.40`), Pencahayaan Kanal Hijau, dan Cakupan FOV Makula.                                    | [`quality_scanning_screen.dart`](mobile/lib/presentation/screens/quality_scanning_screen.dart)               |
| **`05. Kualitas Buram (Retake)`** | **Branch Retake**: Penolakan citra buram/gelap, metrik kegagalan mutu, panduan koreksi jarak lensa bagi nakes, dan tombol retake.                 | [`quality_failed_retake_screen.dart`](mobile/lib/presentation/screens/quality_failed_retake_screen.dart)     |
| **`06–09. Analisis AI`**         | Tahapan inferensi konvolusi EfficientNet-B3 5-Class ICDR dan evaluasi ambang batas keandalan (*Reliability Gate*).                                    | [`ai_analyzing_screen.dart`](mobile/lib/presentation/screens/ai_analyzing_screen.dart)                       |
| **`10 & 11. Human Review`**       | **Branch Human Review**: Penanganan kasus reliabilitas *borderline* (< 85%), sistem menahan prediksi dan mengalihkan ke antrean spesialis Sp.M. | [`human_review_pending_screen.dart`](mobile/lib/presentation/screens/human_review_pending_screen.dart)       |
| **`11–13. Hasil & Grad-CAM`**    | Kartu derajat ICDR (Derajat 0–4), skor keyakinan, diagram distribusi probabilitas, dan penampil interaktif Heatmap Grad-CAM.                           | [`screening_result_screen.dart`](mobile/lib/presentation/screens/screening_result_screen.dart)               |
| **`14. Tindakan Lanjutan`**       | Rekomendasi interval Perdami/ADA 2024 & pencocokan faskes rujukan sekunder/tersier terdekat (Haversine & BPJS Aktif).                                   | [`clinical_recommendation_screen.dart`](mobile/lib/presentation/screens/clinical_recommendation_screen.dart) |
| **`15 & 16. Penerbitan SPK`**     | Penerbitan Surat Pengantar Rujukan (SPK) elektronik resmi berstandar ICD-10 (`E11.319`) siap cetak/unduh PDF.                                         | [`referral_letter_screen.dart`](mobile/lib/presentation/screens/referral_letter_screen.dart)                 |
| **`17. Riwayat Pasien`**          | Pencarian NIK 16 digit pasien dan timeline visual longitudinal progresivitas lesi retina tahun ke tahun.                                                | [`patient_history_screen.dart`](mobile/lib/presentation/screens/patient_history_screen.dart)                 |

---

## 6. Skala Klasifikasi ICDR & Mesin Aturan Perdami/ADA 2024

RETIVA mengadopsi standar internasional *International Clinical Diabetic Retinopathy* (ICDR) 5 tingkat dan menerjemahkannya ke rekomendasi klinis deterministik berbasis konsensus Perdami dan *American Diabetes Association* (ADA) 2024:

| Derajat ICDR | Istilah Medis           | Temuan Patologis Khas Funduskopi                                                                                             | Risiko Progresivitas | Tindakan & Rekomendasi Alur (Perdami & ADA 2024)                                                                                       |   Urgensi   | Kode ICD-10 |
| :----------: | :---------------------- | :--------------------------------------------------------------------------------------------------------------------------- | :------------------: | :------------------------------------------------------------------------------------------------------------------------------------- | :----------: | :---------: |
| **0** | **No DR**         | Tidak ditemukan lesi mikroretina; makula dan diskus optikus tenang.                                                          |     < 5% / tahun     | Skrining ulang rutin tahunan (12 bulan) di FKTP; kendali glikemik & HbA1c standar.                                                     |   `LOW`   |  `E11.9`  |
| **1** | **Mild NPDR**     | Mikroaneurisma terisolasi fokal; tanpa eksudat atau perdarahan luas.                                                         |  5% – 15% / tahun  | Monitoring berkala 6–12 bulan di FKTP; konseling gaya hidup dan optimalisasi terapi DM.                                               |   `LOW`   | `E11.319` |
| **2** | **Moderate NPDR** | Mikroaneurisma multipel, perdarahan bercak (*dot-blot*), *cotton-wool spots*, belum memenuhi kriteria 4-2-1.             |  15% – 27% / tahun  | Rujukan elektif ke Dokter Spesialis Mata (Sp.M) di FKRTL dalam kurun 3–6 bulan; evaluasi funduskopi lanjutan.                         |  `MEDIUM`  | `E11.319` |
| **3** | **Severe NPDR**   | Memenuhi kriteria**4-2-1**: (a) Perdarahan berat 4 kuadran; (b) *Venous beading* 2 kuadran; atau (c) IRMA 1 kuadran. |  50% – 75% / tahun  | **Rujukan Cepat (2–4 minggu)** ke Spesialis Retina FKRTL; evaluasi fotokoagulasi laser argon panretina (PRP).                   |   `HIGH`   | `E11.319` |
| **4** | **PDR**           | Neovaskularisasi retina/diskus (NVD/NVE), perdarahan vitreus pra-retina, atau ablasio retina traksional.                     |    > 75% / tahun    | **Rujukan Darurat (< 1–2 minggu)** ke Pusat Rujukan Mata Tersier; intervensi anti-VEGF intravitreal atau vitreoretinal surgery. | `CRITICAL` | `E11.359` |

---

## 7. Algoritma AI, Kendali Mutu Citra & Interpretabilitas

```text
                        PIPELINE KOMPUTASI CITRA FUNDUS RETIVA
                        ======================================
1. Citra Masukan (RGB) ──> 2. Quality Gate (OpenCV) ──> 3. Normalisasi (300x300)
                                    │                           │
                            [Gagal Mutu: Abstain]               v
                                                        4. EfficientNet-B3 (5 Kelas)
                                                                │
                                                                v
                                                        5. Reliability Gate
                                                          (Conf >= 0.85 & Margin >= 0.20)
                                                                │
                                                 ┌──────────────┴──────────────┐
                                                 │                             │
                                         [Lolos Keandalan]             [Gagal Keandalan]
                                                 │                             │
                                                 v                             v
                                         6. Hasil Otomatis             7. Human Review
                                                 │                             │
                                                 └──────────────┬──────────────┘
                                                                │
                                                                v
                                                 8. Grad-CAM Attention Heatmap
                                                    (Visualisasi Lokalisasi Lesi)
```

### 1. Evaluasi Kendali Mutu Citra (Quality Gate):

* **Indeks Ketajaman Laplacian**: Dihitung menggunakan varian operator Laplace pada kanal abu-abu:

  $$
  \text{Blur Score} = \text{Var}(\nabla^2 I) \ge 0.40
  $$

  Nilai $< 0.40$ mengindikasikan citra *out-of-focus* atau gerakan kamera, memicu instruksi penolakan seketika.
* **Keseimbangan Pencahayaan Kanal Hijau (*Green Channel*)**:
  Kanal hijau memuat kontras pembuluh darah retina tertinggi. Rata-rata intensitas pencahayaan diwajibkan berada pada rentang **15% – 85%** dari histogram dinamis untuk menghindari *underexposure* (gelap) atau *overexposure* (silau).
* **Cakupan Bidang Pandang Retina (*Circular FOV Mask*)**:
  Deteksi kontur lingkaran optik retina memastikan bidang pandang $\ge 45^\circ$, mencakup area makula lutea dan diskus optikus.

### 2. Arsitektur Model Deep Learning:

* **EfficientNet-B3 Backbone**: Model konvolusional mutakhir dengan resolusi masukan $300 \times 300$ piksel, dioptimalkan untuk mengekstraksi fitur mikroaneurisma kecil ($10 \text{--} 50\ \mu\text{m}$) hingga perdarahan vitreus luas.
* **Multi-Format Model Loader**: Sistem secara dinamis mendukung pemuatan bobot model PyTorch (`.pt`/`.pth`), Open Neural Network Exchange (`.onnx`), TensorFlow Lite (`.tflite`), dan *Dynamic Heuristic Engine* sebagai fallback evaluasi dev tanpa GPU.

### 3. Peta Atensi Grad-CAM (*Explainable AI*):

* *Gradient-weighted Class Activation Mapping* (Grad-CAM) menghitung gradien skor kelas target terhadap *feature maps* lapisan konvolusional terakhir.
* Heatmap atensi diproyeksikan di atas citra fundus asli untuk memvisualisasikan area retina yang mendasari keputusan model (misal: klaster mikroaneurisma di makula), memberikan transparansi penuh kepada dokter spesialis mata saat melakukan penelaahan.

---

## 8. Katalog REST API v1 Terpadu (37 Endpoints)

REST API v1 diimplementasikan secara terstruktur di bawah rute `/api/v1/*` dengan wewenang *Role-Based Access Control* (RBAC):

| Domain Modul                          | Rute Endpoint                             |    Metode HTTP    |   Hak Akses   | Deskripsi Fungsional Medis                                                |
| :------------------------------------ | :---------------------------------------- | :----------------: | :-----------: | :------------------------------------------------------------------------ |
| **Autentikasi & Akun**          | `/api/v1/auth/register`                 |      `POST`      |    Public    | Registrasi akun nakes / dokter / administrator baru.                      |
|                                       | `/api/v1/auth/login`                    |      `POST`      |    Public    | Login dengan verifikasi password hash bcrypt dan penerbitan JWT.          |
|                                       | `/api/v1/auth/me`                       |      `GET`      | Authenticated | Mendapatkan data profil dan wewenang pengguna yang sedang aktif.          |
| **Manajemen Pasien**            | `/api/v1/patients`                      | `GET` / `POST` | Nakes / Sp.M | Katalog pasien (pencarian NIK/nama) & pendaftaran pasien baru.            |
|                                       | `/api/v1/patients/[id]`                 | `GET` / `PUT` | Nakes / Sp.M | Rincian data demografis pasien dan riwayat medis terkait.                 |
| **Profil Diabetes Melitus**     | `/api/v1/diabetes-profiles`             | `GET` / `POST` | Nakes / Sp.M | Riwayat metabolik (HbA1c, durasi DM, tipe diabetes, terapi).              |
|                                       | `/api/v1/diabetes-profiles/[id]`        | `GET` / `PUT` | Nakes / Sp.M | Pembaruan data tekanan darah dan riwayat glikemik.                        |
| **Alur Skrining Bilateral**     | `/api/v1/screenings`                    | `GET` / `POST` | Nakes / Sp.M | Inisiasi alur skrining baru dengan informed consent UU PDP.               |
|                                       | `/api/v1/screenings/[id]`               |      `GET`      | Nakes / Sp.M | Detail status skrining, kedua citra mata (OD/OS), dan hasil CDSS.         |
|                                       | `/api/v1/screenings/[id]/images`        |      `POST`      | Nakes / Sp.M | Registrasi metadata citra fundus dan verifikasi checksum SHA-256.         |
|                                       | `/api/v1/screenings/[id]/quality`       |      `POST`      | Nakes / Sp.M | Eksekusi evaluasi Quality Gate bilateral (ketajaman, kontras, FOV).       |
|                                       | `/api/v1/screenings/[id]/analyze`       |      `POST`      | Nakes / Sp.M | Permintaan inferensi model AI 5 kelas dan evaluasi Reliability Gate.      |
|                                       | `/api/v1/screenings/direct-screen`      |      `POST`      | Nakes / Sp.M | **Unified Endpoint**: Upload citra bilateral & inferensi langsung.  |
|                                       | `/api/v1/screenings/[id]/complete`      |      `POST`      | Nakes / Sp.M | Finalisasi alur skrining dan penguncian rekam medik.                      |
| **Telaah Dokter Spesialis**     | `/api/v1/reviews/pending`               |      `GET`      |  Dokter Sp.M  | Antrean skrining dengan keandalan rendah atau kasus borderline.           |
|                                       | `/api/v1/reviews/[id]`                  | `GET` / `POST` |  Dokter Sp.M  | Formulir ajudikasi resmi dokter spesialis mata (konfirmasi/override).     |
| **Rekomendasi Medis**           | `/api/v1/recommendations`               |      `POST`      | Nakes / Sp.M | Evaluasi aturan deterministik Perdami & ADA 2024.                         |
|                                       | `/api/v1/recommendations/[screeningId]` |      `GET`      | Nakes / Sp.M | Mengambil lembar rekomendasi dan interval kontrol terjadwal.              |
| **Faskes Rujukan & BPJS**       | `/api/v1/facilities`                    | `GET` / `POST` | Nakes / Sp.M | Direktori RS rujukan mata beserta koordinat dan status BPJS.              |
|                                       | `/api/v1/facilities/nearest`            |      `GET`      | Nakes / Sp.M | Pencarian faskes terdekat berbasis kalkulasi geodesik Haversine.          |
| **Surat Pengantar Rujukan**     | `/api/v1/referrals`                     | `GET` / `POST` | Nakes / Sp.M | Penerbitan dan pelacakan Surat Pengantar Rujukan (SPK) ICD-10.            |
|                                       | `/api/v1/referrals/[id]`                | `GET` / `PUT` | Nakes / Sp.M | Pembaruan status kehadiran pasien di fasilitas rujukan.                   |
| **Jadwal Kontrol Follow-Up**    | `/api/v1/follow-ups`                    | `GET` / `POST` | Nakes / Sp.M | Penjadwalan kontrol berkala di FKTP atau FKRTL.                           |
|                                       | `/api/v1/follow-ups/[id]`               |      `PUT`      | Nakes / Sp.M | Konfirmasi kehadiran kontrol atau penyesuaian jadwal pasien.              |
| **Riwayat Longitudinal**        | `/api/v1/history/patient/[id]`          |      `GET`      | Nakes / Sp.M | Timeline riwayat funduskopi multi-tahun untuk evaluasi lesi retina.       |
|                                       | `/api/v1/history/patients/[id]`         |      `GET`      | Nakes / Sp.M | Alias jamak untuk kompatibilitas backward mobile client.                  |
| **Tata Kelola Model AI**        | `/api/v1/models`                        | `GET` / `POST` | Admin / Sp.M | Registrasi versi model (bobot hash, arsitektur, parameter).               |
|                                       | `/api/v1/models/active`                 |      `GET`      | Authenticated | Mengambil metadata model inferensi yang sedang aktif bertugas.            |
|                                       | `/api/v1/models/[id]/activate`          |      `POST`      | Administrator | Pergantian versi model inferensi aktif secara dinamis.                    |
| **Monitoring Sistem**           | `/api/v1/health`                        |      `GET`      |    Public    | Health check layanan web gateway, database, dan AI service.               |
| **Jejak Audit Non-Repudiation** | `/api/v1/audit-logs`                    |      `GET`      | Administrator | Log audit forensik mencatat identitas aktor, IP, peran, dan riwayat aksi. |

### Contoh Permintaan & Respons Endpoint Terpadu (`POST /api/v1/screenings/direct-screen`):

```json
// Request Body
{
  "patientId": "pat_clx9876543210",
  "eyePosition": "OD",
  "imageKey": "fundus/2026/OD_pat_clx9876543210.jpg",
  "imageHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}

// Response Body (200 OK)
{
  "success": true,
  "screeningId": "scr_clx1234567890",
  "qualityGate": {
    "passed": true,
    "blurScore": 0.88,
    "illumination": 0.72,
    "fovCovered": true
  },
  "inference": {
    "severityGrade": 2,
    "severityLabel": "Moderate NPDR",
    "confidence": 0.94,
    "margin": 0.38,
    "requiresHumanReview": false
  },
  "recommendation": {
    "action": "RUJUK_SPESIALIS",
    "intervalMonths": 3,
    "urgency": "MEDIUM",
    "icd10": "E11.319"
  }
}
```

---

## 9. Struktur Direktori Repositori Monorepo

```text
retiva-monorepo/
├── .env.example                     # Templat variabel lingkungan sistem terpadu
├── docker-compose.yml               # Orkestrasi Docker (PostgreSQL, MinIO, AI-Service, Web)
├── package.json                     # Root monorepo workspace scripts
├── tsconfig.json                    # Konfigurasi TypeScript global
│
├── mobile/                          # Aplikasi Mobile Klien Tenaga Kesehatan (Flutter)
│   ├── pubspec.yaml                 # Dependensi Flutter (http, shared_preferences, image_picker)
│   ├── analysis_options.yaml        # Konfigurasi linter Dart (0 errors / 0 warnings)
│   ├── README.md                    # Dokumentasi operasional klien mobile
│   ├── lib/
│   │   ├── main.dart                # Entrypoint aplikasi, ThemeData klinis, navigasi
│   │   ├── core/
│   │   │   ├── constants/           # ApiConstants (resolusi host), AppColors (token Figma)
│   │   │   ├── network/             # ApiClient (HTTP gateway handler & mock fallback)
│   │   │   └── utils/               # ClinicalHelpers (ICDR 5-class mapping & Perdami 2024)
│   │   ├── data/models/             # UserModel, PatientModel, ScreeningResultModel
│   │   └── presentation/
│   │       ├── widgets/             # BrandHeader v1.0, CustomButton, QualityIndicatorTile, GradCamViewer
│   │       └── screens/             # 10 Layar implementasi 1:1 desain Figma (Normal, Retake, Human Review)
│   └── test/
│       ├── clinical_workflow_test.dart # Pengujian unit aturan klinis & 3 cabang state machine (8 test)
│       └── widget_screens_test.dart    # Pengujian rendering interaktif seluruh widget screen (8 test)
│
├── web/                             # Web Portal & Core Backend API Gateway (Next.js 14)
│   ├── app/                         # Next.js 14 App Router & 31 API Controller (/api/v1/*)
│   ├── application/                 # Clean Architecture: Use Cases (Auth, Patient, Screening, Referral)
│   ├── domain/                      # Clean Architecture: Pure Entities (User, Patient, Screening, Rules Engine)
│   ├── infrastructure/              # Adapters: Prisma PostgreSQL, S3 Storage, Bcrypt, JWT, Rate Limiter
│   ├── components/                  # UI Web Klinis (Dashboard, Review, Direktori, Tata Kelola)
│   ├── prisma/schema.prisma         # 18 Model Skema Relasional Medis Ternormalisasi
│   └── scripts/test-master.ts       # Unified Master Test Suite (38 Architectural Invariants)
│
├── ai-service/                      # Layanan Inferensi Kecerdasan Buatan (FastAPI)
│   ├── app/
│   │   ├── api/routes.py            # Rute REST AI (/quality, /predict, /screen, /gradcam)
│   │   ├── models/model_loader.py   # Multi-Format Model Loader (PyTorch, ONNX, TFLite, Dynamic Fallback)
│   │   └── services/                # Quality Gate OpenCV, Reliability Gate, Grad-CAM attention
│   ├── tests/                       # Pytest test suite (20 pengujian unit & keselamatan medis)
│   ├── Dockerfile                   # Kontainerisasi AI microservice
│   └── requirements.txt             # Dependensi Python (FastAPI, OpenCV, NumPy, Pillow, Pytest)
│
└── docs/                            # Dokumentasi Medis, Arsitektur, & Keamanan Mendalam
    ├── clinical/CLINICAL_SPECIFICATION.md # Konsensus Perdami & ADA 2024, formula mutu, aturan CDSS
    ├── architecture/ARCHITECTURE.md       # Cetak biru Clean Architecture, diagram sekuensial, ports & adapters
    ├── api/API_V1.md                      # Dokumentasi teknis 31 endpoint REST API v1
    ├── api/openapi.json                   # Spesifikasi standar OpenAPI 3.0 (Swagger/Postman ready)
    ├── security/SECURITY_COMPLIANCE.md    # Analisis pemenuhan UU PDP No. 27/2022 & Permenkes No. 24/2022
    └── user-guide/USER_GUIDE.md           # Panduan pengguna nakes Puskesmas & dokter spesialis mata
```

---

## 10. Panduan Instalasi & Eksekusi Sistem (Quickstart)

Platform RETIVA mendukung dua mode eksekusi: **Menggunakan Docker** (otomatis & isolasi penuh) dan **Tanpa Docker / Native Local** (ringan, hemat RAM & responsif untuk pengembangan).

| Parameter | 🐳 Opsi A: Menggunakan Docker | 💻 Opsi B: Tanpa Docker (Native Local) |
| :--- | :--- | :--- |
| **Kebutuhan RAM** | ~3.5 GB - 6 GB (Docker Engine + 4 Kontainer) | ~1 GB - 1.5 GB (Sangat Ringan) |
| **Instalasi Software** | Cukup Docker Desktop | Node.js, Python, & PostgreSQL (Lokal/Cloud) |
| **Database** | Otomatis terpasang di kontainer PostgreSQL | PostgreSQL lokal (Port 5432) atau Cloud (Neon/Supabase) |
| **Object Storage** | MinIO S3 otomatis dikontainerisasi | Built-in Zero-BLOB Presigned Mock (tanpa perlu MinIO) |
| **Kelebihan** | 100% identik dengan environment produksi | Cepat, hemat resource, debugging instan |

---

### 10.1 Prasyarat Sistem

* **Node.js**: Versi `>= 18.x` (Disarankan Node.js v20 LTS atau v22 LTS)
* **Python**: Versi `>= 3.10` (Disarankan Python 3.11+)
* **Docker & Docker Compose**: (Wajib jika memilih Opsi A)
* **Flutter SDK**: Versi `>= 3.10.0` (Opsional, untuk klien mobile tenaga kesehatan)

---

### 10.2 OPSI A: Menjalankan Menggunakan Docker (Rekomendasi Produksi & Evaluasi)

Seluruh 4 subsistem (PostgreSQL 16, MinIO Storage, FastAPI AI Service, dan Next.js Web) akan otomatis diorkestrasi dalam jaringan kontainer terisolasi.

#### Cara 1: One-Click Runner (Windows)
Cukup klik dua kali file **`start-docker.bat`** di direktori utama repositori. Skrip ini akan otomatis menyiapkan file environment, menyalakan seluruh kontainer, dan menampilkan status kesehatan server.

#### Cara 2: Melalui Terminal / CLI
```bash
# 1. Salin konfigurasi environment
cp .env.example web/.env

# 2. Nyalakan seluruh layanan kontainer di background
docker compose up -d

# 3. Periksa status kesehatan kontainer
docker compose ps

# 4. Pantau log secara langsung (opsional)
docker compose logs -f
```

#### URL Layanan Docker Aktif:
* 🌐 **Web Portal & Core API Gateway**: `http://localhost:3000`
* 🤖 **FastAPI AI Microservice**: `http://localhost:8003` (Dokumentasi Interaktif: `http://localhost:8003/docs`)
* 🗄️ **MinIO S3 Console**: `http://localhost:9001` (User: `minioadmin`, Password: `minioadminpassword`)

#### Menghentikan Layanan Docker:
```bash
docker compose down
```

---

### 10.3 OPSI B: Menjalankan Tanpa Docker (Native Local Mode — Ringan & Cepat)

Mode ini ideal apabila komputer Anda memiliki RAM terbatas atau tidak memiliki Docker Desktop.

#### 1. Persiapan Database PostgreSQL
Pilih salah satu dari dua cara berikut:
* **Pilihan 1 (Paling Mudah & Hemat Resource — Rekomendasi):** Gunakan cloud PostgreSQL gratis seperti [Neon.tech](https://neon.tech) atau [Supabase](https://supabase.com). Anda akan langsung mendapatkan URL koneksi tanpa menginstal server apa pun di laptop.
* **Pilihan 2:** Jalankan PostgreSQL lokal di Windows (default port `5432`).

#### 2. Konfigurasi Environment (`web/.env`)
Salin templat `.env.example` ke `web/.env`:
```bash
cp .env.example web/.env
```
Buka file `web/.env` dan pastikan `DATABASE_URL` sesuai dengan database Anda, serta `AI_SERVICE_URL` mengarah ke port 8003:
```env
# Contoh jika memakai Cloud Neon / Supabase:
DATABASE_URL="postgresql://user:password@ep-sample-pool.neon.tech/retiva_db?sslmode=require"

# Atau jika memakai PostgreSQL lokal di komputer:
DATABASE_URL="postgresql://retiva:retivapassword@localhost:5432/retiva_db?schema=public"

# URL AI Service FastAPI
AI_SERVICE_URL="http://localhost:8003"
```

#### 3. Cara 1: One-Click Runner Tanpa Docker (Windows)
Cukup klik dua kali file **`start-local.bat`** di direktori utama repositori.
Skrip ini akan otomatis:
1. Memvalidasi keberadaan `web/.env`.
2. Menjalankan **FastAPI AI Service** di port 8003 pada jendela terminal terpisah.
3. Menjalankan **Next.js Web Portal** di port 3000 pada jendela terminal terpisah.

---

#### 4. Cara 2: Eksekusi Manual per Layanan di Terminal

Jika Anda ingin menjalankan atau men-debug masing-masing terminal secara manual:

##### 🟢 Terminal 1: Inisialisasi Database & Prisma (Hanya Sekali di Awal)
```bash
cd web
npm install
npx prisma generate
npx prisma db push
```

##### 🤖 Terminal 2: Menjalankan AI Microservice (FastAPI — Port 8003)
```bash
cd ai-service

# Buat & aktifkan virtual environment Python
python -m venv .venv

# Windows:
.venv\Scripts\activate
# Linux / macOS:
source .venv/bin/activate

# Instal dependensi Python
pip install -r requirements.txt

# Jalankan server inferensi AI
uvicorn app.main:app --host 127.0.0.1 --port 8003 --reload
```
* Layanan AI aktif di: `http://localhost:8003` (Swagger Docs: `http://localhost:8003/docs`)

##### 🌐 Terminal 3: Menjalankan Web Portal & Gateway (Next.js 14 — Port 3000)
```bash
cd web
npm run dev
```
* Layanan Web aktif di: `http://localhost:3000`

##### 📱 Terminal 4: Menjalankan Aplikasi Mobile Nakes Flutter (Opsional)
```bash
cd mobile

# Unduh dependensi Flutter
flutter pub get

# Jalankan di Google Chrome / Windows Desktop / Emulator:
flutter run -d chrome
```

> ℹ️ **Catatan Object Storage pada Mode Lokal:** Modul [`s3-compatible.storage.ts`](web/infrastructure/storage/s3-compatible.storage.ts) memiliki adaptor Zero-BLOB presigned mock bawaan, sehingga alur skrining funduskopi dan verifikasi checksum tetap berjalan normal **tanpa perlu menginstal MinIO** secara lokal.

---

## 11. Verifikasi Otomatis Menyeluruh (Full-Stack 78/78 Passed)

Platform RETIVA dilengkapi cakupan uji otomatis komprehensif pada ketiga subsistem utama dengan hasil **100% Pass Rate (78 dari 78 Pengujian Berhasil)**:

```bash
# 1. Jalankan Pengujian Master Web Invariants (38 Invariants)
cd web && npx tsx scripts/test-master.ts

# 2. Jalankan Pengujian Flutter Mobile Client (20 Tests)
cd mobile && flutter test

# 3. Jalankan Pengujian FastAPI AI Service (20 Tests)
cd ai-service && python -m pytest tests
```

### Rangkuman Hasil Verifikasi Pengujian:

```text
==============================================================================
🏁 RETIVA FULL-STACK TEST VERIFICATION SUMMARY
==============================================================================
  1. Web Core API Master Suite (test-master.ts) : 38 / 38 Passed (100%)
     - Phase 1: Identity, Authorization, NIK 16-digit & Demographics  (8/8)
     - Phase 2: Zero-BLOB Storage, SHA-256 Checksums, Quality Gate    (7/7)
     - Phase 3: AI Model Registry, 5-Class Inference, Reliability     (5/5)
     - Phase 4: Specialist Review, Perdami Rules, Geodesic Referrals  (9/9)
     - Phase 5: Non-Repudiation Audit Trail, Model Governance & Sec   (9/9)

  2. Flutter Mobile Client Suite (flutter test) : 20 / 20 Passed (100%)
     - Clinical Rules, ICDR Mapping & Perdami Intervals               (4/4)
     - 3 Figma State Machine Branches (Normal, Retake, Human Review)  (4/4)
     - Interactive Healthcare Professional Screen Widget Tests        (12/12)
       * Konsol Nakes & Shift Card, Intake Pasien Baru NIK 16-digit
       * Grad-CAM Workstation: Pinch-to-zoom 4.5x, Opasitas, Grid Anatomi
       * Matriks Lesi Mikrovaskular, Konsultasi Tele-Oftalmologi Sp.M
       * SPK Rujukan Resmi Kop Dinkes, Tanda Vital, Validasi BSrE & PDF
       * Direktori Pasien, Filter Risiko HbA1c & Timeline Longitudinal

  3. FastAPI AI Service Suite (pytest tests)     : 20 / 20 Passed (100%)
     - OpenCV Quality Gate (Blur Laplacian, FOV, Illumination)        (5/5)
     - Reliability Gate (Entropy, Confidence Margin)                  (4/4)
     - Medical Safety & Grad-CAM Fail-Safe Execution                  (3/3)
     - End-to-End Screening Pipeline & Dynamic Fallback               (8/8)
==============================================================================
  TOTAL FULL-STACK VERIFIED INVARIANTS: 78 / 78 PASSED (100% GREEN)
==============================================================================
```

---

## 12. Kepatuhan Regulasi & Standar Keamanan Medis

1. **Prinsip Nol-Penyimpanan Citra di Database (Zero-BLOB Storage Invariant)**:Basis data relasional PostgreSQL tidak pernah menampung file biner citra. File disimpan di object storage terisolasi dengan penamaan berbasis hash partisi unik.
2. **Tautan Akses Berbatas Waktu (Presigned HMAC URLs)**:Setiap tampilan citra retina pada portal dokter menggunakan URL presigned bertanda tangan kriptografis dengan masa kedaluwarsa 15 menit, mencegah kebocoran tautan publik.
3. **Log Audit Non-Repudiation (Tak Terbantahkan)**:Setiap aksi klinis (pengambilan foto, penilaian mutu, inferensi AI, perubahan derajat oleh dokter spesialis, hingga penerbitan rujukan) dicatat dalam tabel `audit_logs` bersama identitas pengguna, NIP/SIP, peran, alamat IP, dan catatan waktu berpresisi *microsecond*. Memenuhi ketentuan **Permenkes No. 24 Tahun 2022 tentang Rekam Medis Elektronik**.
4. **Kepatuhan Perlindungan Data Pribadi (UU PDP No. 27/2022)**:Pencatatan data sensitif kesehatan pasien dilindungi dengan *informed consent* bilateral eksplisit, enkripsi kata sandi menggunakan bcrypt (*cost factor 12*), dan pemisahan data kredensial dari profil medis.
5. **Pertahanan Berlapis (Defense-in-Depth)**:
   Penerapan HTTP Security Headers tingkat rumah sakit (*Content-Security-Policy*, *Strict-Transport-Security*, *X-Frame-Options DENY*, *X-Content-Type-Options nosniff*), serta *in-memory sliding window rate limiter* untuk menangkal serangan brute-force.

---

## 13. Panduan Demonstrasi & Skenario Uji Klinis

Bagi dewan juri, penilai, atau evaluator yang ingin mendemokan keunggulan klinis RETIVA, berikut adalah 3 skenario demonstrasi utama:

### Skenario 1: Skrining Normal & Rekomendasi Mandiri (Cabang A)

1. Buka aplikasi Flutter Mobile atau Web Portal (`http://localhost:3000`).
2. Masukkan NIK 16 digit pasien baru dan pilih pemeriksaan mata bilateral (**OD / Mata Kanan**).
3. Pilih foto fundus berkualitas tajam.
4. Sistem memverifikasi ketajaman Laplacian ($\ge 0.40$), menjalankan inferensi EfficientNet-B3, dan menampilkan hasil **Moderate NPDR (Derajat 2)** dengan keyakinan 94%.
5. Sistem menerbitkan rekomendasi rujukan elektif 3–6 bulan ke RS terdekat berbasis jarak geodesik Haversine serta menerbitkan lembar rujukan ICD-10 (`E11.319`).

### Skenario 2: Simulasi Penolakan Citra Buram / Quality Gate (Cabang B)

1. Pada layar pemotretan, unggah citra yang sengaja dikaburkan atau foto non-retina (simulasi *out-of-focus*).
2. Sistem secara instan menolak inferensi dengan status **Kualitas Buram** (Laplacian Score $< 0.40$).
3. Layar menampilkan kartu edukasi nakes: "Kamera terlalu bergetar atau jarak lensa belum tepat" serta tombol **Ambil Ulang Foto**. AI menolak memprediksi demi keselamatan pasien (*Reliability Before Prediction*).

### Skenario 3: Simulasi Kasus Borderline & Tele-Adjudikasi Dokter Sp.M (Cabang C)

1. Unggah citra dengan variasi lesi borderline (simulasi confidence $< 85\%$).
2. Klien mobile menampilkan status **Human Review: Menunggu Telaah Dokter Spesialis Mata**.
3. Buka Web Portal dokter (`/reviews/pending`), dokter spesialis memeriksa citra dengan overlay Heatmap Grad-CAM yang menyoroti area perdarahan fokal.
4. Dokter spesialis mengonfirmasi derajat keparahan akhir dan menandatangani resume medis digital.

---

## 14. Indeks Dokumentasi Lengkap Proyek

Dokumentasi spesifikasi teknis, klinis, dan arsitektur RETIVA tersedia secara mendalam pada berkas-berkas berikut:

* 🩺 **[Spesifikasi Klinis &amp; CDSS (docs/clinical/CLINICAL_SPECIFICATION.md)](docs/clinical/CLINICAL_SPECIFICATION.md)**: Konsensus Perdami 2024, skala keparahan ICDR, formula kendali mutu (*Quality Gate*), dan mesin aturan deterministik rujukan.
* 🏛️ **[Spesifikasi Arsitektur Sistem (docs/architecture/ARCHITECTURE.md)](docs/architecture/ARCHITECTURE.md)**: Cetak biru Clean Architecture, perancangan domain model, pola Ports & Adapters, dan diagram sekuensial interaksi sistem.
* 🌐 **[Spesifikasi REST API v1 (docs/api/API_V1.md)](docs/api/API_V1.md)**: Panduan 37 rute endpoint API beserta parameter permintaan, contoh respons JSON, dan skema kode status galat.
* 📄 **[Spesifikasi Standar OpenAPI 3.0 (docs/api/openapi.json)](docs/api/openapi.json)**: Definisi format standar OAS 3.0 untuk pengujian otomatis menggunakan Postman / Swagger UI.
* 🔗 **[Peta Integrasi End-to-End (docs/integration-map.md)](docs/integration-map.md)**: Diagram arsitektur terverifikasi, katalog 15 integrasi, dan sequence diagram alur data antar komponen.
* 🔍 **[Laporan Audit Integrasi (docs/integration-audit.md)](docs/integration-audit.md)**: Temuan 7 isu teknis dengan severity, bukti kode remediasi, dan status 100% PASS.
* 📜 **[Kontrak API Kanonikal (docs/api-contracts.md)](docs/api-contracts.md)**: Spesifikasi envelope request/response, DTO, dan kontrak komunikasi Web, Mobile, Backend dan AI.
* 🧪 **[Laporan Pengujian Terpadu (docs/test-report.md)](docs/test-report.md)**: Perintah eksekusi, log output, dan bukti **78/78 pengujian lulus (100%)** di seluruh 3 stack.
* 🛡️ **[Panduan Keamanan &amp; Regulasi (docs/security/SECURITY_COMPLIANCE.md)](docs/security/SECURITY_COMPLIANCE.md)**: Analisis komprehensif pemenuhan UU PDP No. 27/2022, Permenkes No. 24/2022, standar ISO 27001, serta audit trail non-repudiation.
* 📖 **[Panduan Pengguna &amp; Alur Kerja (docs/user-guide/USER_GUIDE.md)](docs/user-guide/USER_GUIDE.md)**: Tata laksana pengoperasian antarmuka web bagi tenaga kesehatan FKTP dan dokter spesialis mata FKRTL.
* 📱 **[Dokumentasi Klien Mobile (mobile/README.md)](mobile/README.md)**: Arsitektur Flutter, pemetaan 10 layar Figma, dan panduan pengoperasian di lapangan.
* 🧠 **[Panduan AI Microservice (ai-service/README.md)](ai-service/README.md)**: Dokumentasi teknis model EfficientNet-B3, multi-format loader (PyTorch, ONNX, TFLite), Quality Evaluator OpenCV, dan Grad-CAM interpretability.
* 📋 **[Product Requirements Document (prd.md)](prd.md)** & **[UX Design Specification (design(1).md)](design(1).md)**: Dokumen visi produk awal dan pedoman desain antarmuka klinis bebas distraksi visual.

---

## 15. Lisensi dan Hak Cipta

RETIVA dikembangkan untuk kompetisi Hackathon dan inovasi transformasi digital kesehatan nasional Indonesia.
Hak cipta © 2026 Tim Pengembang RETIVA. Seluruh hak cipta dilindungi undang-undang.
