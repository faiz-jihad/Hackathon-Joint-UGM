# RETIVA Mobile Client (Flutter)
### *Aplikasi Skrining Retinopati Diabetik Nasional untuk Tenaga Kesehatan FKTP & Puskesmas*

Aplikasi mobile profesional berbasis Flutter yang mengimplementasikan rancangan antarmuka Figma RETIVA (layar mobile 400 × 854 px) serta standar klinis rumah sakit & FKTP (Konsensus Perdami 2024, ADA 2024, Permenkes No. 24/2022 tentang Rekam Medis Elektronik).

---

## 1. Arsitektur Jaringan & Batasan Sistem (Network Boundary)

Sesuai aturan ketat arsitektur medis RETIVA:
* **Flutter hanya berkomunikasi dengan RETIVA Core API (Next.js)** pada endpoint `/api/v1/*`.
* **Flutter TIDAK PERNAH berkomunikasi langsung dengan FastAPI AI Service** atau basis data relasional PostgreSQL.
* Core API Gateway bertindak sebagai orkestrator aman:
  ```text
  [Flutter Mobile Client (Workstation Nakes)]
            |
            v  (HTTP / JSON / Multipart via /api/v1/*)
  [RETIVA Core API Gateway (Next.js)]
            |
            +-----> [PostgreSQL Database (Prisma ORM)]
            |       - Tabel: users, patients, diabetes_profiles, facilities, screenings, audit_logs
            |
            +-----> [Zero-BLOB Object Storage (MinIO / S3)]
            |       - SHA-256 Hash Invariant & Time-Limited Presigned URLs
            |
            +-----> [FastAPI AI Microservice (Port 8003)]
                    - Quality Gate (OpenCV Modified Laplacian blur >= 0.40)
                    - EfficientNet-B3 (5-Class ICDR Classification)
                    - Grad-CAM Explainability Attention Heatmap Layer
  ```

---

## 2. Struktur Proyek Flutter

```text
mobile/
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                                # Entrypoint aplikasi & konfigurasi tema klinis
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart              # Konfigurasi URL Gateway (Android 10.0.2.2 / iOS localhost)
│   │   │   └── app_colors.dart                 # Palet warna medis terstandarisasi & token desain Figma
│   │   ├── network/
│   │   │   └── api_client.dart                 # Klien HTTP terintegrasi ke Core API + Dynamic Fallback
│   │   └── utils/
│   │       └── clinical_helpers.dart           # Pemetaan skala ICDR & aturan interval Perdami/ADA 2024
│   ├── data/
│   │   └── models/
│   │       ├── user_model.dart                 # Profil Nakes (RBAC, NIP/SIP)
│   │       ├── patient_model.dart              # NIK 16 digit, Profil DM (HbA1c, Tensi, Terapi Insulin)
│   │       └── screening_result_model.dart     # Model inferensi 5-kelas, mutu & rujukan
│   └── presentation/
│       ├── widgets/
│       │   ├── brand_header.dart               # Top App Brand Header Retiva v1.0
│       │   ├── custom_button.dart              # Tombol aksi klinis & outlined button
│       │   ├── quality_indicator_tile.dart     # Kartu progres uji mutu (Laplacian, FOV, Pencahayaan)
│       │   ├── gradcam_viewer_widget.dart      # Workstation penampil Grad-CAM: Pinch-to-zoom 4.5x, Slider Opasitas, Grid Anatomi Retina
│       │   └── patient_intake_modal.dart       # Form intake pendaftaran pasien diabetes baru (validasi NIK 16 digit & profil DM)
│       └── screens/
│           ├── home_screen.dart                # 01. Homepage & Konsol Nakes: Jadwal Shift NIP, Kalkulator Risiko DR, SOP Perdami
│           ├── upload_fundus_screen.dart       # 02. Upload I & 03. Upload II (OD/OS bilateral + Selector Pasien Dinamis)
│           ├── quality_scanning_screen.dart    # 04. Kualitas I-IV & 05. Kualitas Jelas (Quality Gate Scanning)
│           ├── quality_failed_retake_screen.dart # 05. Kualitas Buram (Figma Branch: Retake Panduan Nakes)
│           ├── ai_analyzing_screen.dart        # 06. Analisis I-III & 09. Analisis Selesai (Tahapan Inferensi AI)
│           ├── screening_result_screen.dart    # 11. Hasil Skrining, Matriks Lesi Mikrovaskular, Konsultasi Tele-Oftalmologi Sp.M
│           ├── human_review_pending_screen.dart# 10. Reliability Gate & 11. Status Human Review (Antrean Konsulen Sp.M)
│           ├── clinical_recommendation_screen.dart # 14. Tindakan Lanjutan & Pencocokan Faskes Terdekat (Haversine + BPJS JKN)
│           ├── referral_letter_screen.dart     # 15. Penerbitan SPK Rujukan Resmi (Kop Dinkes, Tanda Vital, Validasi BSrE & Ekspor PDF)
│           └── patient_history_screen.dart     # 17. Riwayat Pasien, Filter Risiko Klinis, dan Timeline Longitudinal
```

---

## 3. Fitur Profesional Kesehatan yang Diimplementasikan

1. **Konsol Klinis Tenaga Kesehatan (Homepage)**:
   - Identitas shift nakes resmi (`Siti Nurhaliza, S.Tr.Kes • NIP: 199204122018022001 • Puskesmas Sleman`).
   - Statistik triase populasi diabetes dari basis data real-time (Total Pasien, HbA1c >= 8.5%, HbA1c 7.0-8.4%, RS Rujukan Siap).
   - Modal Interaktif **Kalkulator Estimasi Risiko DR** berbasis durasi diabetes dan HbA1c.
   - Dokumen SOP Penapisan Perdami 2024 terintegrasi.
2. **Form Intake Pasien Baru (`PatientIntakeModal`)**:
   - Pendaftaran pasien baru langsung ke basis data PostgreSQL melalui API.
   - Validasi ketat NIK 16-digit Indonesia, usia, jenis kelamin, tipe diabetes (Tipe 1 vs 2), terapi insulin, dan tekanan darah.
3. **Pemeriksaan Bilateral Otomatis (`UploadFundusScreen`)**:
   - Tab posisi mata terstandar: Oculus Dextra (`OD` - Kanan) dan Oculus Sinistra (`OS` - Kiri).
   - Retikel kamera fundus 45° FOV dan pemilih pasien terintegrasi langsung ke direktori faskes.
4. **Uji Kendali Mutu Citra Medis (`Quality Gate`)**:
   - Algoritma Laplacian termodifikasi (ambang batas ketajaman `>= 0.40`).
   - Keseimbangan iluminasi kanal hijau dan sudut pandang makula 45°.
   - Branch Retake dengan panduan klinis koreksi pencahayaan/fokus untuk nakes.
5. **Workstation Peninjau Citra & Grad-CAM (`GradCamViewerWidget`)**:
   - **InteractiveViewer (Pinch-to-zoom hingga 4.5x & Pan)** untuk inspeksi mikroaneurisma detail.
   - **Slider Opasitas Grad-CAM Kontinu (10% s/d 100%)** untuk cross-examination citra asli dan heatmap.
   - **Grid Anatomi Retina Interaktif** dengan label penanda Papila N. Optikus, Makula/Fovea Sentralis, dan 4 Kuadran Retina.
   - Skala gradien atensi AI terkalibrasi (Baseline -> Fokal -> Puncak Patologis).
6. **Matriks Temuan Lesi Mikrovaskular & Tele-Oftalmologi (`ScreeningResultScreen`)**:
   - Matriks 5 lesi patologis retina (Mikroaneurisma, Perdarahan Dot-blot, Eksudat Keras, Cotton Wool Spots, Neovaskularisasi).
   - Kode diagnostik ganda: **ICD-10 (`E11.319` / `E11.9`)** dan skala klinis ICDR.
   - Fitur **Konsultasi Tele-Oftalmologi** dengan formulir telaah sekunder ke Dokter Spesialis Mata Konsulen Vitreoretina.
   - Segel kepatuhan Rekam Medis Elektronik (Permenkes No. 24/2022) dengan fingerprint SHA-256.
7. **Surat Pengantar Rujukan (SPK) Elektronik Resmi (`ReferralLetterScreen`)**:
   - Kop surat resmi Pemerintah Kabupaten Sleman - Dinas Kesehatan - UPT Puskesmas Sleman.
   - Ringkasan tabel tanda vital (Tekanan Darah, HbA1c, Gula Darah Sewaktu, Visus OD/OS).
   - Tanda Tangan Elektronik (TTE) tersertifikasi BSrE / BSSN.
   - Dialog ekspor PDF resmi dan sinkronisasi ke BPJS VClaim / SATUSEHAT Kemenkes.
8. **Pemantauan Longitudinal & Direktori Pasien (`PatientHistoryScreen`)**:
   - Filter cepat berdasarkan risiko klinis: `HbA1c >= 8.0% (Prioritas)`, `DM Tipe 2`, `DM Tipe 1`.
   - Timeline longitudinal perkembangan antar-tahun (2024 Derajat 0 -> 2025 Derajat 1 -> 2026 Derajat 2).
   - Profil medis detail dan tombol jalan pintas langsung ke skrining fundus.

---

## 4. Panduan Menjalankan Klien Mobile

### 4.1 Prasyarat
- Flutter SDK `>= 3.10.0`
- Android Studio / Xcode / VS Code
- RETIVA Core API (`web`) aktif pada port 3000

### 4.2 Instalasi Dependensi
```bash
cd mobile
flutter pub get
```

### 4.3 Menjalankan Analisis & Pengujian Unit
```bash
# Verifikasi linter & kode bersih (0 issues):
flutter analyze

# Menjalankan 20/20 pengujian unit dan antarmuka klinis:
flutter test
```

### 4.4 Menjalankan Aplikasi
```bash
# Di Android Emulator (secara otomatis terhubung ke http://10.0.2.2:3000):
flutter run

# Di Perangkat Fisik (pastikan ponsel dan PC berada dalam 1 jaringan Wi-Fi):
flutter run
```
