# RETIVA AI Microservice

### *Reliability-First Deep Learning Inference & Computer Vision Quality Gate*

[![FastAPI](https://img.shields.io/badge/Framework-FastAPI_(Asynchronous_ASGI)-009688?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?style=for-the-badge&logo=python)](https://python.org)
[![OpenCV](https://img.shields.io/badge/Computer_Vision-OpenCV_Headless-5C3EE8?style=for-the-badge&logo=opencv)](https://opencv.org)
[![Deep Learning](https://img.shields.io/badge/Architecture-EfficientNet--B3_(300x300)-FF6F00?style=for-the-badge&logo=pytorch)](models)
[![Tests](https://img.shields.io/badge/Tests-20%2F20_Pytest_Passed_(100%25)-10B981?style=for-the-badge)](tests)

Layanan mikrosistem inferensi kecerdasan buatan terisolasi berbasis **FastAPI** untuk penapisan Retinopati Diabetik berkeandalan tinggi (*Reliability-First Diabetic Retinopathy Screening*).

---

## 1. Filosofi & Mandat Keselamatan Medis

> ⚠️ **Prinsip Utama: Hak Menolak Model AI (The Model Must Be Allowed to Abstain)**
> Model AI diwajibkan menolak membuat prediksi apabila masukan citra tidak memenuhi standar mutu atau tingkat keyakinan berada di zona ketidakpastian.

* **Bukan Alat Diagnosis Otonom**: RETIVA adalah alat bantu penapisan klinis (*Screening Decision Support Tool*), bukan pengganti dokter spesialis mata.
* **Isolasi Kegagalan Grad-CAM (*Fail-Safe Execution*)**: Kegagalan pembuatan heatmap visual atensi tidak boleh menggagalkan hasil inferensi klasifikasi utama.

---

## 2. Pipeline Komputasi Citra Fundus

```text
               +---------------------------+
               |    Retinal Fundus Image   |
               +---------------------------+
                             |
                             v
               +---------------------------+
               |  Image Quality Gate       |
               |  - Blur (Laplacian var)   |
               |  - Exposure/Luminance     |
               |  - FOV (Circular Mask)    |
               |  - Resolution >= 300x300  |
               +---------------------------+
                             |
                   +---------+---------+
                   |                   |
               [FAILED]             [PASSED]
                   |                   |
                   v                   v
            +-------------+     +-------------------------------+
            |   RETAKE    |     |   EfficientNet-B3 Inference   |
            | (Prediction |     |   - 5 ICDR Severity Classes   |
            |   Bypassed) |     +-------------------------------+
            +-------------+                    |
                                               v
                                +-------------------------------+
                                |       Reliability Gate        |
                                |  - Confidence Score >= 0.85   |
                                |  - Top-1 vs Top-2 Margin      |
                                |  - Distribution Entropy       |
                                +-------------------------------+
                                               |
                           +-------------------+-------------------+
                           |                                       |
                     [High Quality &                         [Borderline /
                      High Confidence]                        Uncertain]
                           |                                       |
                           v                                       v
                    +--------------+                       +---------------+
                    |   ANALYZE    |                       | HUMAN_REVIEW  |
                    +--------------+                       +---------------+
                           \                                      /
                            \                                    /
                             v                                  v
                        +--------------------------------------------+
                        |      Grad-CAM Explainability Heatmap       |
                        |      (Fail-safe isolated execution)        |
                        +--------------------------------------------+
                                             |
                                             v
                        +--------------------------------------------+
                        |              Screening Result              |
                        |       (With Clinical Safety Notice)        |
                        +--------------------------------------------+
```

---

## 3. Komponen Teknis Utama

### 3.1 Evaluasi Kendali Mutu Citra (Quality Gate)
- **Indeks Ketajaman Laplacian**: Menghitung varian Laplacian operator pada kanal grayscale $\text{Var}(\nabla^2 I) \ge 0.40$. Citra bernilai $< 0.40$ diklasifikasikan sebagai *out-of-focus* atau goyang.
- **Keseimbangan Pencahayaan Kanal Hijau (*Green Channel*)**: Kanal hijau memuat kontras pembuluh darah retina tertinggi. Rata-rata iluminasi dibatasi pada rentang dinamis **15% – 85%** untuk mencegah *underexposure* (gelap) atau *overexposure* (silau).
- **Cakupan Bidang Pandang Retina (*Circular FOV Mask*)**: Deteksi kontur bola mata memastikan bidang pandang $\ge 45^\circ$, mencakup area makula lutea dan diskus optikus.

### 3.2 Inferensi 5-Kelas ICDR (EfficientNet-B3)
Mengklasifikasikan keparahan retinopati diabetik ke dalam 5 derajat standar internasional:
- **Derajat 0: No DR** (Mata Sehat / Normal)
- **Derajat 1: Mild NPDR** (Non-Proliferative Ringan)
- **Derajat 2: Moderate NPDR** (Non-Proliferative Sedang)
- **Derajat 3: Severe NPDR** (Non-Proliferative Berat - Aturan 4-2-1)
- **Derajat 4: PDR** (Proliferative Diabetic Retinopathy)

### 3.3 Evaluasi Keandalan Klinis (Reliability Gate)
- **Confidence Threshold**: Skor probabilitas kelas tertinggi wajib $\ge 0.85$.
- **Margin Threshold**: Selisih probabilitas kelas Top-1 terhadap Top-2 wajib $\ge 0.20$.
- **Shannon Entropy**: Distribusi probabilitas harus ber-entropi rendah ($\le 1.25$). Jika prediksi merata/bingung, sistem otomatis mengalihkan status ke `HUMAN_REVIEW`.

### 3.4 Multi-Format Model Loader
Layanan AI mendukung multi-backend pemuatan model:
1. **PyTorch**: Model berbobot `.pt` atau `.pth`.
2. **ONNX Runtime**: Model teroptimasi `.onnx` lintas platform.
3. **TensorFlow Lite**: Model ringan `.tflite` untuk efisiensi resource.
4. **Dynamic Heuristic Engine**: Fallback cerdas berbasis computer vision untuk pengujian lokal/CI/CD tanpa bobot biner besar.

---

## 4. Katalog Endpoint REST API AI Service

Layanan berjalan pada port internal `8003`:

| Rute Endpoint | Metode | Parameter | Deskripsi Fungsional |
| :--- | :---: | :--- | :--- |
| `/health` | `GET` | - | Status kesehatan layanan, model aktif, dan versi. |
| `/quality` | `POST` | `file` (multipart/form-data) | Evaluasi Quality Gate (ketajaman, kontras, FOV). |
| `/predict` | `POST` | `file` (multipart/form-data) | Inferensi 5-kelas ICDR & evaluasi keandalan. |
| `/screen` | `POST` | `file` (multipart/form-data) | **Unified Pipeline**: Quality Gate + Inference + Heatmap sekaligus. |
| `/gradcam` | `POST` | `file` (multipart/form-data), `target_class` | Menghasilkan heatmap visual atensi Grad-CAM. |

---

## 5. Panduan Instalasi & Eksekusi

### 5.1 Prasyarat
- Python `>= 3.10` (Disarankan Python 3.11+)
- OpenCV System Libraries (untuk Linux: `libgl1-mesa-glx libglib2.0-0`)

### 5.2 Setup Virtual Environment
```bash
cd ai-service

# Buat virtual environment
python -m venv .venv

# Aktivasi di Windows:
.venv\Scripts\activate

# Aktivasi di Linux/macOS:
source .venv/bin/activate

# Install dependensi
pip install -r requirements.txt
```

### 5.3 Menjalankan Server Inferensi
```bash
uvicorn app.main:app --host 127.0.0.1 --port 8003 --reload
```
Dokumentasi interaktif Swagger UI aktif di: `http://localhost:8003/docs`

### 5.4 Menjalankan Pengujian Pytest
```bash
python -m pytest tests -v
```
**Hasil Verifikasi: 20 / 20 Tests Passed (100% Green)**.
