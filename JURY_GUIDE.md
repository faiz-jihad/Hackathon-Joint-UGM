# 🏆 PANDUAN PENGGUNA DEWAN JURI HACKATHON
## Platform Skrining & Triase Retinopati Diabetik Nasional — RETIVA

> **Kepada Yang Terhormat Dewan Juri Hackathon Joint UGM,**  
> Dokumen ini disusun khusus sebagai **panduan operasional komprehensif** untuk memudahkan Bapak/Ibu Dewan Juri dalam menguji, mengeksplorasi, dan memvalidasi seluruh inovasi klinis, arsitektur kecerdasan buatan, dan keandalan sistem **RETIVA** dalam waktu 5 hingga 15 menit.

---

## 📑 DAFTAR ISI PANDUAN JURI

1. [Nilai Inovasi & Poin Kunci Penilaian](#1-nilai-inovasi--poin-kunci-penilaian)
2. [Matriks Akses Cepat & Kredensial Demo](#2-matriks-akses-cepat--kredensial-demo)
3. [Panduan Uji 1: Aplikasi Android Mobile (APK Flutter)](#3-panduan-uji-1-aplikasi-android-mobile-apk-flutter)
4. [Panduan Uji 2: Web Portal & Tele-Ophthalmology Sp.M](#4-panduan-uji-2-web-portal--tele-ophthalmology-spm)
5. [Panduan Uji 3: Agentic AI Care Companion Pasca-Konsultasi](#5-panduan-uji-3-agentic-ai-care-companion-pasca-konsultasi)
6. [Panduan Uji 4: Sistem Kedaruratan Retina (Emergency SOS)](#6-panduan-uji-4-sistem-kedaruratan-retina-emergency-sos)
7. [Panduan Uji 5: Verifikasi Uji Otomatis (103/103 Tests Passed)](#7-panduan-uji-5-verifikasi-uji-otomatis-103103-tests-passed)
8. [Panduan Menjalankan Sistem Lokal (1-Click & Docker)](#8-panduan-menjalankan-sistem-lokal-1-click--docker)
9. [Tanya Jawab & Bantuan Pengujian (FAQ)](#9-tanya-jawab--bantuan-pengujian-faq)

---

## 1. Nilai Inovasi & Poin Kunci Penilaian

Sebagai diferensiasi utama, **RETIVA BUKAN sekadar model klasifikasi AI yang dibungkus antarmuka aplikasi**, melainkan **Sistem Pendukung Keputusan Klinis (CDSS) holistik** yang menjawab tantangan desentralisasi penapisan diabetes di Indonesia:

| Pilar Penilaian | Keunggulan Inovasi RETIVA |
| :--- | :--- |
| **Keamanan Klinis (Clinical Safety Gate)** | AI berhak **menolak mengeluarkan prediksi** jika foto buram (*OpenCV Laplacian Quality Gate* $\ge 0.40$) atau jika keyakinan model berada di zona *borderline* (< 85%). |
| **Human-in-the-Loop** | Kasus ambigu tidak ditebak sembarangan oleh AI, melainkan dieskalasi otomatis ke antrean dokter spesialis mata (Sp.M) dengan bantuan visualisasi atensi **Grad-CAM**. |
| **Kepatuhan Regulasi Medis** | Mematuhi konsensus **Perdami 2024**, **ADA 2024**, **Permenkes No. 24/2022** (RME & Jejak Audit Non-Repudiation), serta **UU Perlindungan Data Pribadi No. 27/2022**. |
| **Arsitektur Zero-BLOB Storage** | Basis data relasional tidak pernah menyimpan file biner gambar langsung. Gambar disimpan di object storage privat ber-hash SHA-256 dengan *Presigned URL* berbatas waktu 15 menit. |
| **Agentic AI Care Companion** | Pendamping pasien pra/pasca konsultasi dengan *Safety Evaluator* tanda bahaya mata darurat dan rekomendasi nutrisi rendah glikemik berbasis pangan lokal hemat biaya. |
| **Kesiapan Produksi & Mobile Multi-Tier** | Klien mobile Flutter 1:1 desain Figma (layar 400x854px) dengan **Smart Offline Fallback** dan binary APK siap pasang. |

---

## 2. Matriks Akses Cepat & Kredensial Demo

### 🌐 Akses Web Portal:
* **URL Lokal:** [`http://localhost:3000`](http://localhost:3000)
* **URL Produksi VPS (Live Domain):** [`https://hackathon.mataceria.my.id`](https://hackathon.mataceria.my.id)

### 🔑 Akun Demo Siap Pakai (Database Seeded):

> 💡 **Kata sandi untuk seluruh akun demo di bawah ini adalah:** `password`

| Peran (Role) | Email Login | Kata Sandi | Wewenang & Fitur yang Dapat Diuji Juri |
| :--- | :--- | :---: | :--- |
| **Administrator** | `admin@gmail.com` | `password` | Dashboard operasional nasional, pengelolaan direktori faskes rujukan BPJS, tata kelola model AI, dan inspeksi jejak audit forensik. |
| **Dokter Spesialis Mata (Sp.M)** | `dr.harianto@retiva.id` | `password` | **Antrean Telaah Human Review**, inspeksi overlay Grad-CAM interaktif, koreksi (*clinical override*) derajat ICDR, dan penandatanganan resume medis digital. |
| **Dokter Spesialis Mata 2** | `dr.anindita@retiva.id` | `password` | Ajudikasi sekunder kasus rujukan tersier di RS Khusus Mata Dr. Yap. |
| **Tenaga Kesehatan Puskesmas** | `nakes.siti@puskesmas.go.id` | `password` | Intake identitas pasien (NIK 16-digit), skrining bilateral fundus (OD/OS), evaluasi Quality Gate, dan penerbitan SPK rujukan PDF. |
| **Pasien Demo** | NIK: `3404015508750001` | - | Pasien "Bapak Sutrisno" (memiliki rekam medis longitudinal riwayat skrining tahunan). |

---

## 3. Panduan Uji 1: Aplikasi Android Mobile (APK Flutter)

Klien mobile dirancang khusus untuk nakes di Puskesmas/Klinik Pratama dengan akurasi 1:1 terhadap rancangan Figma.

### Langkah Instalasi APK ke Smartphone Android:
1. **Lokasi File APK di Repository:**  
   [`web/public/retiva-app.apk`](web/public/retiva-app.apk) *(Ukuran: 22.8 MB, Arsitektur: ARM64)*
2. **Cara Unduh:**
   * **Opsi A:** Buka browser HP ke `http://<IP-Laptop-Anda>:3000` lalu tap tombol **"Download APK"** di banner beranda.
   * **Opsi B (via ADB di terminal laptop):**
     ```bash
     adb install web/public/retiva-app.apk
     ```
   * **Opsi C:** Kirim file `retiva-app.apk` via WhatsApp/Google Drive/Kabel USB ke HP Android Anda, lalu tap untuk menginstall *(aktifkan izin "Install dari sumber tidak dikenal" pada pengaturan HP)*.

---

### Skenario Uji Klinis di Aplikasi Mobile:

#### Skenario 1.1: Skrining Normal & Grad-CAM Interaktif (Cabang A)
1. Buka aplikasi **RETIVA** di smartphone Android.
2. Di layar beranda (*Homepage*), tap tombol **"Mulai Skrining Baru"**.
3. Masukkan data intake pasien:
   * **NIK:** `3404015508750001` (atau klik gunakan data demo).
   * Centang kotak persetujuan medis (*Informed Consent*).
4. Pilih mata yang diperiksa: **OD (Mata Kanan)** atau **OS (Mata Kiri)**.
5. Ambil foto fundus tajam (atau pilih sampel foto retina dari galeri).
6. Perhatikan layar animasi **Quality Gate**:
   * Ketajaman varian Laplacian dihitung seketika ($\ge 0.40$).
   * Keseimbangan intensitas kanal hijau dievaluasi (15% - 85%).
   * Lingkaran sudut pandang retina (FOV $\ge 45^\circ$) divalidasi.
7. Aplikasi menampilkan hasil inferensi AI:
   * **Derajat Keparahan ICDR** (misal: *Moderate NPDR* Derajat 2).
   * **Tingkat Keyakinan (Confidence Score)** dan diagram distribusi probabilitas 5 kelas.
   * **Penampil Interaktif Heatmap Grad-CAM**: Coba geser slider opasitas atensi AI dan gunakan fitur *pinch-to-zoom* hingga 4.5x untuk meninjau mikroaneurisma retina.
8. Tap **"Tindakan Lanjutan"**:
   * Sistem otomatis menghitung jarak faskes rujukan terdekat berbasis GPS (Haversine).
   * Menampilkan status penerimaan BPJS Kesehatan.
9. Tap **"Terbitkan SPK Rujukan"**:
   * Terbit Surat Pengantar Rujukan resmi berstandar ICD-10 (`E11.319`).
   * Tombol **"Unduh SPK PDF"** siap dicetak atau disimpan.

#### Skenario 1.2: Uji Penolakan Citra Buram / Gagal Mutu (Cabang B - Retake)
1. Lakukan skrining ulang, namun unggah foto yang sengaja buram, terlalu gelap, atau tertutup bayangan.
2. **Sistem Menolak Memprediksi:**  
   AI tidak menebak secara membabi buta. Sistem menampilkan layar **"Kualitas Citra Belum Memenuhi Syarat"**.
3. Sistem memberikan panduan korektif bagi nakes (*"Pencahayaan kurang seimbang", "Jarak lensa terlalu dekat"*).
4. Tersedia tombol **"Ambil Ulang Foto"** untuk mengulang pemotretan.

> 🌟 **Fitur Smart Offline Fallback:**  
> Jika smartphone juri tidak tersambung ke jaringan laptop/server, aplikasi mobile **tidak akan crash**. Sistem secara cerdas mengaktifkan engine simulasi respon medis berstandar Perdami 2024 sehingga juri tetap dapat menguji seluruh 10 layar workstation secara mulus.

---

## 4. Panduan Uji 2: Web Portal & Tele-Ophthalmology Sp.M

Web Portal dibangun dengan **Next.js 14 App Router** dan Clean Architecture, berfungsi sebagai konsol tele-medisin bagi dokter spesialis mata.

### Langkah Pengujian Web Portal:
1. Buka browser di laptop ke alamat: **`http://localhost:3000`**
2. Pada layar **Character Select Screen**, klik tombol **"PILIH PERAN"** pada kartu **DOKTER** (atau kunjungi `http://localhost:3000/login/dokter`).
3. Masuk dengan akun spesialis:
   * **Email:** `dr.harianto@retiva.id`
   * **Kata Sandi:** `password`

---

### Fitur Klinis yang Wajib Diuji Juri di Web:

#### 1. Antrean Telaah Dokter Spesialis (Human-in-the-Loop)
* Buka menu **"Telaah Kasus (Review)"** atau navigasi ke `/reviews/pending`.
* Kasus-kasus yang masuk ke antrean ini adalah hasil skrining faskes primer yang berada pada rentang *borderline* ($\text{confidence} < 85\%$).
* Klik salah satu sesi skrining untuk membuka konsol telaah Sp.M.

#### 2. Konsol Ajudikasi Medis & Grad-CAM Overlay
* Dokter dapat membandingkan **Citra Fundus Asli** berdampingan dengan **Peta Atensi Grad-CAM AI**.
* **Clinical Override:** Dokter memiliki wewenang penuh untuk:
  * Mengonfirmasi prediksi AI.
  * Mengoreksi derajat keparahan (misal dari *Mild* menjadi *Moderate NPDR* jika melihat eksudat keras tersembunyi).
  * Meminta faskes primer melakukan retake foto.
* Dokter membubuhkan catatan klinis dan menandatangani resume digital. Tindakan ini dicatat ke dalam log audit forensik dengan cap waktu berpresisi mikrodetik.

#### 3. Direktori Fasilitas Rujukan & Geodesik BPJS
* Navigasi ke menu **"Fasilitas Rujukan"**.
* Menampilkan daftar Rumah Sakit Mata sekunder/tersier (misal: RS Khusus Mata Dr. Yap, RSUP Dr. Sardjito).
* Sistem menampilkan koordinat geodesik, jarak tempuh kilometer, ketersediaan dokter subspesialis vitreoretina, serta status verifikasi BPJS Kesehatan.

#### 4. Jejak Audit Non-Repudiation (Permenkes No. 24/2022)
* Login sebagai Administrator (`admin@gmail.com` / `password`).
* Buka menu **"Audit Log"** untuk melihat pencatatan seluruh mutasi medis: ID sesi, identitas nakes/dokter, peran, alamat IP, dan timestamp yang tidak dapat dimanipulasi (*tamper-proof*).

---

## 5. Panduan Uji 3: Agentic AI Care Companion Pasca-Konsultasi

Agentic AI Care Companion dirancang untuk memberdayakan pasien diabetes setelah menerima hasil skrining:

### Skenario Uji 3.1: Deteksi Gejala Darurat Retina (Urgent Safety Evaluator)
1. Buka modul Care Companion di web portal (`/care-companion` atau via menu pasien).
2. Simulasikan keluhan pasien: pilih gejala *"Melihat kilatan cahaya mendadak seperti petir"* atau *"Ada bayangan hitam tirai menutupi lapang pandang"*.
3. **Respon Sistem:**  
   Sistem **memblokir seluruh alur rutin non-darurat** dan seketika menyalakan alarm peringatan merah cito:  
   `STATUS: SEGERA_KE_IGD_RS_MATA (Indikasi Suspek Ablasio Retina / Perdarahan Vitreus Akut)`.

### Skenario Uji 3.2: Perencana Nutrisi Rendah Glikemik Ramah Kantong (Budget-Aware)
1. Masukkan profil batasan anggaran makan harian pasien (misal: **Rp25.000 – Rp35.000 per hari**).
2. Sistem menyusun menu makan 3 kali sehari + 1 snack sehat menggunakan bahan pangan lokal Indonesia berindeks glikemik rendah (tempe bacem tanpa gula pasir, tahu kukus, beras merah, ikan kembung bakar, sayur bening bayam).
3. **Uji Penggantian Menu (Meal Swap):**  
   Klik tombol ganti menu pada makan siang. Sistem secara dinamis menghitung ulang sisa alokasi anggaran rupiah dan target kalori harian secara deterministik.

### Skenario Uji 3.3: Invarian State Machine Medis
* Sistem menerapkan proteksi ketat: **rencana tindak lanjut gaya hidup pasca-konsultasi tidak boleh diterbitkan kepada pasien sebelum resume dokter spesialis mata terkonfirmasi secara sah**.

---

## 6. Panduan Uji 4: Sistem Kedaruratan Retina (Emergency SOS)

Untuk mencegah risiko kebutaan akut pada pasien diabetes di daerah terpencil:
1. Pasien dapat mengakses tombol **SOS Darurat Retina**.
2. Sistem menyiarkan koordinat GPS darurat, data profil diabetes (kadar gula darah & riwayat terapi), serta kontak darurat keluarga ke Puskesmas terdekat dan ambulans siaga.

---

## 7. Panduan Uji 5: Verifikasi Uji Otomatis (103/103 Tests Passed)

Juri yang ingin memvalidasi ketangguhan kode sumber dan cakupan pengujian teknis dapat menjalankan test suite lengkap berikut di terminal:

```bash
# ====================================================================
# 1. Uji Master Web Core API (38 Pengujian Invarian Medis)
# ====================================================================
npm run test:master
```
*Menguji: Autentikasi RBAC, validasi NIK 16 digit, aturan Zero-BLOB, checksum SHA-256, model registry, 5-kelas ICDR, evaluasi Perdami 2024, dan jejak audit non-repudiation.*

```bash
# ====================================================================
# 2. Uji Agentic AI Care Companion (25 Pengujian)
# ====================================================================
npm run test:care-companion
```
*Menguji: Safety evaluator gejala darurat retina, invarian state machine pasca-konsultasi, mesin nutrisi rendah GI berbasis budget IDR, dan orkestrator agen.*

```bash
# ====================================================================
# 3. Uji Klien Mobile Flutter (20 Unit & Widget Tests)
# ====================================================================
cd mobile
flutter test
```
*Menguji: Aturan klinis ICDR, alur 3 cabang state machine (Normal, Retake, Review), dan komponen visual Grad-CAM.*

```bash
# ====================================================================
# 4. Uji Layanan AI FastAPI (20 Pytest)
# ====================================================================
cd ai-service
pytest
```
*Menguji: OpenCV blur Laplacian, cakupan FOV, kestabilan Grad-CAM, dan isolasi kegagalan model.*

```text
HASIL TOTAL PENILAIAN OTOMATIS: 103 / 103 PENGUJIAN LULUS (100% PASS RATE)
```

---

## 8. Panduan Menjalankan Sistem Lokal (1-Click & Docker)

Jika juri ingin menjalankan seluruh subsistem dari nol di laptop juri:

### Opsi 1: One-Click Runner (Windows - Paling Cepat)
Cukup klik ganda file:
```text
start-local.bat
```
Skrip ini akan otomatis menyalin konfigurasi environment, menyalakan AI Microservice di port 8003, dan menyalakan Next.js Web Gateway di port 3000 pada jendela terminal terpisah.

### Opsi 2: Docker Compose (Multi-Container)
```bash
cp .env.example web/.env
docker compose up -d
```
Layanan yang aktif:
* **Web Portal:** `http://localhost:3000`
* **FastAPI Docs:** `http://localhost:8003/docs`
* **MinIO Console:** `http://localhost:9001` (`minioadmin` / `minioadminpassword`)

---

## 9. Tanya Jawab & Bantuan Pengujian (FAQ)

#### Q1: Apakah saya harus menyalakan server backend untuk mencoba aplikasi mobile Android?
> **Tidak wajib.** Aplikasi mobile RETIVA memiliki fitur **Smart Offline Fallback**. Juri dapat langsung menginstall file APK di HP Android dan menguji pemotretan, Quality Gate penolakan foto buram, visualisasi Grad-CAM, dan penerbitan SPK rujukan secara mandiri.

#### Q2: Di mana file APK Android tersimpan di dalam folder proyek?
> File APK release berada di: **[`web/public/retiva-app.apk`](web/public/retiva-app.apk)** (22.8 MB). File ini juga dapat diunduh langsung dari browser di beranda `http://localhost:3000`.

#### Q3: Bagaimana jika HP Android memunculkan peringatan saat memasang APK?
> Karena APK ini didistribusikan untuk keperluan demonstrasi hackathon (belum dipublikasikan ke Google Play Store publik), Android akan menampilkan konfirmasi instalasi. Cukup pilih **"Tetap Install" (Install Anyway)** atau izinkan instalasi dari file manager Anda.

#### Q4: Bagaimana cara mereset atau mengisi ulang basis data ke kondisi awal demo?
> Jalankan perintah berikut di folder proyek:
> ```bash
> npm --prefix web run prisma:seed
> ```
> Perintah ini akan menyegarkan data fasilitas rujukan, akun demo dokter Sp.M, nakes, serta data riwayat skrining longitudinal pasien.

---

*Selamat menguji dan mengeksplorasi ekosistem inovasi **RETIVA**! Kami siap memberikan demonstrasi langsung dan menjawab pertanyaan teknis maupun klinis dari Dewan Juri.*
