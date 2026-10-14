import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'referral_letter_screen.dart';
import 'care_companion_hub_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFacilities();
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
    final severityTitle =
        ClinicalHelpers.getSeverityTitle(widget.result.aiResult.predictedClass);
    final confidencePct =
        (widget.result.aiResult.confidence * 100).toStringAsFixed(1);
    final isNoDr = widget.result.aiResult.predictedClass == 'NO_DR';
    final isSevereOrPdr =
        widget.result.aiResult.predictedClass == 'SEVERE_DR' ||
            widget.result.aiResult.predictedClass == 'PROLIFERATIVE_DR';

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

                    const SizedBox(height: 16),

                    // Fundus AI Diagnostic Card
                    _buildFundusDiagnosticCard(severityTitle, confidencePct),

                    const SizedBox(height: 16),

                    // Rekomendasi Tindakan Klinis Card
                    _buildClinicalActionCard(isNoDr, isSevereOrPdr),

                    const SizedBox(height: 16),

                    // Protokol Penanganan Medis
                    _buildMedicalProtocolCard(),

                    const SizedBox(height: 16),

                    // Panduan Mandiri Pasien ('Hal yang Dapat Anda Lakukan')
                    _buildPatientGuidelineSection(),

                    const SizedBox(height: 16),

                    // Rekomendasi Dokter Spesialis Terhubung
                    _buildDoctorReferralCard(),

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
          const Text(
            'Tindakan Lanjutan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF246BFD),
            ),
          ),
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

  Widget _buildFundusDiagnosticCard(String severityTitle, String confidencePct) {
    final eyeTag = widget.eyePosition == 'OD' ? 'OD' : 'OS';
    final qualityScore = (widget.eyePosition == 'OS' && widget.result.qualityOS != null)
        ? widget.result.qualityOS!.overallScore
        : widget.result.qualityOD.overallScore;

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
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0061A4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Hasil Analisis Biomarker Retina',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D1E25),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 96x96 circular fundus preview with OD badge
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
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Color(0xFF0061A4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          qualityScore >= 0.85
                              ? 'Kualitas Citra: Optimal (${(qualityScore * 100).toInt()}%)'
                              : 'Kualitas Citra: Memadai (${(qualityScore * 100).toInt()}%)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0061A4),
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
                              value: widget.result.aiResult.confidence,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFDFF1FB),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF246BFD)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confidencePct%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF246BFD),
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

  Widget _buildClinicalActionCard(bool isNoDr, bool isSevereOrPdr) {
    String urgencyTitle;
    String targetTime;
    String urgencyBadge;
    String description;

    if (isNoDr) {
      urgencyTitle = 'Skrining Rutin Tahunan';
      targetTime = '12 Bulan';
      urgencyBadge = 'Prioritas Rutin';
      description =
          'Disarankan menjadwalkan evaluasi fundus kontrol tahunan berikutnya untuk pemantauan retinopati dan tetap menjaga kontrol glikemik serta tekanan darah stabil.';
    } else if (isSevereOrPdr) {
      urgencyTitle = 'Rujukan Spesialis Mata Segera';
      targetTime = '< 2 Minggu';
      urgencyBadge = 'Prioritas Tinggi';
      description =
          'Diperlukan rujukan segera ke dokter spesialis mata (Sp.M / Subspesialis Vitreoretina) untuk evaluasi funduskopi mendalam, laser fotokoagulasi atau terapi anti-VEGF.';
    } else {
      urgencyTitle = 'Konsultasi Dokter Spesialis Mata';
      targetTime = '1 - 3 Bulan';
      urgencyBadge = 'Prioritas Sedang';
      description =
          'Disarankan berkonsultasi dengan dokter spesialis mata (Sp.M / Subspesialis Vitreoretina) untuk evaluasi funduskopi mendalam dan pemetaan ketebalan makula dengan OCT.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E7F5)),
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
                  color: const Color(0xFF246BFD),
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
                    const Text(
                      'REKOMENDASI UTAMA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0061A4),
                        letterSpacing: 0.55,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      urgencyTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
              fontSize: 14,
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
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF003178),
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
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0061A4),
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

  Widget _buildMedicalProtocolCard() {
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
            title: 'Pemeriksa Berwenang',
            body: 'Dokter Spesialis Mata (Sp.M) / Vitreoretina Konsultan',
          ),
          const SizedBox(height: 12),
          _buildProtocolStep(
            number: '2',
            title: 'Rencana Intervensi Lanjutan',
            body: 'Optical Coherence Tomography (OCT) Makula & evaluasi kebocoran fokal',
          ),
          const SizedBox(height: 12),
          _buildProtocolStep(
            number: '3',
            title: 'Toleransi Jadwal Rujukan',
            body: 'Tidak boleh melebihi rentang 90 hari kalender',
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

  Widget _buildPatientGuidelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Panduan Mandiri Pasien',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1E25),
              ),
            ),
            Text(
              'Edukasi Preventif',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0061A4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGuidelineCard(
                icon: Icons.bloodtype_outlined,
                title: 'Kontrol Gula Darah',
                desc: 'Target HbA1c < 7.0% secara stabil.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildGuidelineCard(
                icon: Icons.favorite_border_rounded,
                title: 'Tekanan Darah & Lipid',
                desc: 'Jaga tensi optimal < 130/80 mmHg.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGuidelineCard(
                icon: Icons.calendar_today_outlined,
                title: 'Disiplin Skrining',
                desc: 'Patuhi interval evaluasi tanpa jeda.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildGuidelineCard(
                icon: Icons.visibility_outlined,
                title: 'Waspada Tanda Akut',
                desc: 'Kilatan cahaya atau floaters mendadak.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0061A4)),
          ),
          const SizedBox(height: 8),
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
            desc,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF434652),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorReferralCard() {
    final facility = _selectedFacility;
    final doctorName = facility?['doctor_name'] ?? (facility != null ? 'Dokter Penanggung Jawab Faskes' : 'Belum Memilih Faskes Rujukan');
    final facilityName = facility?['name'] ?? 'Fasilitas Rujukan RME Terdaftar';

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
          const Text(
            'RUJUKAN DOKTER TERPILIH',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF737783),
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDFF1FB),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/doctor_avatar_sample.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: Color(0xFF0061A4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1E25),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Subspesialis Vitreoretina & Makula',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF434652),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      facilityName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0061A4),
                      ),
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

  Widget _buildDisclaimerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xF2F4FAFF), // rgba(244,250,255,0.95)
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0D47A1),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left action button: Download SPK referral letter
          InkWell(
            onTap: () {
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFD9EBF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 20,
                color: Color(0xFF246BFD),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Primary Care Companion Action Button (Medica Capsule Style)
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40246BFD),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF246BFD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.health_and_safety_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Care Companion',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Right button: Kembali ke Beranda
          IconButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined, color: Color(0xFF246BFD)),
            tooltip: 'Kembali ke Beranda',
          ),
        ],
      ),
    );
  }
}
