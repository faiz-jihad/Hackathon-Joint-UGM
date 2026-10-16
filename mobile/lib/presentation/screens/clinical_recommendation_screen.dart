import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'referral_letter_screen.dart';
import 'care_companion_hub_screen.dart';
import '../widgets/notification_bell_widget.dart';

class ClinicalRecommendationScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;

  const ClinicalRecommendationScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
  });

  @override
  State<ClinicalRecommendationScreen> createState() =>
      _ClinicalRecommendationScreenState();
}

class _ClinicalRecommendationScreenState
    extends State<ClinicalRecommendationScreen> {
  List<Map<String, dynamic>> _facilities = [];
  String _selectedFacilityId = '';
  late int _selectedLevelIndex;

  @override
  void initState() {
    super.initState();
    _selectedLevelIndex = _getSeverityIndex(widget.result.aiResult.predictedClass);
    _loadFacilities();
  }

  int get _patientLevelIndex => _getSeverityIndex(widget.result.aiResult.predictedClass);

  int _getSeverityIndex(String raw) {
    switch (raw.toUpperCase()) {
      case 'NO_DR': return 0;
      case 'MILD_DR': case 'MILD': case 'MILD_NPDR': return 1;
      case 'MODERATE_DR': case 'MODERATE': case 'MODERATE_NPDR': return 2;
      case 'SEVERE_DR': case 'SEVERE': case 'SEVERE_NPDR': return 3;
      case 'PROLIFERATIVE_DR': case 'PDR': return 4;
      default: return 2;
    }
  }

  String _getClassFromIndex(int index) {
    switch (index) {
      case 0: return 'NO_DR';
      case 1: return 'MILD_DR';
      case 2: return 'MODERATE_DR';
      case 3: return 'SEVERE_DR';
      case 4: return 'PROLIFERATIVE_DR';
      default: return 'MODERATE_DR';
    }
  }

  Future<void> _loadFacilities() async {
    final list = await ApiClient().getNearestFacilities();
    if (mounted) {
      setState(() {
        _facilities = list;
        if (list.isNotEmpty) {
          _selectedFacilityId = list.first['id']?.toString() ?? '';
        }
      });
    }
  }

  Map<String, dynamic>? get _selectedFacility {
    if (_facilities.isEmpty) return null;
    return _facilities.firstWhere(
      (f) => f['id'] == _selectedFacilityId,
      orElse: () => _facilities.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeClass = _getClassFromIndex(_selectedLevelIndex);
    final isPatientLevel = _selectedLevelIndex == _patientLevelIndex;
    final severityTitle = ClinicalHelpers.getSeverityTitle(activeClass);
    final confidencePct = isPatientLevel
        ? (widget.result.aiResult.confidence * 100).toStringAsFixed(1)
        : (_selectedLevelIndex == 0 ? '98.5' : _selectedLevelIndex == 1 ? '92.0' : _selectedLevelIndex == 2 ? '89.0' : _selectedLevelIndex == 3 ? '94.5' : '96.2');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Section / Intro
                    _buildIntroSection(),

                    const SizedBox(height: 14),

                    // 4-Pillar Clinical Flow Roadmap Banner
                    _buildFourPillarRoadmapStrip(),

                    const SizedBox(height: 14),

                    // 5-Level Severity Grading Selector (Dari Terendah ke Tertinggi)
                    _buildFiveLevelSelector(_patientLevelIndex),

                    const SizedBox(height: 16),

                    // Fundus AI Diagnostic Card
                    _buildFundusDiagnosticCard(severityTitle, confidencePct, isPatientLevel, _selectedLevelIndex),

                    const SizedBox(height: 16),

                    // Rekomendasi Tindakan Klinis Card
                    _buildClinicalActionCard(_selectedLevelIndex),

                    const SizedBox(height: 16),

                    // Protokol Penanganan Medis
                    _buildMedicalProtocolCard(_selectedLevelIndex),

                    const SizedBox(height: 16),

                    // Panduan Mandiri Pasien ('Hal yang Dapat Anda Lakukan')
                    _buildPatientGuidelineSection(_selectedLevelIndex),

                    const SizedBox(height: 16),

                    // Clinical Disclaimer Note
                    _buildDisclaimerNote(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Aside - Aksi Klinis (Fixed Bottom)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Color(0xFF246BFD),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tindakan Lanjutan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const NotificationBellWidget(),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Rekomendasi Tindak Lanjut',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1E25),
            letterSpacing: -0.22,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Langkah penanganan klinis berbasis grading keparahan retinopati diabetik dan validasi telemedicine faskes.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF434652),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFourPillarRoadmapStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 6),
              Text(
                'Alur Terpadu 4 Tahap Klinis',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRoadmapPill('1. Masalah', 'Anamnesis', const Color(0xFF246BFD)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
              _buildRoadmapPill('2. Diagnosis', 'ICDR & Sp.M', const Color(0xFF246BFD)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
              _buildRoadmapPill('3. Solusi', 'Tindakan/SPK', const Color(0xFF246BFD)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFCBD5E1)),
              _buildRoadmapPill('4. Rawat', 'Monitoring', const Color(0xFF246BFD)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapPill(String step, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              step,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiveLevelSelector(int patientLevel) {
    const levels = [
      {'index': 0, 'degree': 'Level 0', 'name': 'Tidak Ada\nDR', 'color': Color(0xFF16A34A), 'sub': 'Normal'},
      {'index': 1, 'degree': 'Level 1', 'name': 'NPDR\nRingan', 'color': Color(0xFFD97706), 'sub': 'Mild'},
      {'index': 2, 'degree': 'Level 2', 'name': 'NPDR\nSedang', 'color': Color(0xFFEA580C), 'sub': 'Moderate'},
      {'index': 3, 'degree': 'Level 3', 'name': 'NPDR\nBerat', 'color': Color(0xFFDC2626), 'sub': 'Severe'},
      {'index': 4, 'degree': 'Level 4', 'name': 'PDR\nProliferatif', 'color': Color(0xFF991B1B), 'sub': 'PDR'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF246BFD)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Grading 5 Level ICDR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: levels.map((lvl) {
              final idx = lvl['index'] as int;
              final isSelected = _selectedLevelIndex == idx;
              final isPatient = patientLevel == idx;
              final color = lvl['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLevelIndex = idx;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : (isPatient ? color.withOpacity(0.6) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : (isPatient ? 1.5 : 1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lvl['degree'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? color : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lvl['name'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? color : const Color(0xFF64748B),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFundusDiagnosticCard(String severityTitle, String confidencePct, bool isPatientLevel, int levelIndex) {
    final eyeTag = widget.eyePosition == 'OD' ? 'OD' : 'OS';
    final qualityScore = (widget.eyePosition == 'OS' && widget.result.qualityOS != null)
        ? widget.result.qualityOS!.overallScore
        : widget.result.qualityOD.overallScore;

    final Color barColor = levelIndex == 0
        ? const Color(0xFF16A34A)
        : levelIndex == 1
            ? const Color(0xFFD97706)
            : levelIndex == 2
                ? const Color(0xFF246BFD)
                : levelIndex == 3
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF991B1B);

    final double barValue = isPatientLevel
        ? widget.result.aiResult.confidence
        : (levelIndex == 0 ? 0.985 : levelIndex == 1 ? 0.92 : levelIndex == 2 ? 0.89 : levelIndex == 3 ? 0.945 : 0.962);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: barColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPatientLevel
                      ? 'Hasil Analisis Biomarker (${widget.eyePosition})'
                      : 'Biomarker Retina: Level $levelIndex',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1E25),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Circular fundus preview with OD badge
              Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCBDDE7),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/retina_hero.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D1E25)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0D1E25),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        eyeTag,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: barColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isPatientLevel
                                ? (qualityScore >= 0.85
                                    ? 'Kualitas: Optimal (${(qualityScore * 100).toInt()}%)'
                                    : 'Kualitas: Memadai (${(qualityScore * 100).toInt()}%)')
                                : 'Standar Kualitas: ICDR Gold Standard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: barColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      severityTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1E25),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: LinearProgressIndicator(
                              value: barValue,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confidencePct%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalActionCard(int levelIndex) {
    String urgencyTitle;
    String targetTime;
    String urgencyBadge;
    String description;
    Color accentColor;
    Color bgTint;
    Color borderTint;
    String actionHeaderTag;

    switch (levelIndex) {
      case 0:
        actionHeaderTag = 'REKOMENDASI UTAMA: OBSERVASI FKTP';
        urgencyTitle = 'Skrining Rutin Tahunan di Faskes Pertama (FKTP)';
        targetTime = '12 Bulan';
        urgencyBadge = 'Prioritas Rutin (Non-Cito)';
        accentColor = const Color(0xFF16A34A);
        bgTint = const Color(0xFFF0FDF4);
        borderTint = const Color(0xFFBBF7D0);
        description =
            'Fundus dalam batas normal tanpa tanda mikroaneurisma atau kebocoran mikrovaskular. Pasien disarankan melanjutkan kontrol metabolik rutin di FKTP / Puskesmas, mempertahankan target HbA1c < 7.0%, dan menjadwalkan foto fundus kontrol tahunan berikutnya.';
        break;
      case 1:
        actionHeaderTag = 'REKOMENDASI UTAMA: PEMANTAUAN KETAT FKTP';
        urgencyTitle = 'Evaluasi Berkala 6 Bulan & Modifikasi Gaya Hidup';
        targetTime = '6 - 9 Bulan';
        urgencyBadge = 'Prioritas Rendah - Sedang (Elektif)';
        accentColor = const Color(0xFFD97706);
        bgTint = const Color(0xFFFFFBEB);
        borderTint = const Color(0xFFFDE68A);
        description =
            'Ditemukan mikroaneurisma fokal minimal (1–3 lesi terisolasi) tanpa edema makula. Belum memerlukan intervensi bedah/laser. Disarankan evaluasi foto fundus berkala 6 bulan di FKTP serta kontrol agresif tekanan darah (<130/80 mmHg) dan glukosa darah.';
        break;
      case 2:
        actionHeaderTag = 'REKOMENDASI UTAMA: KONSULTASI SPESIALIS MATA';
        urgencyTitle = 'Konsultasi Dokter Spesialis Mata (Sp.M) & Evaluasi OCT';
        targetTime = '1 - 3 Bulan';
        urgencyBadge = 'Prioritas Sedang (Rujukan Terjadwal)';
        accentColor = const Color(0xFF246BFD);
        bgTint = const Color(0xFFE7F6FF);
        borderTint = const Color(0xFFD0E7F5);
        description =
            'Ditemukan mikroaneurisma nyata, bercak perdarahan superfisial (dot-blot hemorrhages), atau eksudat keras di sekitar makula. Disarankan berkonsultasi dengan dokter spesialis mata (Sp.M) untuk evaluasi funduskopi mendalam dan pemetaan ketebalan makula dengan OCT.';
        break;
      case 3:
        actionHeaderTag = 'REKOMENDASI UTAMA: RUJUKAN CEPAT VITREORETINA';
        urgencyTitle = 'Rujukan Cepat Spesialis Mata (Persiapan Laser Panretinal)';
        targetTime = '2 - 4 Minggu';
        urgencyBadge = 'Prioritas Tinggi (Mendesak)';
        accentColor = const Color(0xFFDC2626);
        bgTint = const Color(0xFFFEF2F2);
        borderTint = const Color(0xFFFECACA);
        description =
            'Memenuhi aturan 4-2-1 (>20 perdarahan intraretina di 4 kuadran / venous beading di 2 kuadran / IRMA). Risiko konversi ke proliferatif aktif sangat tinggi dalam 1 tahun. Diperlukan rujukan terencana ke faskes sekunder/tersier dengan fasilitas Vitreoretina untuk evaluasi profilaksis laser fotokoagulasi (PRP).';
        break;
      case 4:
      default:
        actionHeaderTag = 'REKOMENDASI UTAMA: RUJUKAN CITO / DARURAT RETINA';
        urgencyTitle = 'Intervensi Segera: Laser Panretina (PRP) & Terapi Anti-VEGF';
        targetTime = 'Segera (< 7 - 14 Hari)';
        urgencyBadge = 'Prioritas Sangat Tinggi (Cito Medis)';
        accentColor = const Color(0xFF991B1B);
        bgTint = const Color(0xFFFFF1F2);
        borderTint = const Color(0xFFFFCCD3);
        description =
            'Tampak neovaskularisasi diskus/retina (NVD/NVE) rapuh dan/atau perdarahan vitreus aktif. Ancaman kehilangan penglihatan permanen mendesak tindakan laser panretinal photocoagulation (PRP) segera dan injeksi anti-VEGF intraokular untuk menekan perdarahan.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderTint),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionHeaderTag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      urgencyTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1E25),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF434652),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderTint),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Waktu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF737783),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        targetTime,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderTint),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tingkat Urgensi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF737783),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        urgencyBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalProtocolCard(int levelIndex) {
    String step1Title = 'Pemeriksa Berwenang';
    String step1Body;
    String step2Title = 'Rencana Intervensi Lanjutan';
    String step2Body;
    String step3Title = 'Toleransi Jadwal Rujukan';
    String step3Body;

    switch (levelIndex) {
      case 0:
        step1Body = 'Dokter Umum di FKTP / Puskesmas Pembina Wilayah';
        step2Body = 'Edukasi mandiri, pemantauan HbA1c & evaluasi foto fundus tahunan';
        step3Body = '12 Bulan (1 tahun kalender terencana)';
        break;
      case 1:
        step1Body = 'Dokter Umum / Penanggung Jawab Program Prolanis FKTP';
        step2Body = 'Optimasi terapi OHO/insulin dan evaluasi foto fundus berkala 6 bulan';
        step3Body = '6 Bulan kalender';
        break;
      case 2:
        step1Body = 'Dokter Spesialis Mata (Sp.M) / Vitreoretina Konsultan';
        step2Body = 'Optical Coherence Tomography (OCT) Makula & evaluasi kebocoran fokal';
        step3Body = 'Tidak boleh melebihi rentang 90 hari kalender';
        break;
      case 3:
        step1Body = 'Subspesialis Vitreoretina di RS Rujukan (Tipe B/A)';
        step2Body = 'Angiografi Fluoresens (FFA) & Persiapan Panretinal Photocoagulation (PRP)';
        step3Body = 'Dalam rentang 14 - 30 hari kalender';
        break;
      case 4:
      default:
        step1Body = 'Konsultan Bedah Vitreoretina RS Tersier (Tipe A)';
        step2Body = 'Injeksi Anti-VEGF intraokular segera, Laser PRP Cito, atau evaluasi Vitrektomi';
        step3Body = 'Cito medis (< 7 - 14 hari kalender)';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Protokol Penanganan Medis',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1E25),
                ),
              ),
              Icon(
                Icons.assignment_outlined,
                size: 18,
                color: Color(0xFF0061A4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildProtocolStep(
            number: '1',
            title: step1Title,
            body: step1Body,
          ),
          const SizedBox(height: 12),
          _buildProtocolStep(
            number: '2',
            title: step2Title,
            body: step2Body,
          ),
          const SizedBox(height: 12),
          _buildProtocolStep(
            number: '3',
            title: step3Title,
            body: step3Body,
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolStep({
    required String number,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFFDFF1FB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003178),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1E25),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF434652),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FITUR 2: EDUKASI SESUAI KONDISI
  // Menampilkan panduan 4 pilar (Pola Makan, Aktivitas, Pengobatan, dan Kontrol)
  // yang relevan dan dinamis terhadap stadium DR yang dipilih/ditemukan.
  // ===========================================================================
  Widget _buildPatientGuidelineSection(int levelIndex) {
    final severityName = ClinicalHelpers.getSeverityTitle(_getClassFromIndex(levelIndex));
    final isAdvanced = levelIndex >= 2; // Moderate, Severe, PDR

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF246BFD),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Edukasi Sesuai Kondisi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showFullEducationSheet(context, levelIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Panduan',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF246BFD),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF246BFD)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Panduan terarah disesuaikan khusus untuk kondisi: $severityName',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // 4 Pilar Edukasi Utama
          Row(
            children: [
              // Pilar 1: Pola Makan
              Expanded(
                child: _buildGuidelineCard(
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF246BFD),
                  iconBg: const Color(0xFFEFF6FF),
                  title: '1. Pola Makan (Diet 3J)',
                  desc: 'Piring model T, indeks glikemik rendah, batasi gula < 25g/hari & garam.',
                  badge: 'Nutrisi Retina',
                  onTap: () => _showFullEducationSheet(context, levelIndex),
                ),
              ),
              const SizedBox(width: 10),
              // Pilar 2: Aktivitas Fisik
              Expanded(
                child: _buildGuidelineCard(
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF246BFD),
                  iconBg: const Color(0xFFEFF6FF),
                  title: '2. Aktivitas Fisik',
                  desc: isAdvanced
                      ? 'Jalan santai ringan. HINDARI angkat beban berat / mengejan kuat.'
                      : 'Aerobik ringan-sedang 150 mnt/minggu (30 mnt/hari).',
                  badge: isAdvanced ? 'Waspada Tekanan' : 'Rekomendasi Aman',
                  onTap: () => _showFullEducationSheet(context, levelIndex),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Pilar 3: Kepatuhan Pengobatan
              Expanded(
                child: _buildGuidelineCard(
                  icon: Icons.medication_liquid_rounded,
                  iconColor: const Color(0xFF246BFD),
                  iconBg: const Color(0xFFEFF6FF),
                  title: '3. Kepatuhan Obat',
                  desc: 'Konsumsi OAD / insulin tepat waktu. Jangan hentikan obat tanpa izin dokter.',
                  badge: 'Kontrol Glikemik',
                  onTap: () => _showFullEducationSheet(context, levelIndex),
                ),
              ),
              const SizedBox(width: 10),
              // Pilar 4: Jadwal & Target Kontrol
              Expanded(
                child: _buildGuidelineCard(
                  icon: Icons.event_repeat_rounded,
                  iconColor: const Color(0xFF246BFD),
                  iconBg: const Color(0xFFEFF6FF),
                  title: '4. Target & Kontrol',
                  desc: levelIndex == 0
                      ? 'Target HbA1c < 7.0%, tensi < 130/80. Kontrol ulang 12 bulan.'
                      : isAdvanced
                          ? 'Target ketat HbA1c < 7.0%. Kontrol ulang segera 1-3 bulan.'
                          : 'Target HbA1c < 7.0%. Kontrol ulang 6-12 bulan.',
                  badge: 'Target Standar',
                  onTap: () => _showFullEducationSheet(context, levelIndex),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      badge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w700, color: iconColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullEducationSheet(BuildContext context, int levelIndex) {
    final severityName = ClinicalHelpers.getSeverityTitle(_getClassFromIndex(levelIndex));
    final isAdvanced = levelIndex >= 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF246BFD), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panduan Edukasi Pasien Terpadu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Kondisi: $severityName',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF246BFD)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilar 1
                    _buildEduSheetSection(
                      title: '1. Panduan Pola Makan (Diet 3J)',
                      icon: Icons.restaurant_rounded,
                      color: const Color(0xFF246BFD),
                      points: [
                        'Jadwal: Makan secara teratur 3 kali makan utama dan 2 kali selingan sehat (buah tidak terlalu manis atau kacang rebus).',
                        'Jumlah: Hitung porsi piring makan model T: 1/2 piring sayuran hijau/serat, 1/4 piring karbohidrat kompleks (beras merah/jagung), dan 1/4 piring lauk protein rendah lemak (ikan/ayam tanpa kulit).',
                        'Jenis: Prioritaskan makanan dengan Indeks Glikemik Rendah (Low-GI) serta kaya antioksidan retina (Lutein & Zeaxanthin) seperti bayam, kangkung, wortel, brokoli, dan ikan kaya omega-3.',
                        'Batasan Penting: Batasi gula murni < 4 sendok makan (50g) atau idealnya < 25g/hari, garam < 1 sendok teh (2000mg natrium/hari), dan lemak jenuh.',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pilar 2
                    _buildEduSheetSection(
                      title: '2. Panduan Aktivitas Fisik & Olahraga',
                      icon: Icons.directions_walk_rounded,
                      color: const Color(0xFF246BFD),
                      points: isAdvanced
                          ? [
                              'PERINGATAN KLINIS: Pada stadium retinopati diabetik sedang hingga lanjut, hindari aktivitas yang menaikkan tekanan bola mata secara mendadak.',
                              'DILARANG: Angkat beban berat (weightlifting), mengejan keras (manuver Valsalva), posisi kepala di bawah tubuh (inversion yoga), atau olahraga kontak keras.',
                              'DIANJURKAN: Jalan santai ringan selama 20-30 menit di permukaan datar, senam kaki diabetes, atau stretching ringan.',
                            ]
                          : [
                              'Frekuensi: Lakukan latihan fisik aerobik sedang 150 menit per minggu (30 menit sehari, minimal 5 hari per minggu).',
                              'Pilihan Terbaik: Jalan cepat, bersepeda statis, berenang santai, atau senam diabetes terpadu.',
                              'Cek Gula Darah: Pastikan gula darah di atas 100 mg/dL sebelum berolahraga untuk mencegah hipoglikemia.',
                            ],
                    ),
                    const SizedBox(height: 16),

                    // Pilar 3
                    _buildEduSheetSection(
                      title: '3. Kepatuhan Pengobatan & Terapi Medis',
                      icon: Icons.medication_liquid_rounded,
                      color: const Color(0xFF246BFD),
                      points: [
                        'Konsumsi Obat Teratur: Minum obat antidiabetes oral (seperti Metformin/Glimepiride) atau suntik insulin tepat sesuai jam dan dosis anjuran dokter.',
                        'Jangan Modifikasi Dosis: Hindari menambah, mengurangi, atau menghentikan obat sendiri meskipun merasa badan sudah sehat.',
                        'Obat Tetes Mata: Jika dokter spesialis mata meresepkan tetes mata pelumas atau anti-inflamasi, gunakan secara higienis dan sesuai petunjuk.',
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pilar 4
                    _buildEduSheetSection(
                      title: '4. Jadwal Kontrol & Target Klinis',
                      icon: Icons.event_repeat_rounded,
                      color: const Color(0xFF246BFD),
                      points: [
                        'Target HbA1c: Pertahankan kadar HbA1c di bawah 7.0% untuk menghentikan perburukan mikrovaskular retina.',
                        'Target Tekanan Darah: Jaga tensi optimal < 130/80 mmHg. Tekanan darah tinggi mempercepat perdarahan retina.',
                        'Target Profil Lipid: Kolesterol LDL < 100 mg/dL (atau < 70 mg/dL bila ada risiko kardiovaskular).',
                        'Jadwal Periksa Mata Rutin: Pemeriksaan foto fundus ulang wajib dilakukan secara berkala tanpa menunggu timbulnya keluhan buram.',
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF246BFD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Saya Mengerti Panduan Ini', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEduSheetSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF0061A4),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pemberitahuan Regulasi: Hasil berbasis kecerdasan artifisial merupakan instrumen skrining awal dan bukan pengganti diagnosis definitif oftalmologis. Keputusan terapi akhir diputuskan oleh dokter penanggung jawab.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF434652),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final facility = _selectedFacility ??
        (_facilities.isNotEmpty
            ? _facilities.first
            : {
                'id': '',
                'name': 'Fasilitas Rujukan RME',
                'doctor_name': 'Dokter Spesialis Mata',
                'specialty': 'Vitreoretina',
                'city': '-',
              });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Tombol Beranda
            InkWell(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 22,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Surat SPK Rujukan
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferralLetterScreen(
                          facility: facility,
                          result: widget.result,
                          patient: widget.patient,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(
                    'Surat SPK',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF246BFD),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Utama: AI Care Companion
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CareCompanionHubScreen(
                          patient: widget.patient,
                          screeningResult: widget.result,
                          initialStep: 1,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  label: const Text(
                    'Care Companion',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
