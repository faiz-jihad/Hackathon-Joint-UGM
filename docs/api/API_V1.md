# RETIVA REST API v1 Specification

Semua endpoint beroperasi di bawah prefix: `/api/v1`

---

## 1. Authentication (`/api/v1/auth`)

### `POST /api/v1/auth/register`
Mendaftarkan akun baru.
- **Request Body**:
  ```json
  {
    "email": "nakes@puskesmas.id",
    "password": "Password123!",
    "fullName": "Siti Nurhaliza, A.Md.Kep",
    "role": "HEALTHCARE_WORKER",
    "phoneNumber": "08123456789"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "data": {
      "token": "eyJhbGciOi...",
      "user": {
        "id": "uuid",
        "email": "nakes@puskesmas.id",
        "fullName": "Siti Nurhaliza, A.Md.Kep",
        "role": "HEALTHCARE_WORKER"
      }
    },
    "meta": { "timestamp": "...", "version": "v1" }
  }
  ```

### `POST /api/v1/auth/login`
Autentikasi akun.
- **Request Body**: `{ "email": "...", "password": "..." }`
- **Response (200 OK)**: Token & user object.

### `GET /api/v1/auth/me`
Mengambil data profil pengguna aktif dari Bearer JWT.

---

## 2. Patients (`/api/v1/patients`)

### `POST /api/v1/patients`
Mendaftarkan rekam demografis pasien diabetes baru.
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "nik": "3201015504850001",
    "fullName": "Budi Santoso",
    "birthDate": "1975-06-15",
    "gender": "MALE",
    "phone": "081987654321",
    "address": "Sleman, DI Yogyakarta"
  }
  ```
- **Response (201 Created)**: Patient object dengan kalkulasi `age`.

### `GET /api/v1/patients`
Pencarian dan daftar pasien dengan pagination (`query`, `limit`, `offset`).

### `GET /api/v1/patients/:id`
Ambil detail data pasien (terlindungi oleh RBAC: pasien hanya dapat melihat datanya sendiri).

---

## 3. Diabetes Profile (`/api/v1/patients/:id/diabetes-profile`)

### `GET /api/v1/patients/:id/diabetes-profile`
Ambil profil riwayat diabetes pasien.

### `POST /api/v1/patients/:id/diabetes-profile`
Simpan atau perbarui profil klinis diabetes pasien.
- **Request Body**:
  ```json
  {
    "diabetesType": "TYPE_2",
    "yearOfDiagnosis": 2018,
    "currentTreatment": "ORAL_MEDICATION",
    "lastHbA1c": 8.2,
    "lastHbA1cDate": "2026-08-10",
    "systolicBp": 135,
    "diastolicBp": 85,
    "isSmoker": false,
    "notes": "Rutin Metformin."
  }
  ```
- **Response (200 OK)**: Profil diabetes lengkap beserta kalkulasi `diabetesDurationYears` dan `glycaemicControlStatus` (`OPTIMAL` / `SUBOPTIMAL` / `POOR`).

---

## 4. Screenings (`/api/v1/screenings`)

### `POST /api/v1/screenings`
Menginisiasi sesi skrining baru untuk pasien.
- **Request Body**:
  ```json
  {
    "patientId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "notes": "Pemeriksaan skrining berkala tahunan."
  }
  ```
- **Response (201 Created)**: Screening object dalam status `CREATED`.

### `GET /api/v1/screenings/:id`
Mengambil status detail sesi skrining beserta daftar citra, skor quality gate, dan status terkini.

### `POST /api/v1/screenings/:id/images`
Mengunggah citra fundus retina (OD / OS). Citra dialirkan ke Object Storage terenkripsi (S3/MinIO), database hanya mencatat metadata dan hash SHA-256 integrity checksum.
- **Content-Type**: `multipart/form-data`
- **Fields**:
  - `eye`: `"OD"` (Mata Kanan) atau `"OS"` (Mata Kiri)
  - `file`: binary fundus image file
- **Response (201 Created)**:
  ```json
  {
    "success": true,
    "data": {
      "retinalImage": {
        "id": "uuid",
        "screeningId": "uuid",
        "eye": "OD",
        "storageKey": "screenings/.../od.jpg",
        "checksum": "sha256...",
        "mimeType": "image/jpeg"
      },
      "screeningStatus": "IMAGE_UPLOADED"
    }
  }
  ```

### `GET /api/v1/screenings/:id/images/:imageId/url`
Mendapatkan presigned time-limited secure URL untuk menampilkan citra fundus secara aman tanpa membuka akses publik ke bucket storage.

### `POST /api/v1/screenings/:id/quality-check`
Memicu evaluasi otomatis **Image Quality Gate** pada citra fundus yang diunggah.
- **Hasil Skenario Mutu Gagal**:
  Status skrining beralih ke `RETAKE_REQUIRED`. Klasifikasi AI dihentikan, instruksi retake dikembalikan ke nakes.
- **Hasil Skenario Mutu Lulus**:
  Status skrining beralih ke `QUALITY_CHECK`. Seluruh citra memenuhi syarat mutu, siap dilanjutkan ke inferensi AI (Phase 3).

### `POST /api/v1/screenings/:id/analyze`
Memicu inferensi model **EfficientNet-B3** dan evaluasi **Reliability Gate**.
- **Prasyarat**: Status skrining harus `QUALITY_CHECK` (lolos uji mutu).
- **Hasil Skenario Reliabilitas Tinggi**:
  Status skrining beralih ke `AI_ANALYZED`.
- **Hasil Skenario Reliabilitas Rendah / Borderline**:
  Status skrining beralih ke `HUMAN_REVIEW` (wajib ditelaah dokter spesialis mata).
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "screeningId": "uuid",
      "screeningStatus": "AI_ANALYZED",
      "aiResult": {
        "predictedClass": "MODERATE_DR",
        "confidence": 0.88,
        "rawProbabilities": {
          "NO_DR": 0.03,
          "MILD_DR": 0.05,
          "MODERATE_DR": 0.88,
          "SEVERE_DR": 0.03,
          "PROLIFERATIVE_DR": 0.01
        },
        "isHighRisk": false
      },
      "reliability": {
        "status": "ANALYZE",
        "score": 0.90,
        "requiresHumanReview": false
      },
      "nextStep": "PROCEED_TO_RECOMMENDATION"
    }
  }
  ```

### `GET /api/v1/screenings/:id/ai-result`
Mengambil riwayat inferensi AI, skor reliabilitas, dan versi model yang digunakan pada skrining ini.

---

## 5. Model Registry & Versioning (`/api/v1/models`)

### `GET /api/v1/models/active`
Mengambil detail metadata model AI yang sedang aktif digunakan di sistem.
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "modelName": "efficientnet-b3",
      "version": "efficientnet-b3-v1.0.0",
      "pipelineVersion": "dr-pipe-v1.2",
      "weightsHash": "sha256:8f4e2c9a1d3b7e5f6a0c8b9d2e4f6a8b1c3d5e7f9a0b2c4d6e8f0a2b4c6d8e0f",
      "thresholds": {
        "qualityPassThreshold": 0.75,
        "reliabilityHighThreshold": 0.85,
        "reliabilityLowThreshold": 0.60
      },
      "classes": [
        "NO_DR",
        "MILD_DR",
        "MODERATE_DR",
        "SEVERE_DR",
        "PROLIFERATIVE_DR"
      ]
    }
  }
  ```

### `GET /api/v1/models`
Mengambil daftar seluruh versi model AI yang telah terdaftar di sistem.
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**: Array of model version objects.

### `POST /api/v1/models`
Mendaftarkan versi model AI baru ke registri (Role: `ADMIN`).
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "modelName": "efficientnet-b3",
    "version": "efficientnet-b3-v2.0.0",
    "pipelineVersion": "dr-pipe-v2.0",
    "weightsHash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "isActive": false,
    "description": "Model dilatih ulang dengan dataset EYEPACS + Messidor-2 lokal."
  }
  ```
- **Response (201 Created)**: Model version object yang baru dibuat.

### `GET /api/v1/models/:id`
Mengambil detail satu versi model AI berdasarkan ID.
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**: Model version object.

### `PUT /api/v1/models/:id/activate`
Mengaktifkan versi model tertentu sebagai model default aktif sistem (Role: `ADMIN`). Model lain secara otomatis dinonaktifkan (`isActive: false`).
- **Headers**: `Authorization: Bearer <token>`
- **Response (200 OK)**: Model version object dengan status `isActive: true`.

---

## 6. Human Review (`/api/v1/reviews`)

### `GET /api/v1/reviews/pending`
Mengambil antrean skrining yang memerlukan telaah dokter spesialis mata (role: `OPHTHALMOLOGIST` atau `ADMIN`).

### `POST /api/v1/reviews/:screeningId`
Mengonfirmasi atau meng-override hasil AI oleh dokter spesialis mata.
- **Request Body**:
  ```json
  {
    "reviewStatus": "OVERRIDDEN",
    "confirmedClass": "MODERATE_DR",
    "clinicalNotes": "Ditemukan mikroaneurisma multipel di kuadran temporal dan perdarahan dot-blot."
  }
  ```
- **Response (200 OK)**:
  Status skrining otomatis maju ke `SCREENING_COMPLETED` dan menghasilkan rekomendasi klinis terstruktur.

---

## 7. Recommendations (`/api/v1/recommendations`)

### `GET /api/v1/recommendations/:screeningId`
Mengambil rekomendasi klinis hasil evaluasi rules engine deterministik (Perdami/ADA 2024).
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "uuid",
      "screeningId": "uuid",
      "summary": "Ditemukan tanda retinopati diabetik non-proliferatif sedang...",
      "recommendedAction": "SPECIALIST_OPHTHALMOLOGY_REFERRAL",
      "urgencyLevel": "MEDIUM",
      "referralIndicated": true,
      "clinicalGuideline": "Pedoman Pengelolaan Retinopati Diabetika Perdami 2024 / ADA 2024 Standards of Care",
      "generatedAt": "2026-09-24T..."
    }
  }
  ```

---

## 8. Facilities & Matching (`/api/v1/facilities`)

### `GET /api/v1/facilities`
Mencari direktori fasilitas kesehatan mata dengan filter layanan dan ketersediaan BPJS.

### `POST /api/v1/facilities/match`
Pencocokan fasilitas kesehatan rujukan terdekat secara deterministik (aturan jarak Haversine, layanan subspesialis retina, status BPJS/JKN). **AI tidak memilih rumah sakit secara langsung.**
- **Request Body**:
  ```json
  {
    "latitude": -7.7713,
    "longitude": 110.3775,
    "maxDistanceKm": 25,
    "requiredService": "RETINA_SPECIALIST",
    "requireBpjs": true
  }
  ```
- **Response (200 OK)**: Daftar faskes terdekat terurut berdasarkan status verifikasi dan jarak (km).

---

## 9. Referrals (`/api/v1/referrals`)

### `POST /api/v1/referrals`
Menerbitkan surat rekomendasi rujukan pasien ke faskes rujukan sekunder/tersier.
- **Request Body**:
  ```json
  {
    "screeningId": "uuid",
    "patientId": "uuid",
    "targetFacilityId": "uuid",
    "urgency": "MEDIUM",
    "reason": "Rujukan evaluasi biomikroskopi fundus NPDR Moderate.",
    "clinicalSummary": "Pasien diabetes tipe 2 sejak 2018 dengan HbA1c 8.2%..."
  }
  ```
- **Response (201 Created)**: Referral object berstatus `ISSUED` dengan masa berlaku 30 hari. Status skrining beralih ke `REFERRAL_RECOMMENDED`.

### `GET /api/v1/referrals/:id`
Detail surat rekomendasi rujukan beserta informasi fasilitas target.

### `PUT /api/v1/referrals/:id`
Memperbarui status rujukan (misal: `PATIENT_ATTENDED`, `CANCELLED`).

---

## 10. Follow-ups & History (`/api/v1/follow-ups` & `/api/v1/history`)

### `POST /api/v1/follow-ups`
Menjadwalkan tanggal kunjungan tindak lanjut atau skrining retina berkala.
- **Request Body**:
  ```json
  {
    "patientId": "uuid",
    "screeningId": "uuid",
    "dueDate": "2026-12-24T00:00:00.000Z",
    "notes": "Kontrol retina berkala 3 bulan."
  }
  ```

### `GET /api/v1/follow-ups`
Daftar jadwal tindak lanjut dengan filter tanggal dan status.

### `PUT /api/v1/follow-ups/:id`
Mencatat kehadiran pasien dan menyelesaikan kunjungan kontrol (`FOLLOW_UP_COMPLETED`).

### `GET /api/v1/history/patients/:patientId`
Mengambil rekam jejak skrining longitudinal pasien lengkap:
- Data demografis & profil diabetes
- Timeline seluruh sesi skrining (tanggal, evaluasi mutu, AI result, review dokter)
- Riwayat surat rujukan
- Riwayat kepatuhan kontrol tindak lanjut

---

## 11. Audit Trail & Compliance Logs (`/api/v1/audit-logs`)

Mendukung tata kelola medis, forensik, dan kepatuhan UU PDP No. 27 Tahun 2022 serta Permenkes No. 24 Tahun 2022.

### `GET /api/v1/audit-logs`
Mengambil riwayat mutasi dan aksi penting dalam sistem RETIVA (Role: `ADMIN`).
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**:
  - `actorId` (optional): Filter ID aktor pengguna yang melakukan tindakan.
  - `action` (optional): Filter jenis aksi (e.g. `PATIENT_CREATED`, `SCREENING_INITIATED`, `IMAGE_UPLOADED`, `QUALITY_CHECK_COMPLETED`, `AI_INFERENCE_PERFORMED`, `HUMAN_REVIEW_SUBMITTED`, `REFERRAL_ISSUED`, `FOLLOW_UP_SCHEDULED`, `MODEL_REGISTERED`, `MODEL_ACTIVATED`).
  - `resource` (optional): Filter entitas (e.g. `Patient`, `Screening`, `HumanReview`, `Referral`, `ModelVersion`).
  - `resourceId` (optional): Filter ID entitas terkait.
  - `limit` (optional, default: 50): Jumlah rekaman per halaman.
  - `offset` (optional, default: 0): Indeks awal rekaman.
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "uuid",
        "actorId": "uuid",
        "action": "AI_INFERENCE_PERFORMED",
        "resource": "Screening",
        "resourceId": "uuid",
        "timestamp": "2026-09-24T07:15:30.000Z",
        "ipAddress": "192.168.1.10",
        "userAgent": "RETIVA-Mobile/1.0.0",
        "metadata": {
          "modelVersion": "efficientnet-b3-v1.0.0",
          "predictedClass": "MODERATE_DR",
          "confidence": 0.88,
          "reliabilityScore": 0.90
        }
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0
    }
  }
  ```


