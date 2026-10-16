import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ClinicalHelpers {
  static String normalizeClass(String? raw) {
    if (raw == null || raw.isEmpty) return 'MODERATE_DR';
    final upper = raw.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (upper == 'NO_DR' || upper == 'NO' || upper == 'NORMAL') return 'NO_DR';
    if (upper == 'MILD' || upper == 'MILD_DR' || upper == 'MILD_NPDR') return 'MILD_DR';
    if (upper == 'MODERATE' || upper == 'MODERATE_DR' || upper == 'MODERATE_NPDR') return 'MODERATE_DR';
    if (upper == 'SEVERE' || upper == 'SEVERE_DR' || upper == 'SEVERE_NPDR') return 'SEVERE_DR';
    if (upper == 'PROLIFERATIVE_DR' || upper == 'PROLIFERATIVE' || upper == 'PDR') return 'PROLIFERATIVE_DR';
    return upper;
  }

  static String getSeverityTitle(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Tidak Tampak DR (Derajat 0)';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'NPDR Ringan (Derajat 1)';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'NPDR Sedang (Derajat 2)';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'NPDR Berat (Derajat 3)';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'PDR Proliferatif (Derajat 4)';
      default:
        return 'Belum Terklasifikasi';
    }
  }

  static String getSeverityDescription(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Tidak ditemukan tanda lesi mikrovaskular retina. Makula dan diskus optikus tampak tenang.';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'Ditemukan mikroaneurisma fokal terisolasi tanpa eksudat atau perdarahan intraretina luas.';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'Ditemukan mikroaneurisma multipel, perdarahan dot-blot, eksudat keras, atau cotton-wool spots.';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'Memenuhi salah satu kriteria aturan 4-2-1 Perdami. Risiko konversi ke proliferatif tinggi dalam 1 tahun.';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'Ditemukan neovaskularisasi retina/diskus (NVD/NVE), perdarahan vitreus, atau ablasio traksional.';
      default:
        return 'Menunggu evaluasi hasil inferensi.';
    }
  }

  static Color getSeverityColor(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return AppColors.statusGreen;
      case 'MILD_DR':
      case 'MILD_NPDR':
        return AppColors.statusYellow;
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return AppColors.statusOrange;
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return AppColors.statusRed;
      default:
        return AppColors.textMuted;
    }
  }

  static Color getSeveritySurfaceColor(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return AppColors.statusGreenSurface;
      case 'MILD_DR':
      case 'MILD_NPDR':
        return AppColors.statusYellowSurface;
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return AppColors.statusOrangeSurface;
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return AppColors.statusRedSurface;
      default:
        return AppColors.background;
    }
  }

  static String getPerdamiInterval(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'Kontrol Ulang 12 Bulan (FKTP)';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'Kontrol Ulang 6–12 Bulan (FKTP)';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'Rujukan Sp.M dalam 3–6 Bulan (FKRTL)';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'Rujukan Cepat 2–4 Minggu (FKRTL / Laser PRP)';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'Rujukan Darurat Segera (< 1–2 Minggu)';
      default:
        return 'Sesuai arahan klinisi';
    }
  }

  static String getIcd10Code(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return 'ICD-10 H36.00 / Z01.0 (Pemeriksaan Mata Normal Tanpa DR)';
      case 'MILD_DR':
      case 'MILD_NPDR':
        return 'ICD-10 H36.01 (Retinopati Diabetika Non-Proliferatif Ringan)';
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return 'ICD-10 H36.03 (Retinopati Diabetika Non-Proliferatif Sedang)';
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return 'ICD-10 H36.04 (Retinopati Diabetika Non-Proliferatif Berat)';
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 'ICD-10 H36.05 (Retinopati Diabetika Proliferatif)';
      default:
        return 'ICD-10 H36.0 (Retinopati Diabetika)';
    }
  }

  static List<Map<String, dynamic>> getBiomarkers(String? classification) {
    final c = classification?.toUpperCase() ?? '';
    final isNo = c == 'NO_DR';
    final isMild = c == 'MILD_DR' || c == 'MILD_NPDR';
    final isMod = c == 'MODERATE_DR' || c == 'MODERATE_NPDR';
    final isSev = c == 'SEVERE_DR' || c == 'SEVERE_NPDR';
    final isPdr = c == 'PROLIFERATIVE_DR' || c == 'PDR';

    return [
      {
        'name': 'Mikroaneurisma (MA)',
        'detected': !isNo,
        'level': isNo ? 'Negatif' : (isMild ? 'Minimal (1-3)' : (isMod ? 'Moderat' : 'Difus (>20)')),
        'desc': 'Dilatasi sakular fokal pada dinding kapiler retina akibat hilangnya perisit.',
        'isCritical': isSev || isPdr,
      },
      {
        'name': 'Perdarahan Intraretina (Dot/Blot)',
        'detected': isMod || isSev || isPdr,
        'level': (isMod || isSev || isPdr) ? (isSev || isPdr ? 'Masif (4 Kuadran)' : 'Ada (Temporal/Nasal)') : 'Negatif',
        'desc': 'Kebocoran eritrosit di lapisan pleksiform dalam akibat mikroangiopati kronis.',
        'isCritical': isSev || isPdr,
      },
      {
        'name': 'Eksudat Keras (Hard Exudates)',
        'detected': isMod || isSev || isPdr,
        'level': (isMod || isSev || isPdr) ? 'Ada (Perimacular)' : 'Negatif',
        'desc': 'Presipitasi lipoprotein & lipid akibat gangguan sawar darah-retina (blood-retinal barrier).',
        'isCritical': false,
      },
      {
        'name': 'Bercak Wol Katun (Cotton Wool Spots)',
        'detected': isSev || isPdr,
        'level': (isSev || isPdr) ? 'Ada (≥2 Kuadran)' : 'Negatif',
        'desc': 'Infark mikroaksonal pada lapisan serat saraf retina (RNFL) karena iskemia lokal.',
        'isCritical': isSev || isPdr,
      },
      {
        'name': 'Neovaskularisasi (NVD/NVE)',
        'detected': isPdr,
        'level': isPdr ? 'Positif (Diskus/Retina)' : 'Negatif',
        'desc': 'Pembentukan pembuluh darah baru abnormal yang rapuh dipicu hipersekresi VEGF.',
        'isCritical': isPdr,
      },
      {
        'name': 'Risiko Edema Makula Diabetik (DME)',
        'detected': isMod || isSev || isPdr,
        'level': isNo ? 'Sangat Rendah' : (isMild ? 'Rendah' : (isMod ? 'Sedang (<1 DD)' : 'Tinggi')),
        'desc': 'Penebalan makula foveal yang menjadi penyebab nomor satu penurunan tajam penglihatan sentral.',
        'isCritical': isSev || isPdr,
      },
    ];
  }

  static Map<String, dynamic> getImmediateSolution(String? classification) {
    switch (classification?.toUpperCase()) {
      case 'NO_DR':
        return {
          'triageLevel': 'OBSERVASI RUTIN FKTP',
          'urgency': 'Non-Cito',
          'timeframe': '12 Bulan',
          'actionTitle': 'Skrining Edukatif & Pemeliharaan Target Metabolik',
          'actionSteps': [
            'Pertahankan HbA1c < 7.0% melalui kontrol rutin di FKTP / Puskesmas.',
            'Lakukan pemeriksaan funduskopi digital tahunan untuk memantau integritas vaskular retina.',
            'Edukasi pasien mengenali gejala awal penurunan penglihatan diabetik.',
          ],
          'needReferral': false,
        };
      case 'MILD_DR':
      case 'MILD_NPDR':
        return {
          'triageLevel': 'PEMANTAUAN KETAT FKTP / RUJUKAN SELEKTIF',
          'urgency': 'Elektif',
          'timeframe': '6 Bulan',
          'actionTitle': 'Optimasi Terapi Medikamentosa & Evaluasi Ulang 6 Bulan',
          'actionSteps': [
            'Evaluasi kepatuhan terapi obat antidiabetes oral (OHO) dan kontrol glikemik ketat.',
            'Pengendalian tekanan darah agresif target < 130/80 mmHg untuk mencegah progresivitas mikroaneurisma.',
            'Jadwalkan foto fundus berkala ulang dalam 6 bulan untuk deteksi dini eksudat baru.',
          ],
          'needReferral': false,
        };
      case 'MODERATE_DR':
      case 'MODERATE_NPDR':
        return {
          'triageLevel': 'RUJUKAN TERENCANA FKRTL (RS TIPE C/B)',
          'urgency': 'Rujukan Terjadwal (3–4 Minggu)',
          'timeframe': 'Maksimal 30 Hari',
          'actionTitle': 'Rujukan Spesialis Mata (Sp.M) untuk Pemeriksaan OCT Makula',
          'actionSteps': [
            'Penerbitan Surat Pengantar Rujukan (SPK) BPJS ke Poli Spesialis Mata Rumah Sakit Rujukan.',
            'Pemeriksaan Optical Coherence Tomography (OCT) Makula guna menyingkirkan Edema Makula Subklinis.',
            'Evaluasi fundus stereoskopik dengan biomikroskopi slit-lamp dan lensa 90D/78D.',
            'Jika edema makula foveal terkonfirmasi, persiapkan injeksi anti-VEGF intraokular lini pertama.',
          ],
          'needReferral': true,
        };
      case 'SEVERE_DR':
      case 'SEVERE_NPDR':
        return {
          'triageLevel': 'RUJUKAN PRIORITAS TINGGI (RS TIPE B/A)',
          'urgency': 'Cepat (1–2 Minggu)',
          'timeframe': '14 Hari',
          'actionTitle': 'Rujukan Segera Spesialis Mata untuk Evaluasi Laser Panretinal (PRP)',
          'actionSteps': [
            'Rujuk cepat ke Rumah Sakit Rujukan Tersier dengan fasilitas Vitreoretina.',
            'Persiapan Panretinal Photocoagulation (PRP) profilaksis guna mencegah konversi ke PDR aktif.',
            'Pemeriksaan Angiografi Fluoresens Fundus (FFA) jika diperlukan untuk petakan zona iskemia kapiler.',
            'Instruksikan pasien hindari aktivitas mengejan berlebih atau olahraga beban berat.',
          ],
          'needReferral': true,
        };
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return {
          'triageLevel': 'RUJUKAN CITO / DARURAT RETINA',
          'urgency': 'Cito (< 7 Hari)',
          'timeframe': 'Segera',
          'actionTitle': 'Intervensi Segera Spesialis Vitreoretina: Laser PRP & Anti-VEGF',
          'actionSteps': [
            'Rujukan CITO ke Konsultan Vitreoretina Rumah Sakit Rujukan Mata Tersier.',
            'Tindakan Laser Panretinal Photocoagulation (PRP) segera untuk regresi neovaskularisasi retina rapuh.',
            'Pemberian Injeksi Anti-VEGF (Aflibercept/Ranibizumab) intraokular untuk menekan pendarahan aktif.',
            'Evaluasi risiko perdarahan vitreus masif atau ablasio retina traksional yang memerlukan vitrektomi.',
          ],
          'needReferral': true,
        };
      default:
        return {
          'triageLevel': 'EVALUASI KLINIS',
          'urgency': 'Sesuai Arahan Dokter',
          'timeframe': '-',
          'actionTitle': 'Konsultasikan Hasil ke Dokter Penanggung Jawab',
          'actionSteps': ['Lakukan verifikasi klinis dengan dokter fasilitas kesehatan terdekat.'],
          'needReferral': false,
        };
    }
  }

  static Map<String, dynamic> getLongTermPlan(String? classification) {
    return {
      'metabolicTargets': [
        {'label': 'Target HbA1c', 'target': '< 7.0%', 'desc': 'Menurunkan risiko komplikasi mikrovaskular mata hingga 76% (UKPDS)'},
        {'label': 'Gula Darah Puasa (GDP)', 'target': '80 - 130 mg/dL', 'desc': 'Menjaga stabilitas perfusi endotel kapiler retina'},
        {'label': 'Gula Darah 2 Jam PP', 'target': '< 180 mg/dL', 'desc': 'Mencegah lonjakan stres oksidatif postprandial'},
        {'label': 'Tekanan Darah', 'target': '< 130/80 mmHg', 'desc': 'Mencegah peningkatan tekanan kapiler & ruptur mikroaneurisma'},
        {'label': 'Kolesterol LDL', 'target': '< 100 mg/dL', 'desc': 'Menekan akumulasi endapan eksudat lipid keras di makula'},
      ],
      'lifestyleGuidelines': [
        {
          'title': 'Aktivitas Fisik Aman Retina',
          'desc': 'Lakukan jalan kaki santai atau senam diabetes 30 menit/hari. Hindari olahraga angkat beban berat atau mengejan (manuver Valsalva) yang menaikkan tekanan bola mata.',
        },
        {
          'title': 'Nutrisi Pelindung Retina',
          'desc': 'Konsumsi sayuran berdaun hijau gelap kaya Lutein & Zeaxanthin (bayam, daun katuk, brokoli) serta asam lemak Omega-3 untuk melindungi sel fotoreseptor retina.',
        },
        {
          'title': 'Kepatuhan Obat Teratur',
          'desc': 'Minum obat antidiabetes oral atau suntik insulin tepat waktu tanpa menghentikan dosis mandiri.',
        },
      ],
      'redFlagAlerts': [
        'Pandangan tiba-tiba gelap tertutup bayangan hitam seperti tirai menutup.',
        'Mendadak melihat hujan bintik hitam kemerahan melayang dalam jumlah banyak.',
        'Kilatan cahaya terang mendadak seperti petir (fotopsia) berulang kali di sudut mata.',
        'Nyeri mendadak pada bola mata disertai mata merah, mual, dan muntah.',
      ],
    };
  }

  /// Konversi objek DateTime ke Waktu Indonesia Barat (WIB, UTC+7) secara akurat
  static DateTime toWib(DateTime? dt) {
    if (dt == null) {
      return DateTime.now().toUtc().add(const Duration(hours: 7));
    }
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(const Duration(hours: 7));
  }

  /// Format tanggal dan jam dinamis secara real-time ke format Indonesia WIB
  static String formatIndonesianDateTime(DateTime? dateTime) {
    final d = toWib(dateTime);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = months[(d.month - 1).clamp(0, 11)];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} $monthName ${d.year}, $hour:$minute WIB';
  }

  /// Format jam saja dalam WIB (misal: 10:14 WIB)
  static String formatTimeOnly(DateTime? dateTime) {
    final d = toWib(dateTime);
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Format ringkas waktu untuk kartu telaah: 'Hari Ini,\n10:00 WIB' atau '15 Okt,\n10:00 WIB'
  static String formatWibTimeOrToday(DateTime? dateTime) {
    final wib = toWib(dateTime);
    final nowWib = toWib(DateTime.now());
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    final isToday = wib.year == nowWib.year && wib.month == nowWib.month && wib.day == nowWib.day;
    if (isToday) {
      return 'Hari Ini,\n$hour:$minute WIB';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = months[(wib.month - 1).clamp(0, 11)];
    return '${wib.day} $monthName,\n$hour:$minute WIB';
  }

  /// Buat ID skrining dinamis sesuai tanggal hari ini (#RTV-YYYYMMDD-XX)
  static String generateScreeningDisplayId(String? rawId) {
    final now = toWib(DateTime.now());
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final digits = (rawId ?? '').replaceAll(RegExp(r'[^0-9]'), '').padRight(2, '1').substring(0, 2);
    return '#RTV-$y$m$d-$digits';
  }
}
