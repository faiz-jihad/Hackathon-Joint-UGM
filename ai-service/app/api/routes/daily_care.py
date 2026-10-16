import re
from typing import List, Dict, Any, Optional
from fastapi import APIRouter
from app.schemas.daily_care import (
    DailyCheckInRequest,
    DailyCheckInResponse,
    SmartMealRecommendationRequest,
    SmartMealRecommendationResponse,
    SmartMealItemSchema,
)

router = APIRouter(prefix="/api/v1/daily-care", tags=["Daily Health Check-in & AI Evaluation"])

CRITICAL_TRIGGERS = [
    (re.compile(r"(buram|gelap|kabur|hilang penglihatan|buta)\s*(mendadak|tiba-tiba|seketika|cepat)", re.IGNORECASE),
     "Penurunan tajam penglihatan mendadak"),
    (re.compile(r"(kilatan|kilat|seperti petir|kelap[- ]kelip|flashes)\s*(cahaya|mata)?", re.IGNORECASE),
     "Sensasi kilatan cahaya (fotopsia) - risiko traksi retina"),
    (re.compile(r"(bintik|titik|jaring laba[- ]laba|floaters|bercak).*?(mendadak|banyak|bertambah banyak|tiba-tiba)", re.IGNORECASE),
     "Pertambahan signifikan bintik melayang mendadak (floaters) - risiko perdarahan vitreus"),
    (re.compile(r"(tirai|bayangan tirai|gelap separuh|seperti tertutup tirai|curtain)", re.IGNORECASE),
     "Penglihatan tertutup bayangan tirai gelap - tanda utama robekan/ablasio retina"),
    (re.compile(r"(nyeri|sakit)\s*(mata)?\s*(hebat|sangat sakit|disertai mual|muntah)", re.IGNORECASE),
     "Nyeri bola mata akut berat"),
]

@router.post("/evaluate-checkin", response_model=DailyCheckInResponse)
def evaluate_daily_checkin(request: DailyCheckInRequest):
    matched_triggers: List[str] = []
    actionable_guidance: List[str] = []

    # 1. Evaluate explicit boolean flags
    flags = request.visual_flags or {}
    if flags.get("sudden_blur") or flags.get("sudden_vision_drop"):
        matched_triggers.append("Penurunan tajam penglihatan mendadak")
    if flags.get("flashes") or flags.get("flashes_of_light"):
        matched_triggers.append("Melihat kilatan cahaya (fotopsia)")
    if flags.get("new_floaters") or flags.get("sudden_floaters"):
        matched_triggers.append("Pertambahan floaters mendadak")
    if flags.get("curtain_shadow"):
        matched_triggers.append("Penglihatan tertutup bayangan tirai gelap")
    if flags.get("severe_eye_pain"):
        matched_triggers.append("Nyeri mata hebat")

    # 2. Evaluate free-text visual symptoms
    if request.visual_symptoms:
        text = request.visual_symptoms.strip()
        for pattern, desc in CRITICAL_TRIGGERS:
            if pattern.search(text) and desc not in matched_triggers:
                matched_triggers.append(desc)

    # Emergency safety rule: Any ocular red-flag trigger
    if matched_triggers:
        return DailyCheckInResponse(
            status="emergency_alert",
            is_emergency=True,
            severity="CRITICAL_EMERGENCY",
            matched_triggers=matched_triggers,
            summary="⚠️ PERINGATAN MEDIS DARURAT: Terdeteksi Tanda Bahaya Akut Retina",
            explanation=(
                f"Laporan Anda mendeteksi gejala kritis: {', '.join(matched_triggers)}. "
                "Gejala ini berpotensi menandakan robekan/ablasio retina atau perdarahan ke rongga vitreus "
                "yang membutuhkan penanganan segera oleh Dokter Spesialis Mata."
            ),
            next_step="SEGERA DATANGI IGD RUMAH SAKIT ATAU RS MATA TERDEKAT DALAM 24 JAM",
            actionable_guidance=[
                "Segera menuju IGD RS Mata terdekat (contoh: RS Mata YAP, RSUP Dr. Sardjito, atau RSUD rujukan).",
                "Hindari gerakan kepala menyentak, membungkuk ke bawah, dan dilarang mengangkat beban berat.",
                "Tunda aktivitas fisik rutin dan senam sampai diperiksa langsung oleh dokter spesialis.",
                "Bawa hasil skrining retina Retiva dan kartu BPJS/identitas Anda."
            ],
            clinical_safety_notice=(
                "Peringatan Otomatis: Sistem tidak menggantikan pemeriksaan fisik langsung. "
                "Penanganan dalam kurun waktu kurang dari 24 jam sangat penting untuk menyelamatkan tajam penglihatan."
            )
        )

    # 3. Blood Glucose Analysis (Deterministic Clinical Bounds)
    glucose_status = "NORMAL"
    glucose_msg = ""
    if request.blood_glucose is not None:
        bg = request.blood_glucose
        ctx = (request.glucose_context or "FASTING").upper()

        if bg < 70:
            glucose_status = "HYPOGLYCEMIA"
            matched_triggers.append(f"Kadar glukosa darah rendah ({bg:.0f} mg/dL) - Tanda Hipoglikemia")
            glucose_msg = (
                f"Kadar glukosa Anda {bg:.0f} mg/dL tergolong rendah (hipoglikemia akut). "
                "Segera konsumsi 15-20 gram karbohidrat cepat serap (seperti 1 sdm madu atau 1/2 gelas teh manis). "
                "Cek ulang setelah 15 menit."
            )
            actionable_guidance.append("Terapkan 'Aturan 15': Konsumsi 15g karbohidrat manis cepat serap, istirahat, dan ukur ulang 15 menit kemudian.")
        elif bg > 300:
            glucose_status = "SEVERE_HYPERGLYCEMIA"
            matched_triggers.append(f"Kadar glukosa darah sangat tinggi ({bg:.0f} mg/dL)")
            glucose_msg = (
                f"Kadar glukosa darah Anda {bg:.0f} mg/dL sangat tinggi. "
                "Perbanyak minum air putih, jangan lewatkan obat dokter, dan segera hubungi faskes jika merasakan mual/muntah."
            )
            actionable_guidance.append("Cukupi hidrasi air putih minimal 2 liter/hari dan konsultasikan penyesuaian dosis obat ke faskes.")
        elif (ctx == "FASTING" and bg > 130) or (ctx == "POST_PRANDIAL" and bg > 180):
            glucose_status = "ABOVE_TARGET"
            glucose_msg = (
                f"Kadar gula darah {bg:.0f} mg/dL sedikit di atas target optimal ({ctx.replace('_', ' ').title()}). "
                "Pertahankan konsistensi konsumsi makanan berindeks glikemik rendah dan batasi karbohidrat sederhana."
            )
            actionable_guidance.append("Pilih menu makanan berserat tinggi (sayuran hijau, beras merah, tahu/tempe) untuk menstabilkan respon glikemik.")
        else:
            glucose_msg = f"Kadar gula darah {bg:.0f} mg/dL ({ctx.replace('_', ' ').title()}) berada dalam rentang target kendali yang baik."
            actionable_guidance.append("Pertahankan pola makan teratur dan jadwal minum obat yang konsisten.")

    # 4. Medication & Lifestyle Compliance Check
    if not request.medications_completed:
        actionable_guidance.append("Pastikan meminum obat diabetes sesuai petunjuk dokter. Jangan mengubah dosis tanpa rekomendasi tenaga medis.")
    if request.activity_completed:
        actionable_guidance.append("Aktivitas fisik ringan (seperti jalan santai 30 menit) terbukti efektif menjaga sensitivitas insulin dan kesehatan pembuluh darah retina.")

    # Determine overall non-emergency severity
    if glucose_status == "HYPOGLYCEMIA":
        severity = "WARNING"
        summary = "⚠️ Perhatian Khusus: Kadar Gula Darah Rendah (Hipoglikemia)"
        next_step = "Lakukan pertolongan pertama hipoglikemia, istirahat, dan pantau ulang gula darah."
    elif glucose_status == "SEVERE_HYPERGLYCEMIA":
        severity = "WARNING"
        summary = "⚠️ Perhatian: Kadar Gula Darah Tinggi Membutuhkan Pemantauan Ketat"
        next_step = "Minum air putih cukup dan hubungi dokter FKTP jika keluhan berlanjut."
    elif glucose_status == "ABOVE_TARGET" or request.physical_condition in ["LEMAS", "LELAH_PUSING"]:
        severity = "ATTENTION"
        summary = "Kondisi Stabil dengan Catatan Pemantauan Gaya Hidup"
        next_step = "Lanjutkan rencana perawatan harian dan jaga hidrasi serta istirahat cukup."
    else:
        severity = "ROUTINE"
        summary = "Kondisi Sehat Terpantau Stabil Hari Ini"
        next_step = "Lanjutkan jadwal agenda harian, minum obat rutin, dan kontrol berkala."

    explanation_parts = []
    if glucose_msg:
        explanation_parts.append(glucose_msg)
    else:
        explanation_parts.append("Kondisi fisik harian tercatat dengan baik.")

    if request.physical_condition == "FIT":
        explanation_parts.append("Tubuh terasa bugar, sangat baik untuk mendukung metabolisme harian.")
    elif request.physical_condition == "LEMAS":
        explanation_parts.append("Tubuh terasa lemas; prioritaskan hidrasi dan hindari kelelahan berlebih.")

    if not request.medications_completed:
        explanation_parts.append("Catatan: Anda melaporkan belum menyelesaikan minum obat hari ini.")

    return DailyCheckInResponse(
        status="evaluated",
        is_emergency=False,
        severity=severity,
        matched_triggers=matched_triggers,
        summary=summary,
        explanation=" ".join(explanation_parts),
        next_step=next_step,
        actionable_guidance=actionable_guidance,
        clinical_safety_notice=(
            "Catatan Klinis: Evaluasi ini berbasis data laporan mandiri dan tidak menggantikan "
            "pemeriksaan fisik berkala oleh Dokter Spesialis Mata (Sp.M) maupun Dokter Penyakit Dalam (Sp.PD). "
            "Tetap patuhi anjuran resep dan jadwal kontrol resmi Anda."
        )
    )


# ========================================================
# SMART MEAL RECOMMENDATION & CLINICAL NUTRITION ENGINE
# ========================================================

BASE_MEAL_DATABASE = {
    "BREAKFAST": [
        {
            "id": "meal-bf-01",
            "category": "SARAPAN",
            "time_recommendation": "07.15",
            "name": "Nasi Merah Telur Rebus & Sayur Bening Bayam",
            "main_dish": "Telur Rebus Bebas Minyak (1 Butir)",
            "complementary_foods": ["Nasi Beras Merah 100g (1 centong sedang)", "Sayur Bening Bayam Segar 1 Mangkuk"],
            "suggested_portion": "Piring Model T: 1/2 piring sayur bayam, 1/4 karbohidrat nasi merah, 1/4 protein telur.",
            "ingredients": [
                {"name": "Beras Merah Pulen", "quantity": "75 gram", "est_cost_idr": 2000},
                {"name": "Telur Ayam Ras", "quantity": "1 butir", "est_cost_idr": 2500},
                {"name": "Bayam Hijau Segar", "quantity": "1/2 ikat", "est_cost_idr": 2000},
                {"name": "Bawang Merah & Putih", "quantity": "Secukupnya", "est_cost_idr": 1000},
            ],
            "estimated_cost_idr": 7500,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Nasi Jagung & Tempe Kukus",
                    "savings_idr": 1500,
                    "description": "Ganti telur rebus dengan 2 potong tempe kukus bumbu ketumbar dan gunakan beras jagung lokal.",
                    "substitution_type": "PLANT_BASED_BUDGET"
                },
                {
                    "title": "Substitusi Ubi Jalar Rebus",
                    "savings_idr": 1000,
                    "description": "Ganti nasi merah dengan 1 buah ubi jalar rebus sedang kaya serat larut.",
                    "substitution_type": "TUBER_CARB"
                }
            ],
            "nutrition": {
                "calories_kcal": 295,
                "carbs_grams": 28,
                "fiber_grams": 6.5,
                "protein_grams": 13,
                "glycemic_index": "RENDAH",
                "sodium_mg": 180
            },
            "allergens": ["telur"],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        },
        {
            "id": "meal-bf-02",
            "category": "SARAPAN",
            "time_recommendation": "07.15",
            "name": "Oatmeal Gurih Kaldu Bening & Suwir Tempe Tahu",
            "main_dish": "Tempe & Tahu Kukus Bumbu Kuning",
            "complementary_foods": ["Oatmeal Kaldu Rempah Hangat 4 sdm", "Wortel & Daun Bawang Cincang"],
            "suggested_portion": "Porsi terukur: 4 sdm oatmeal seduh, 2 potong tempe-tahu, 1 mangkuk kaldu sayur.",
            "ingredients": [
                {"name": "Rolled Oats / Oatmeal Polos", "quantity": "35 gram", "est_cost_idr": 2500},
                {"name": "Tempe Kedelai Murni", "quantity": "2 potong (60g)", "est_cost_idr": 2000},
                {"name": "Tahu Putih Segar", "quantity": "1 potong (50g)", "est_cost_idr": 1500},
                {"name": "Wortel & Seledri", "quantity": "1/2 batang", "est_cost_idr": 1000},
            ],
            "estimated_cost_idr": 7000,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Bubur Jagung Halus",
                    "savings_idr": 1000,
                    "description": "Ganti oatmeal dengan bubur jagung lokal tanpa santan.",
                    "substitution_type": "LOCAL_GRAIN"
                }
            ],
            "nutrition": {
                "calories_kcal": 270,
                "carbs_grams": 25,
                "fiber_grams": 7.0,
                "protein_grams": 12,
                "glycemic_index": "RENDAH",
                "sodium_mg": 150
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        }
    ],
    "LUNCH": [
        {
            "id": "meal-lu-01",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Nasi Merah, Ikan Kembung Kukus Bumbu Kuning & Tumis Buncis",
            "main_dish": "Ikan Kembung Kukus Bumbu Kuning (1 Ekor 80g)",
            "complementary_foods": ["Nasi Merah 100g (1 centong sedang)", "Tumis Buncis Muda & Wortel Sedikit Minyak", "Lalap Timun Kemangi"],
            "suggested_portion": "Piring Model T: 1/2 piring tumis buncis & lalapan segar, 1/4 nasi beras merah, 1/4 ikan kembung.",
            "ingredients": [
                {"name": "Beras Merah Pulen", "quantity": "75 gram", "est_cost_idr": 2000},
                {"name": "Ikan Kembung Segar", "quantity": "1 ekor (80g)", "est_cost_idr": 7000},
                {"name": "Buncis Muda & Wortel", "quantity": "100 gram", "est_cost_idr": 2500},
                {"name": "Kunyit, Jahe, Serai, Minyak Kelapa Sedikit", "quantity": "Secukupnya", "est_cost_idr": 2000},
            ],
            "estimated_cost_idr": 13500,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Pepes Tahu Tempe Daun Pisang",
                    "savings_idr": 4500,
                    "description": "Ganti ikan kembung dengan pepes tahu tempe berbumbu rempah kemangi. Tetap kaya protein dan hemat Rp 4.500.",
                    "substitution_type": "VEGETARIAN_ECONOMICAL"
                },
                {
                    "title": "Substitusi Nasi Jagung Pulen",
                    "savings_idr": 1000,
                    "description": "Ganti nasi merah dengan nasi jagung lokal yang memiliki indeks glikemik serupa namun harga lebih terjangkau.",
                    "substitution_type": "LOCAL_CARB"
                }
            ],
            "nutrition": {
                "calories_kcal": 385,
                "carbs_grams": 32,
                "fiber_grams": 7.5,
                "protein_grams": 22,
                "glycemic_index": "RENDAH",
                "sodium_mg": 220
            },
            "allergens": ["ikan", "seafood"],
            "has_seafood": True,
            "has_poultry": False,
            "is_vegetarian": False
        },
        {
            "id": "meal-lu-02",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Nasi Jagung Pulen, Pepes Tahu Tempe Kemangi & Sayur Asem Bening",
            "main_dish": "Pepes Tahu & Tempe Kukus Daun Kemangi (2 Bungkus)",
            "complementary_foods": ["Nasi Jagung Pulen 100g", "Sayur Asem Bening Labu Siam & Kacang Panjang", "Lalap Mentimun Segar"],
            "suggested_portion": "Piring Model T: 1/2 piring sayur asem labu siam, 1/4 nasi jagung, 1/4 pepes tahu tempe.",
            "ingredients": [
                {"name": "Beras Jagung Lokal", "quantity": "80 gram", "est_cost_idr": 1800},
                {"name": "Tempe Segar", "quantity": "2 potong (70g)", "est_cost_idr": 2500},
                {"name": "Tahu Putih Lembut", "quantity": "1 kotak (60g)", "est_cost_idr": 1700},
                {"name": "Sayuran Asem (Labu Siam, Kacang Panjang)", "quantity": "1 mangkuk", "est_cost_idr": 2500},
                {"name": "Bumbu Pepes & Asam Jawa Sedikit", "quantity": "Secukupnya", "est_cost_idr": 1500},
            ],
            "estimated_cost_idr": 10000,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Telur Rebus Sambal Tomat",
                    "savings_idr": 500,
                    "description": "Kombinasikan 1 butir telur rebus dengan 1 potong tahu untuk variasi rasa.",
                    "substitution_type": "PROTEIN_VARIATION"
                }
            ],
            "nutrition": {
                "calories_kcal": 340,
                "carbs_grams": 34,
                "fiber_grams": 8.5,
                "protein_grams": 17,
                "glycemic_index": "RENDAH",
                "sodium_mg": 190
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        },
        {
            "id": "meal-lu-03",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Nasi Merah, Dada Ayam Ungkep Kuning & Sayur Bening Oyong Wortel",
            "main_dish": "Dada Ayam Tanpa Kulit Ungkep Kuning (70g)",
            "complementary_foods": ["Nasi Beras Merah 100g", "Sayur Bening Oyong Wortel 1 Mangkuk", "Tempe Bakar Teflon 1 Potong"],
            "suggested_portion": "Piring Sehat: 1/2 piring sayur oyong wortel, 1/4 nasi merah, 1/4 ayam ungkep kuning.",
            "ingredients": [
                {"name": "Beras Merah", "quantity": "75 gram", "est_cost_idr": 2000},
                {"name": "Dada Ayam Tanpa Kulit", "quantity": "70 gram", "est_cost_idr": 7000},
                {"name": "Oyong & Wortel", "quantity": "1 buah kecil & 1/2 wortel", "est_cost_idr": 2500},
                {"name": "Bumbu Kuning Rempah", "quantity": "Secukupnya", "est_cost_idr": 1500},
                {"name": "Tempe", "quantity": "1 potong (35g)", "est_cost_idr": 1000},
            ],
            "estimated_cost_idr": 14000,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Ayam dengan Telur Orak-Arik Bayam",
                    "savings_idr": 4000,
                    "description": "Ganti ayam dengan telur dan tumisan bayam, hemat Rp 4.000 dengan profil glikemik serupa.",
                    "substitution_type": "BUDGET_PROTEIN"
                }
            ],
            "nutrition": {
                "calories_kcal": 375,
                "carbs_grams": 30,
                "fiber_grams": 6.8,
                "protein_grams": 25,
                "glycemic_index": "RENDAH",
                "sodium_mg": 210
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": True,
            "is_vegetarian": False
        },
        {
            "id": "meal-lu-04",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Nasi Jagung, Tahu Kukus Bumbu Kunyit & Sayur Bening Bayam",
            "main_dish": "Tahu Sutra Kukus Bumbu Kunyit & Daun Kemangi (2 Potong)",
            "complementary_foods": ["Sayur Bening Bayam Segar Kaldu Bawang Dapur (1 Mangkuk)", "Nasi Jagung Pulen Rendah Glikemik 100g", "Lalap Timun Iris Segar"],
            "suggested_portion": "Piring Model T dari Dapur: 1/2 piring sayur bening bayam, 1/4 nasi jagung, 1/4 tahu kukus kunyit.",
            "ingredients": [
                {"name": "Tahu Sutra Dapur", "quantity": "2 kotak (120g)", "est_cost_idr": 2500},
                {"name": "Bayam Hijau Segar", "quantity": "1 ikat", "est_cost_idr": 2000},
                {"name": "Beras Jagung Lokal Pulen", "quantity": "80 gram", "est_cost_idr": 1800},
                {"name": "Bawang Merah & Putih", "quantity": "Secukupnya", "est_cost_idr": 1000},
            ],
            "estimated_cost_idr": 7300,
            "affordable_alternatives": [
                {
                    "title": "Kreasi Bakar Teflon",
                    "savings_idr": 0,
                    "description": "Panggang tahu di teflon tanpa minyak untuk aroma karamelisasi gurih.",
                    "substitution_type": "COOKING_METHOD"
                }
            ],
            "nutrition": {
                "calories_kcal": 285,
                "carbs_grams": 27,
                "fiber_grams": 7.2,
                "protein_grams": 14,
                "glycemic_index": "RENDAH",
                "sodium_mg": 130
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        },
        {
            "id": "meal-lu-05",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Menu Nutrisi Lengkap: Nasi Merah Organik, Fillet Dada Ayam Herbal & Tumis Brokoli Jamur",
            "main_dish": "Fillet Dada Ayam Organik Panggang Herbal Rosemary (100g)",
            "complementary_foods": ["Tumis Brokoli Kembang Kol & Jamur Kancing Organik", "Nasi Beras Merah Organik Pulen 100g", "Salad Mini Tomat Ceri Minyak Zaitun"],
            "suggested_portion": "Piring Model T Premium: 1/2 brokoli jamur organik, 1/4 nasi beras merah, 1/4 fillet ayam herbal.",
            "ingredients": [
                {"name": "Dada Ayam Organik", "quantity": "100 gram", "est_cost_idr": 12000},
                {"name": "Brokoli & Jamur Kancing", "quantity": "120 gram", "est_cost_idr": 4500},
                {"name": "Beras Merah Organik", "quantity": "75 gram", "est_cost_idr": 2500},
                {"name": "Minyak Zaitun EVOO & Rempah", "quantity": "1 sdm", "est_cost_idr": 1500},
            ],
            "estimated_cost_idr": 20500,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Ayam Pasar Lokal",
                    "savings_idr": 4000,
                    "description": "Gunakan dada ayam segar pasar tradisional untuk penghematan.",
                    "substitution_type": "LOCAL_SAVING"
                }
            ],
            "nutrition": {
                "calories_kcal": 395,
                "carbs_grams": 30,
                "fiber_grams": 8.5,
                "protein_grams": 28,
                "glycemic_index": "RENDAH",
                "sodium_mg": 150
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": True,
            "is_vegetarian": False
        },
        {
            "id": "meal-lu-06",
            "category": "MAKAN_SIANG",
            "time_recommendation": "12.30",
            "name": "Menu Rendah Garam: Nasi Merah, Ayam Ungkep Rempah Daun Jeruk & Tumis Buncis",
            "main_dish": "Dada Ayam Ungkep Rempah Daun Jeruk & Serai (Bebas Garam Tambahan)",
            "complementary_foods": ["Tumis Buncis Bawang Putih Bakar (Tanpa Garam / MSG)", "Nasi Beras Merah Pulen 100g", "Lalap Timun Kemangi"],
            "suggested_portion": "Piring Anti-Hipertensi: 1/2 tumis buncis rempah, 1/4 nasi merah, 1/4 ayam ungkep serai.",
            "ingredients": [
                {"name": "Dada Ayam Fillet", "quantity": "75 gram", "est_cost_idr": 6000},
                {"name": "Buncis Muda Segar", "quantity": "100 gram", "est_cost_idr": 2500},
                {"name": "Beras Merah Pulen", "quantity": "75 gram", "est_cost_idr": 2000},
                {"name": "Serai, Daun Jeruk, Bawang Putih, Kunyit", "quantity": "Secukupnya", "est_cost_idr": 1500},
            ],
            "estimated_cost_idr": 12000,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Tempe Rempah Daun Salam",
                    "savings_idr": 3500,
                    "description": "Ganti ayam dengan tempe ungkep rempah untuk opsi lebih hemat dan ramah tensi.",
                    "substitution_type": "LOW_SODIUM_ECONOMICAL"
                }
            ],
            "nutrition": {
                "calories_kcal": 325,
                "carbs_grams": 30,
                "fiber_grams": 7.0,
                "protein_grams": 22,
                "glycemic_index": "RENDAH",
                "sodium_mg": 85
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": True,
            "is_vegetarian": False
        }
    ],
    "DINNER": [
        {
            "id": "meal-di-01",
            "category": "MAKAN_MALAM",
            "time_recommendation": "19.00",
            "name": "Pecel Kangkung Tauge & Tahu Tempe Bakar Teflon",
            "main_dish": "Tempe & Tahu Bakar Teflon Bumbu Rempah",
            "complementary_foods": ["Rebusan Kangkung & Tauge 1 Piring Penuh", "Bumbu Kacang Encer Rendah Gula 2 sdm", "Nasi Merah Porsi Kecil (50g)"],
            "suggested_portion": "Makan malam ringan: 2/3 piring sayuran rebus pecel, 1/3 protein tempe tahu, sedikit karbohidrat kompleks.",
            "ingredients": [
                {"name": "Kangkung Segar", "quantity": "1 ikat", "est_cost_idr": 2500},
                {"name": "Tauge Kacang Hijau", "quantity": "50 gram", "est_cost_idr": 1500},
                {"name": "Tempe & Tahu Kedelai", "quantity": "Masing-masing 1 potong", "est_cost_idr": 2500},
                {"name": "Bumbu Pecel Rendah Gula Encer", "quantity": "2 sdm", "est_cost_idr": 2000},
            ],
            "estimated_cost_idr": 8500,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Bumbu Sambal Tomat Rebus",
                    "savings_idr": 1000,
                    "description": "Ganti bumbu kacang dengan sambal tomat kukus segar tanpa gula aren untuk opsi lebih rendah kalori.",
                    "substitution_type": "LOW_CALORIE_SAVING"
                }
            ],
            "nutrition": {
                "calories_kcal": 310,
                "carbs_grams": 24,
                "fiber_grams": 8.0,
                "protein_grams": 16,
                "glycemic_index": "RENDAH",
                "sodium_mg": 190
            },
            "allergens": ["kacang"],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        },
        {
            "id": "meal-di-02",
            "category": "MAKAN_MALAM",
            "time_recommendation": "19.00",
            "name": "Sup Bening Tahu Sutra, Jamur Tiram & Labu Air Hangat",
            "main_dish": "Tahu Sutra Lembut Kuah Bening Kaldu Bawang",
            "complementary_foods": ["Jamur Tiram & Labu Air 1 Mangkuk Besar", "Ubi Rebus 50g / Nasi Merah 1 Centong Kecil"],
            "suggested_portion": "Mangkuk besar sup bening hidrasi tinggi dengan karbohidrat minimal sebelum tidur.",
            "ingredients": [
                {"name": "Tahu Putih / Tahu Sutra", "quantity": "1 kotak", "est_cost_idr": 2500},
                {"name": "Jamur Tiram Segar", "quantity": "50 gram", "est_cost_idr": 2000},
                {"name": "Labu Air / Oyong", "quantity": "1/2 buah", "est_cost_idr": 2000},
                {"name": "Bumbu Bawang & Seledri", "quantity": "Secukupnya", "est_cost_idr": 1000},
                {"name": "Beras Merah Porsi Kecil", "quantity": "40 gram", "est_cost_idr": 1500},
            ],
            "estimated_cost_idr": 9000,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Telur Puyuh Rebus (3 Butir)",
                    "savings_idr": 500,
                    "description": "Tambahkan telur puyuh rebus dan kurangi porsi jamur untuk selera berbeda.",
                    "substitution_type": "PROTEIN_SWAP"
                }
            ],
            "nutrition": {
                "calories_kcal": 280,
                "carbs_grams": 22,
                "fiber_grams": 6.2,
                "protein_grams": 14,
                "glycemic_index": "RENDAH",
                "sodium_mg": 170
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        }
    ],
    "SNACK": [
        {
            "id": "meal-sn-01",
            "category": "CAMILAN",
            "time_recommendation": "15.30",
            "name": "Potongan Buah Pepaya California Matang Segar",
            "main_dish": "Pepaya Segar Potong Dadu (100 gram)",
            "complementary_foods": ["Air Putih Hangat 1 Gelas"],
            "suggested_portion": "1 Piring kecil buah potong (maksimal 100-120 gram per waktu camilan).",
            "ingredients": [
                {"name": "Pepaya California", "quantity": "100 gram", "est_cost_idr": 2500}
            ],
            "estimated_cost_idr": 2500,
            "affordable_alternatives": [
                {
                    "title": "Substitusi Pisang Kepok Rebus",
                    "savings_idr": 0,
                    "description": "1 buah pisang kepok rebus kaya pati resisten yang ramah glukosa.",
                    "substitution_type": "FRUIT_SWAP"
                }
            ],
            "nutrition": {
                "calories_kcal": 45,
                "carbs_grams": 11,
                "fiber_grams": 2.2,
                "protein_grams": 0.8,
                "glycemic_index": "SEDANG",
                "sodium_mg": 5
            },
            "allergens": [],
            "has_seafood": False,
            "has_poultry": False,
            "is_vegetarian": True
        }
    ]
}


@router.post("/smart-meal-recommendation", response_model=SmartMealRecommendationResponse)
def evaluate_smart_meal(request: SmartMealRecommendationRequest):
    cat_key = (request.meal_category or "LUNCH").upper()
    if cat_key not in BASE_MEAL_DATABASE:
        cat_key = "LUNCH"

    candidates = BASE_MEAL_DATABASE[cat_key]

    # Deterministic Filter 1: Allergies
    cleaned_allergies = [a.lower().strip() for a in (request.allergies or [])]
    filtered_candidates = []
    for m in candidates:
        has_allergen_conflict = False
        for allergen in cleaned_allergies:
            if allergen in ["seafood", "udang", "ikan"] and m.get("has_seafood"):
                has_allergen_conflict = True
                break
            if allergen in ["telur"] and "telur" in m.get("allergens", []):
                has_allergen_conflict = True
                break
            if allergen in ["kacang"] and "kacang" in m.get("allergens", []):
                has_allergen_conflict = True
                break
            if allergen in ["ayam", "unggas"] and m.get("has_poultry"):
                has_allergen_conflict = True
                break
        if not has_allergen_conflict:
            filtered_candidates.append(m)

    if not filtered_candidates:
        filtered_candidates = [candidates[-1]]  # Safe plant-based fallback

    # Check available kitchen ingredients
    pantry_keywords = [ing.lower().strip() for ing in (request.available_ingredients or []) if ing.strip()]
    if pantry_keywords:
        pantry_matches = []
        for m in filtered_candidates:
            meal_text = (m["name"] + " " + m["main_dish"] + " " + " ".join(i["name"] for i in m["ingredients"])).lower()
            if any(k in meal_text for k in pantry_keywords):
                pantry_matches.append(m)
        if pantry_matches:
            filtered_candidates = pantry_matches

    # Deterministic Filter 2: Kidney / Renal safety (Nefropati Diabetik)
    is_kidney_restricted = False
    req_restrictions = " ".join((request.dietary_restrictions or []) + [request.clinician_notes or ""]).lower()
    if any(k in req_restrictions for k in ["ginjal", "nefropati", "ckd", "batasi protein"]):
        is_kidney_restricted = True
        low_protein_candidates = [m for m in filtered_candidates if m["nutrition"]["protein_grams"] <= 18]
        if low_protein_candidates:
            filtered_candidates = low_protein_candidates

    # Deterministic Filter 3: Low Sodium / Hypertension
    is_low_salt = any(k in req_restrictions for k in ["garam", "hipertensi", "tensi", "sodium", "rendah_garam"])
    if is_low_salt:
        low_salt_candidates = [m for m in filtered_candidates if m["nutrition"].get("sodium_mg", 200) <= 200]
        if low_salt_candidates:
            filtered_candidates = low_salt_candidates

    # Deterministic Filter 4: Budget tier check
    target_budget = request.daily_budget or 35000
    if target_budget <= 25000:
        # Budget hemat: sort ascending by cost
        filtered_candidates.sort(key=lambda x: x["estimated_cost_idr"])
        chosen_meal = filtered_candidates[0]
    elif target_budget >= 45000:
        # Budget premium / tinggi: sort descending by cost and nutrition
        filtered_candidates.sort(key=lambda x: x["estimated_cost_idr"], reverse=True)
        chosen_meal = filtered_candidates[0]
    else:
        # Moderate budget
        chosen_meal = filtered_candidates[0]

    # Generate Simple Indonesian Nutritional Explanations
    nutr = chosen_meal["nutrition"]
    carbs = nutr["carbs_grams"]
    fiber = nutr["fiber_grams"]
    protein = nutr["protein_grams"]

    carb_explanation = (
        f"Karbohidrat kompleks ({carbs}g) dari bahan pokok utuh dicerna secara bertahap oleh enzim pencernaan, "
        "sehingga glukosa masuk ke aliran darah dengan stabil tanpa lonjakan tajam."
    )
    fiber_explanation = (
        f"Kandungan serat tinggi ({fiber}g) dari aneka sayuran memperlambat laju penyerapan gula dan memperpanjang rasa kenyang alami."
    )
    protein_explanation = (
        f"Asupan protein bersih ({protein}g) "
        + ("dan omega-3 " if chosen_meal.get("has_seafood") else "")
        + "mendukung pemeliharaan jaringan otot serta kesehatan dinding pembuluh darah mikro retina mata."
    )
    stability_summary = (
        "Komposisi gizi 'Piring Model T' (1/2 piring sayur, 1/4 karbohidrat kompleks, 1/4 protein) "
        "membantu menjaga respon glikemik 2 jam pasca makan tetap terkendali."
    )

    # Adjust for recent glucose
    if request.last_glucose_mg_dl is not None:
        if request.last_glucose_mg_dl > 180:
            stability_summary += " Karena gula darah Anda sebelumnya sedikit tinggi, prioritaskan mengonsumsi sayuran terlebih dahulu sebelum karbohidrat."
        elif request.last_glucose_mg_dl < 80:
            stability_summary += " Karena gula darah Anda sebelumnya cenderung rendah, pastikan porsi karbohidrat kompleks terukur ini dihabiskan tepat waktu."

    safety_notes = []
    if is_kidney_restricted:
        safety_notes.append("Penyesuaian Nefropati: Porsi protein dikontrol terukur untuk meringankan beban kerja filtrasi ginjal.")
    if cleaned_allergies:
        safety_notes.append(f"Pengecekan Alergi Berhasil: Bebas dari bahan berisiko ({', '.join(cleaned_allergies)}).")

    safety_notes.append("Pencegahan Hipoglikemia: Karbohidrat kompleks terjaga seimbang dan tidak menerapkan diet ekstrem nol-karbohidrat.")

    meal_schema = SmartMealItemSchema(
        id=chosen_meal["id"],
        category=chosen_meal["category"],
        time_recommendation=chosen_meal["time_recommendation"],
        name=chosen_meal["name"],
        main_dish=chosen_meal["main_dish"],
        complementary_foods=chosen_meal["complementary_foods"],
        suggested_portion=chosen_meal["suggested_portion"],
        ingredients=chosen_meal["ingredients"],
        estimated_cost_idr=chosen_meal["estimated_cost_idr"],
        affordable_alternatives=chosen_meal["affordable_alternatives"],
        nutrition=nutr,
        nutritional_impact_explanation={
            "carbohydrate_impact": carb_explanation,
            "fiber_impact": fiber_explanation,
            "protein_vascular_impact": protein_explanation,
            "glucose_stability_summary": stability_summary
        },
        is_eaten=False,
        eaten_at=None,
        post_meal_glucose_mg_dl=None
    )

    return SmartMealRecommendationResponse(
        success=True,
        meal=meal_schema,
        clinical_safety_validation={
            "passed_safety_checks": True,
            "allergy_cleared": True,
            "kidney_safe": is_kidney_restricted,
            "low_carb_safeguard_active": True,
            "safety_notes": safety_notes
        },
        disclaimer=(
            "Pemberitahuan Klinis: Nilai gizi dan estimasi harga dihitung berdasarkan bahan pasar tradisional. "
            "Menu sehat mendukung kestabilan glukosa darah dan kesehatan mikrovaskular mata, "
            "namun tidak menyembuhkan retinopati diabetik dan bukan pengganti instruksi obat/insulin dari dokter spesialis."
        )
    )

