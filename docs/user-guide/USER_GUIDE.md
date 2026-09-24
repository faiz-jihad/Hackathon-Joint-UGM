# PANDUAN PENGGUNA DAN ALUR OPERASIONAL KLINIS RETIVA

RETIVA (*Diabetic Retinopathy Screening System*) adalah instrumen pendukung keputusan klinis (Clinical Decision Support System / CDSS) berbasis kecerdasan buatan dan kendali mutu citra yang dirancang untuk fasilitas kesehatan primer (FKTP) dan rujukan (FKRTL) di Indonesia.

Sistem ini mematuhi Pedoman Pelayanan Kedokteran Perdami (*Persatuan Dokter Spesialis Mata Indonesia*), Konsensus ADA 2024 (*American Diabetes Association*), Permenkes No. 24 Tahun 2022 tentang Rekam Medis Elektronik, dan UU Perlindungan Data Pribadi No. 27 Tahun 2022.

---

## 1. Peran dan Kewenangan Pengguna (RBAC)

| Peran Pengguna | Kewenangan Utama | Fasilitas Terkait |
| :--- | :--- | :--- |
| **Tenaga Kesehatan (Nakes / Perawat / Bidan)** | Registrasi profil diabetes pasien, akuisisi citra fundus bilateral (OD/OS), evaluasi Quality Gate, inisiasi permohonan rujukan. | Fasilitas Kesehatan Tingkat Pertama (FKTP / Puskesmas / Klinik Pratama). |
| **Dokter Spesialis Mata (Ophthalmologist)** | Evaluasi antrean Human Review, inspeksi visual Grad-CAM, konfirmasi/koreksi (*override*) derajat ICDR, penerbitan surat rujukan formal. | Fasilitas Kesehatan Rujukan Tingkat Lanjutan (FKRTL / Rumah Sakit). |
| **Administrator Sistem** | Manajemen pendaftaran faskes rujukan, audit registry model AI, pemantauan log audit non-repudiation. | Dinas Kesehatan / Kemenkes / Administrator IT. |

---

## 2. Alur Operasional Tenaga Kesehatan di FKTP

### 2.1 Pendaftaran Pasien & Profil Diabetes
1. Buka portal RETIVA dan pilih tab **Skrining Baru (OD/OS)**.
2. Masukkan Nomor Induk Kependudukan (NIK - 16 digit).
   - Apabila pasien telah terdaftar sebelumnya, profil riwayat klinis akan terisi otomatis.
   - Apabila pasien baru, lengkapi nama lengkap, usia, jenis kelamin, klasifikasi diabetes melitus (Tipe 1 / Tipe 2 / Gestasional), durasi menderita diabetes, kadar HbA1c terakhir, dan regimen obat/insulin terkini.
3. Pastikan kotak persetujuan medis (*informed consent*) telah dicentang sesuai dengan hak privasi pasien.
4. Klik **Lanjutkan ke Akuisisi Citra**.

### 2.2 Akuisisi Citra Funduskopi Digital
1. Posisikan pasien di depan kamera fundus non-midriatik.
2. Pilih mata yang diperiksa terlebih dahulu:
   - **OD (Oculus Dexter)**: Mata Kanan
   - **OS (Oculus Sinister)**: Mata Kiri
3. Verifikasi standar pemotretan:
   - Fovea sentralis dan diskus optikus terlihat jelas dalam bidang pandang 45 derajat.
   - Hindari pantulan kilau cahaya kornea (*flash artifact*) dan bayangan bulu mata.
4. Unggah atau capture citra fundus digital.
5. Klik **Proses Citra & Jalankan Evaluasi Klinis**.

### 2.3 Evaluasi Kendali Mutu (Quality Gate)
Sebelum citra diproses oleh model klasifikasi AI, sistem menjalankan kendali mutu otomatis:
- **Indeks Ketajaman (Sharpness)**: Mengukur kejelasan batas pembuluh darah retina (Ambang batas minimum: 0.40).
- **Indeks Pencahayaan (Illumination)**: Memverifikasi keseimbangan kontras makula dan ketiadaan bayangan gelap.
- **Cakupan Retina (Field of View)**: Memverifikasi keterlihatan makula dan papil saraf optik.

**Keluaran Quality Gate:**
- **Citra Layak (Passed)**: Citra secara otomatis diteruskan ke analisis inferensi AI dan kalkulator keandalan klinis.
- **Perlu Pengambilan Ulang (Failed / Retake Required)**: Citra ditolak dengan alasan spesifik (contoh: *Gambar terlalu buram*). Tenaga kesehatan wajib mengulangi pengambilan foto fundus sebelum dapat melanjutkan.

---

## 3. Alur Telaah Klinis Dokter Spesialis Mata (Human-in-the-Loop)

### 3.1 Antrean Review Kasus Borderline & Tidak Pasti
Sesuai prinsip keselamatan medis, RETIVA **tidak pernah memaksakan prediksi AI jika tingkat keyakinan rendah**.
Apabila hasil skrining berada pada rentang *borderline* atau keandalan rendah (*Reliability Gate: LOW*), kasus secara otomatis diarahkan ke **Antrean Telaah Dokter Spesialis Mata**.

### 3.2 Prosedur Ajudikasi Spesialis
1. Buka tab **Tinjauan Dokter** atau klik tombol **Periksa** pada baris antrean dashboard.
2. Periksa informasi klinis pasien (durasi sakit, kadar HbA1c terkini).
3. Evaluasi citra fundus melalui dua mode tampilan:
   - **Citra Fundus Asli**: Citra resolusi tinggi untuk memeriksa mikroaneurisma, perdarahan bercak (*dot-blot hemorrhages*), eksudat keras, atau neovaskularisasi.
   - **Peta Grad-CAM AI**: Peta gradien atensi arsitektur konvolusi yang menyorot area lesi retina yang menjadi fokus perhatian model.
4. Tentukan keputusan ajudikasi pada formulir:
   - **Konfirmasi Temuan AI**: Menyetujui derajat klasifikasi model (No DR / Mild / Moderate / Severe / PDR).
   - **Koreksi Derajat DR Manual (Clinical Override)**: Mengubah derajat retinopati berdasarkan evaluasi klinis spesialis.
   - **Minta Pengambilan Ulang Citra**: Meminta faskes primer melakukan foto ulang jika media refraksi atau kualitas gambar tidak memadai.
5. Tuliskan catatan klinis dokter penelaah.
6. Klik **Simpan & Tandatangani Ajudikasi Klinis**. Keputusan ini secara otomatis dicatat dalam log audit non-repudiation bersama NIP/SIP dokter.

---

## 4. Logika Mesin Rekomendasi Klinis (Perdami & ADA 2024)

RETIVA menerapkan aturan deterministik berbasis pedoman resmi, bukan teks generatif black-box:

| Temuan Klasifikasi ICDR | Stratifikasi Risiko | Rekomendasi Alur Tindakan | Batas Waktu Rujukan |
| :--- | :--- | :--- | :--- |
| **No DR** (Derajat 0) | Risiko Rendah | Skrining berkala rutin tahunan di FKTP Puskesmas. Optimalisasi kendali glikemik target HbA1c < 7.0%. | 12 Bulan |
| **Mild NPDR** (Derajat 1) | Risiko Sedang | Monitoring berkala di FKTP. Evaluasi tekanan darah dan profil lipid. Kontrol ulang fundus 6 bulan. | 6 Bulan |
| **Moderate NPDR** (Derajat 2) | Risiko Tinggi | Rujukan berjenjang ke Dokter Spesialis Mata FKRTL untuk pemeriksaan slit-lamp dan OCT makula. | Maksimal 30 Hari |
| **Severe NPDR** (Derajat 3) | Risiko Sangat Tinggi | Rujukan prioritas cito ke Rumah Sakit Rujukan untuk pertimbangan Pan-Retinal Photocoagulation (PRP). | Maksimal 14 Hari |
| **PDR** (Derajat 4) | Kondisi Kritis | Rujukan segera ke Sub-spesialis Vitreoretina untuk tindakan intervensi bedah atau injeksi anti-VEGF. | Segera (&lt; 7 Hari) |

---

## 5. Penerbitan Surat Pengantar Rujukan (SPK) & BPJS Health Integration

1. Buka tab **Rujukan & Faskes**.
2. Sistem secara otomatis menghitung jarak geodesik (*Haversine distance*) dari koordinat faskes perujuk ke rumah sakit rujukan sekunder/tersier.
3. Fasilitas rujukan menampilkan status verifikasi JKN:
   - **Menerima Rujukan BPJS / JKN**: Faskes terdaftar dalam sistem rujukan berjenjang BPJS Kesehatan.
   - **Status Perlu Dikonfirmasi**: Faskes swasta atau fasilitas yang memerlukan konfirmasi rujukan manual.
4. Pilih rumah sakit rujukan yang dituju (misal: RSUP Dr. Sardjito atau RS Khusus Mata Dr. Yap).
5. Periksa indikasi klinis ICD-10 (misal: `E11.319`).
6. Klik **Terbitkan Surat Rujukan Resmi**. Dokumen rujukan elektronik diterbitkan dengan nomor registrasi unik dan batas masa berlaku.

---

## 6. Kepatuhan Audit & Keamanan Medis

- **Integritas Citra Zero-BLOB**: Citra retina asli tidak disimpan di basis data relasional. Hanya hash kriptografis SHA-256 dan storage key privat yang tersimpan.
- **Log Audit Non-Repudiation**: Setiap login, pemeriksaan mutu, inferensi AI, ajudikasi dokter, dan penerbitan rujukan dicatat secara permanen di tab **Audit & Tata Kelola** dengan waktu berstandar NTP dan identitas operator.
- **Pemberitahuan Klinis Wajib**: Hasil skrining RETIVA adalah alat bantu skrining awal dan **bukan diagnosis medis final**. Tanggung jawab klinis diagnosa definitif dan terapi berada pada dokter yang berwenang.
