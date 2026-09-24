# RETIVA Security & Healthcare Regulatory Compliance Guide

Dokumen ini mendefinisikan postur keamanan, mitigasi risiko data medis, serta kepatuhan hukum **RETIVA** terhadap **Undang-Undang Perlindungan Data Pribadi (UU PDP No. 27 Tahun 2022)** dan **Permenkes No. 24 Tahun 2022 tentang Rekam Medis**.

---

## 1. Prinsip Utama Keamanan Medis RETIVA

1. **Zero-BLOB Storage in Database**:
   - Citra fundus resolusi tinggi tidak disimpan sebagai BLOB di database PostgreSQL guna mencegah eksfiltrasi massal dan *database bloat*.
   - Database hanya menyimpan hash SHA-256 dan `storage_key`.
2. **Presigned & Time-Limited URLs**:
   - Object Storage dikonfigurasi privat (*public access blocked*).
   - Akses citra hanya dapat dilakukan melalui *signed URL* dengan masa kedaluwarsa ketat (10-15 menit).
3. **Role-Based Access Control (RBAC) & Least Privilege**:
   - `PATIENT`: Hanya dapat mengakses data pribadi, rekam skrining sendiri, dan jadwal kontrolnya.
   - `HEALTHCARE_WORKER`: Menginisiasi skrining, mengunggah citra, dan mendaftarkan pasien.
   - `OPHTHALMOLOGIST`: Mengakses antrean telaah klinis (*Human Review Queue*), mengonfirmasi/meng-override hasil klasifikasi AI.
   - `ADMIN`: Mengelola registri versi model, konfigurasi ambang batas, dan mengaudit jejak kepatuhan (*Audit Log*).
4. **Non-Repudiation Audit Trail**:
   - Setiap mutasi data (pendaftaran pasien, pengunggahan citra, uji mutu, inferensi AI, telaah dokter, rujukan, jadwal kontrol) dicatat dalam tabel `AuditLog` yang terisolasi.

---

## 2. Model Versioning & Tata Kelola AI

Untuk memastikan keandalan medis dan penelusuran hukum (*forensic auditability*):
- Setiap inferensi terikat pada `modelVersionId` (misal: `efficientnet-b3-v1.0.0`) dan `weights_hash`.
- Jika model diperbarui di masa depan, catatan skrining pasien lama tetap mempertahankan versi model asal saat inferensi dilakukan.
- AI tidak pernah bertindak sebagai *autonomous diagnostic engine*; hasil AI adalah *screening finding* yang melewati **Reliability Gate** sebelum disetujui.

---

## 3. Matriks Mitigasi Ancaman (Threat Modeling)

| Ancaman | Vektor | Mitigasi RETIVA |
| :--- | :--- | :--- |
| **Pencurian Citra Retina Massal** | Eksfiltrasi DB Dump | DB tidak menyimpan file biner citra. Akses S3 menggunakan private bucket dan presigned URL unik berbatas waktu. |
| **Manipulasi Integritas Citra** | Penggantian citra saat transmisi | Verifikasi hash SHA-256 dihitung saat upload dan divalidasi sebelum Quality Gate / inferensi. |
| **Akses Tak Sah Rekam Medis** | IDOR pada endpoint pasien | Verifikasi token JWT wajib memeriksa kepemilikan data (`patient.userId === actor.id`) pada layer Use-Case. |
| **Brute-Force Login & Credential Stuffing** | `/api/v1/auth/login` | Penerapan `InMemoryRateLimiter` (maksimal 5 percobaan gagal per menit) dan Bcrypt salt rounds 12. |
| **Injeksi SQL / Parameter Tampering** | Query params & JSON body | Seluruh input melewati sanitasi skema Zod dan prepared statements Prisma ORM. |
