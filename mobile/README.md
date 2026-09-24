# RETIVA Mobile Client (Flutter)

Aplikasi mobile untuk tenaga kesehatan (perawat / kader / operator fundus camera) di fasilitas kesehatan primer / Puskesmas.

## Arsitektur Mobile & Network Boundary

Sesuai aturan arsitektur RETIVA:
- **Flutter hanya berkomunikasi dengan RETIVA Core API (Next.js)** pada endpoint `/api/v1/*`.
- **Flutter TIDAK PERNAH berkomunikasi langsung dengan FastAPI AI Service** atau database PostgreSQL.
- Semua gambar fundus di-upload melalui multipart presigned flow yang dikoordinasikan oleh RETIVA Core API.

## Fitur Utama
1. **Autentikasi & RBAC**: Login sebagai Tenaga Kesehatan / Pasien.
2. **Pendaftaran Pasien**: Registrasi NIK, identitas, dan profil diabetes melitus.
3. **Fundus Camera Capture**: Integrasi kamera fundus portabel atau upload galeri (OD / OS).
4. **Automated Quality Guidance**: Indikator instan jika citra buram / terlalu gelap sebelum dikirim ke AI.
5. **Screening Dashboard**: Menampilkan status skrining real-time (Reliability, Human Review, Rekomendasi).
6. **Rujukan & Faskes**: Menampilkan peta dan daftar faskes retina terdekat dengan status BPJS yang jelas.
