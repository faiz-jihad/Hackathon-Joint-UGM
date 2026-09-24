# SPESIFIKASI KLINIS DAN SISTEM PENDUKUNG KEPUTUSAN (CDSS) RETIVA

## 1. Konteks Medis dan Epidemiologi

Retinopati Diabetik (RD) merupakan komplikasi mikrovaskular utama dari Diabetes Melitus (DM) yang menjadi salah satu penyebab utama gangguan penglihatan dan kebutaan permanen pada usia produktif di Indonesia. 

Berdasarkan konsensus nasional **Perdami (Persatuan Dokter Spesialis Mata Indonesia)** dan **ADA (American Diabetes Association) 2024**:
- Pasien DM Tipe 2 wajib menjalani pemeriksaan skrining funduskopi retina sejak awal terdiagnosis, kemudian diulang minimal satu kali setiap tahun.
- Pasien DM Tipe 1 memulai skrining funduskopi rutin dalam kurun waktu 5 tahun setelah diagnosis ditegakkan.
- Lebih dari 80% kasus kebutaan akibat retinopati diabetik dapat dicegah apabila lesi mikrovaskular terdeteksi pada fase non-proliferatif awal dan mendapatkan tatalaksana serta kendali glikemik yang memadai.

---

## 2. Skala Klasifikasi ICDR (International Clinical Diabetic Retinopathy)

RETIVA mengadopsi skala derajat keparahan ICDR 5 tingkat yang diakui secara global dan menjadi standar pelayanan kedokteran spesialis mata di Indonesia:

| Derajat ICDR | Istilah Klinis | Temuan Patologis Khas pada Citra Fundus | Risiko Konversi 1 Tahun |
| :--- | :--- | :--- | :--- |
| **Derajat 0** | **No DR** (Tidak tampak retinopati) | Tidak ada lesi mikrovaskular terdeteksi; fundus normal, fovea dan diskus tenang. | < 5% |
| **Derajat 1** | **Mild NPDR** (Non-proliferatif ringan) | Hanya ditemukan mikroaneurisma fokal terisolasi tanpa eksudat atau perdarahan luas. | 5% - 15% |
| **Derajat 2** | **Moderate NPDR** (Non-proliferatif sedang) | Mikroaneurisma multipel, perdarahan bercak intraretina (*dot-blot hemorrhages*), eksudat keras (*hard exudates*), atau *cotton-wool spots*, namun belum memenuhi aturan 4-2-1. | 15% - 27% |
| **Derajat 3** | **Severe NPDR** (Non-proliferatif berat) | Memenuhi salah satu kriteria aturan **4-2-1**: (a) Perdarahan intraretina berat pada 4 kuadran; (b) Venous beading pada 2 kuadran; atau (c) IRMA (*Intraretinal Microvascular Abnormalities*) pada 1 kuadran, tanpa neovaskularisasi terbuka. | 50% - 75% |
| **Derajat 4** | **PDR** (Retinopati proliferatif) | Neovaskularisasi diskus optikus (NVD), neovaskularisasi retina perifer (NVE), perdarahan vitreus pra-retina, atau ablasio retina traksional. | > 75% |

---

## 3. Protokol Kendali Mutu Citra (Quality Gate Protocol)

Untuk menjamin keselamatan diagnostik pasien, citra fundus yang diambil di FKTP harus melewati uji kendali mutu objektif sebelum inferensi dilakukan.

### 3.1 Parameter Evaluasi Kualitas
1. **Indeks Ketajaman (Sharpness Index)**:
   - Dihitung menggunakan varians operator Laplacian termodifikasi terhadap batas pembuluh darah retina kuadran sentral.
   - Nilai minimum ambang batas (*threshold*): **>= 0.40**.
   - Citra dengan nilai < 0.40 diklasifikasikan sebagai *buram (blur)* dan memicu penolakan otomatis.
2. **Indeks Pencahayaan & Kontras (Illumination Balance)**:
   - Mengukur distribusi histogram intensitas kanal hijau (*green channel*) yang optimal untuk visualisasi mikrovaskular.
   - Menghindari area *underexposed* (< 15% intensitas rata-rata) atau *overexposed* akibat pantulan lampu kamera pada kornea.
3. **Cakupan Bidang Pandang Retina (Field of View Coverage)**:
   - Mengharuskan makula lutea dan diskus optikus berada di dalam zona pandang tengah dengan diameter sudut minimal 45 derajat.

### 3.2 Prosedur Kegagalan Mutu (Retake Handling)
- Kegagalan uji mutu menghasilkan status **`QUALITY_FAIL`**.
- Sistem menampilkan alasan penolakan yang jelas dan instruksi koreksi kepada tenaga kesehatan (misal: penyesuaian jarak lensa atau eliminasi artefak kedipan).
- Citra yang gagal tidak diperkenankan diproses ke model klasifikasi guna mencegah *false negative* akibat lesi yang tertutup artefak.

---

## 4. Evaluasi Keandalan Klinis (Reliability Gate)

RETIVA menerapkan prinsip **Reliability Before Prediction**. Prediksi AI tidak dapat disajikan sebagai pendukung keputusan klinis jika tingkat keyakinannya berada pada zona ketidakpastian (*uncertainty margin*).

### 4.1 Ambang Batas Keandalan
- **High Reliability (`RELIABILITY_HIGH`)**:
  - Probabilitas kelas utama >= 0.85 (85%).
  - Margin selisih antara probabilitas kelas pertama dan kedua >= 0.20.
  - Hasil skrining dapat ditampilkan langsung dengan rekomendasi alur standar.
- **Low Reliability / Needs Review (`RELIABILITY_LOW`)**:
  - Probabilitas kelas utama < 0.85, atau margin selisih antarkelas tipis (kasus *borderline*).
  - Kasus otomatis dialihkan ke **Antrean Telaah Dokter Spesialis Mata (Human-in-the-Loop)**.
  - Pasien dan faskes diberi tahu bahwa citra sedang dalam peninjauan profesional.

---

## 5. Mesin Rekomendasi Klinis Deterministik (Rules Engine)

Keputusan klinis mengenai interval kontrol dan urgensi rujukan **tidak diserahkan kepada Large Language Model (LLM)**, melainkan dieksekusi secara deterministik menggunakan mesin aturan berbasis tabel kebenaran klinis:

```typescript
// Logika Inti Deterministic Recommendation Engine
if (drGrade === 'NO_DR') {
  return {
    action: 'Skrining berkala rutin tahunan di FKTP Puskesmas.',
    intervalMonths: 12,
    referralRequired: false,
    urgencyDays: 365,
    guidelineReference: 'Perdami 2024 / ADA Standards of Care'
  };
} else if (drGrade === 'MILD_NPDR') {
  return {
    action: 'Monitoring ketat kendali glikemik di FKTP. Evaluasi ulang funduskopi 6 bulan.',
    intervalMonths: 6,
    referralRequired: false,
    urgencyDays: 180,
    guidelineReference: 'Perdami 2024 / ADA Standards of Care'
  };
} else if (drGrade === 'MODERATE_NPDR') {
  return {
    action: 'Rujukan terencana ke Dokter Spesialis Mata FKRTL untuk evaluasi edema makula dan OCT.',
    intervalMonths: 1,
    referralRequired: true,
    urgencyDays: 30,
    guidelineReference: 'Perdami 2024 / Permenkes Rujukan Berjenjang'
  };
} else if (drGrade === 'SEVERE_NPDR' || drGrade === 'PDR') {
  return {
    action: 'Rujukan prioritas cito ke Rumah Sakit Khusus Mata / Sub-spesialis Vitreoretina.',
    intervalMonths: 0.5,
    referralRequired: true,
    urgencyDays: 14,
    guidelineReference: 'Perdami 2024 Konsensus Vitreoretina'
  };
}
```

---

## 6. Protokol Keterterangan Model (Explainability & Grad-CAM)

1. **Tujuan Grad-CAM**:
   - Menghasilkan visualisasi atensi spasial dari lapisan konvolusi terdalam arsitektur EfficientNet-B3.
   - Membantu dokter penelaah memverifikasi apakah model memusatkan perhatian pada fitur patologis yang benar (misal: eksudat keras, hemoragi) dan bukan pada artefak tepi citra.
2. **Batasan Penggunaan**:
   - Peta Grad-CAM secara tegas diberi label sebagai **konteks atensi algoritma**, bukan bukti patologi absolut atau penentu batas reseksi lesi.

---

## 7. Pemetaan Interoperabilitas Rekam Medis (HL7 FHIR / SatuSehat)

Untuk integrasi ke platform SatuSehat Kementerian Kesehatan RI, data skrining RETIVA dipetakan ke profil FHIR standar:

| Entitas RETIVA | Sumber Daya FHIR R4 | Kode Terminologi Standar |
| :--- | :--- | :--- |
| **Identitas Pasien** | `Patient` | Sistem Identitas NIK Kependudukan (`https://fhir.kemkes.go.id/id/nik`) |
| **Pemeriksaan Fundus** | `Observation` | LOINC `32451-7` (Diagnostic imaging study fundus photograph) |
| **Temuan Derajat DR** | `Condition` | SNOMED CT `4855003` (Diabetic retinopathy) / ICD-10 `E11.3` |
| **Laporan Skrining** | `DiagnosticReport` | LOINC `59282-4` (Ophthalmology Diagnostic study report) |
| **Surat Rujukan FKRTL** | `ServiceRequest` | SNOMED CT `306206005` (Referral to ophthalmologist) |
