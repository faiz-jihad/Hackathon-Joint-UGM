import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import 'upload_fundus_screen.dart';
import 'patient_history_screen.dart';
import 'care_companion_hub_screen.dart';

/// Screen 01: 01. Homepage (Figma Frame 25:3)
/// Authoritative 1:1 Implementation matching Figma source of truth.
class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveDashboardData();
  }

  Future<void> _loadLiveDashboardData() async {
    try {
      final patients = await ApiClient().getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadFundusScreen(
          initialPatient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientHistoryScreen(),
      ),
    );
  }

  void _navigateToCareCompanion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareCompanionHubScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
          initialStep: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Brand Header (Figma Node 25:5)
            const BrandHeader(),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.figmaBlue),
              ),

            // Main Scrollable Inner Page Content (Figma Node 25:4 & 25:16)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLiveDashboardData,
                color: AppColors.figmaBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // 1. Circular Retina Clinical Framing (Figma Node 25:39)
                      _buildCircularRetinaHero(),

                      const SizedBox(height: 24),

                      // 2. Headline & Description (Figma Node 25:18)
                      _buildHeadlineAndDescription(),

                      const SizedBox(height: 20),

                      // 3. Feature Highlight Pills (Figma Node 25:23)
                      _buildFeatureHighlightPills(),

                      const SizedBox(height: 28),

                      // 4. Section 1: Skrining Terakhir (Figma Node 76:240)
                      _buildSectionSkriningTerakhir(),

                      const SizedBox(height: 24),

                      // 4.5. Section: AI Care Companion Hub
                      _buildSectionCareCompanion(),

                      const SizedBox(height: 28),

                      // 5. Section 2: Status Pemeriksaan & Tiga Jalur Sistem (Figma Node 76:296)
                      _buildSectionTigaJalurSistem(),

                      const SizedBox(height: 28),

                      // 6. Section 3: Informasi Singkat Skrining Retina (Figma Node 76:348)
                      _buildSectionEdukasiRetina(),

                      const SizedBox(height: 24),

                      // 7. Bottom Action CTA Area (Figma Node 25:54)
                      _buildBottomCtaArea(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Circular Retina Clinical Framing (Figma Node 25:39)
  Widget _buildCircularRetinaHero() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer Circular Frame with Gradient and Shadow (Figma Node 25:39 & 25:40)
          Container(
            width: 224,
            height: 224,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE3F2FD),
                  Colors.white,
                ],
              ),
              border: Border.all(
                color: const Color(0x332196F3), // rgba(33,150,243,0.2)
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F0D47A1), // rgba(13,71,161,0.12)
                  offset: Offset(0, 12),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(9),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F172A),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/retina_hero.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0F172A),
                  child: const Center(
                    child: Icon(Icons.remove_red_eye, color: AppColors.figmaBlueSurface, size: 56),
                  ),
                ),
              ),
            ),
          ),

          // Trust Badge Tag (Figma Node 25:48)
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000), // rgba(0,0,0,0.1)
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: AppColors.figmaBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Standar Klinis Fundus',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.figmaBlue,
                      height: 1.5,
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

  /// Headline & Description (Figma Node 25:18)
  Widget _buildHeadlineAndDescription() {
    return Column(
      children: [
        const Text(
          'Skrining Retinopati Diabetik',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaBlue,
            letterSpacing: -0.6,
            height: 1.33,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Deteksi dini tanda-tanda kerusakan pembuluh\ndarah retina akibat diabetes melalui foto fundus\ndigital secara akurat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
            height: 1.625,
          ),
        ),
      ],
    );
  }

  /// Feature highlight pills: Cepat, Akurat, Insight (Figma Node 25:23)
  Widget _buildFeatureHighlightPills() {
    return Row(
      children: [
        Expanded(
          child: _buildHighlightCard(
            title: 'Cepat',
            subtitle: '< 5 Detik',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHighlightCard(
            title: 'Akurat',
            subtitle: 'Deep Learning',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildHighlightCard(
            title: 'Insight',
            subtitle: 'Peta Visual',
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0,0,0,0.05)
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.figmaBlue,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.figmaTextMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 1: Skrining Terakhir (Figma Node 76:240)
  Widget _buildSectionSkriningTerakhir() {
    final latestPatient = _patients.isNotEmpty ? _patients.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row (Figma Node 76:242)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Skrining Terakhir',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.figmaTextHeading,
                letterSpacing: -0.09,
              ),
            ),
            InkWell(
              onTap: _navigateToHistory,
              borderRadius: BorderRadius.circular(4),
              child: const Row(
                children: [
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.figmaBlueLink,
                      letterSpacing: 0.26,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.figmaBlueLink,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (latestPatient == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDFF1FB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    color: AppColors.figmaBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Riwayat Skrining',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.figmaTextHeading,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lakukan skrining foto fundus untuk mendeteksi retinopati diabetik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.figmaTextBody,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _navigateToUpload,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 14),
                  label: const Text('Mulai Skrining Pertama'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.figmaBlue,
                    side: const BorderSide(color: AppColors.figmaBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  offset: Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF1FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/fundus_thumbnail.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.figmaBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestPatient.fullName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.figmaTextHeading,
                              letterSpacing: 0.15,
                              height: 1.33,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 11,
                                color: AppColors.figmaTextBody,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NIK: ${latestPatient.nik}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.figmaTextBody,
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.figmaBlueChip,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        latestPatient.diabetesProfile?.diabetesType ?? 'T2DM',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusGreenDark,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.figmaBlueChip,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Terapi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.figmaTextBody,
                                letterSpacing: 0.44,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestPatient.diabetesProfile?.currentTreatment ?? 'Terjadwal',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusGreenSuccess,
                                letterSpacing: 0.26,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.figmaBlueChip,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HbA1c Terkini',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.figmaTextBody,
                                letterSpacing: 0.44,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestPatient.diabetesProfile?.lastHbA1c != null
                                  ? '${latestPatient.diabetesProfile!.lastHbA1c}%'
                                  : '-',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.figmaBlueDark,
                                letterSpacing: 0.26,
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
          ),
      ],
    );
  }

  /// Section: AI Care Companion Hub
  Widget _buildSectionCareCompanion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEBF3FF), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0D47A1),
            blurRadius: 10,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.figmaBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI CARE COMPANION',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.figmaBlue),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pendamping Perawatan & Gizi Terjangkau',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.figmaTextHeading,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cari RS rujukan BPJS, siapkan pertanyaan dokter, dan susun menu harian ramah kantong untuk kontrol gula darah.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.figmaTextBody,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _navigateToCareCompanion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.figmaBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Buka Pendamping Pasien',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section 2: Status Pemeriksaan & Tiga Jalur Sistem (Figma Node 76:296)
  Widget _buildSectionTigaJalurSistem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Pemeriksaan & Tiga Jalur Sistem',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.figmaTextHeading,
            letterSpacing: -0.09,
          ),
        ),

        const SizedBox(height: 8),

        // 1. RETAKE Card (Figma Node 76:306)
        _buildTriageCard(
          icon: Icons.cameraswitch_outlined,
          iconBg: AppColors.figmaRetakeSurface,
          iconColor: AppColors.figmaRetakeRed,
          title: '1. RETAKE (Ambil Ulang)',
          titleColor: AppColors.figmaRetakeRed,
          badgeText: 'Kualitas Rendah',
          badgeBg: AppColors.figmaRetakeSurface,
          badgeTextColor: AppColors.figmaRetakeDark,
          description:
              'Jika citra terdeteksi buram, artefak silau, atau kurang pencahayaan, sistem menolak proses sebelum diagnosa salah.',
        ),

        const SizedBox(height: 8),

        // 2. ANALYZE Card (Figma Node 76:320)
        _buildTriageCard(
          icon: Icons.auto_awesome,
          iconBg: AppColors.figmaAnalyzeBg,
          iconColor: AppColors.figmaBlueDark,
          title: '2. ANALYZE (Analisis Mandiri)',
          titleColor: AppColors.figmaBlueDark,
          badgeText: 'Akurasi Tinggi',
          badgeBg: AppColors.figmaAnalyzeBg,
          badgeTextColor: AppColors.figmaBlueDark,
          description:
              'Jika citra layak dan skor reliability memadai, model memetakan eksudat, mikroaneurisma, dan perdarahan secara instan.',
        ),

        const SizedBox(height: 8),

        // 3. HUMAN REVIEW Card (Figma Node 76:334)
        _buildTriageCard(
          icon: Icons.medical_services_outlined,
          iconBg: AppColors.figmaHumanReviewBg,
          iconColor: AppColors.figmaBlueLink,
          title: '3. HUMAN REVIEW (Spesialis)',
          titleColor: AppColors.figmaBlueLink,
          badgeText: 'Konsultasi',
          badgeBg: AppColors.figmaHumanReviewBg,
          badgeTextColor: const Color(0xFF00497D),
          description:
              'Jika hasil ambigu atau pada ambang stadium lanjut, citra langsung dialihkan ke dokter spesialis mata (Sp.M) untuk validasi resmi.',
        ),
      ],
    );
  }

  Widget _buildTriageCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0,0,0,0.05)
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon Box (40x40 rounded 12)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(width: 16),

          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          letterSpacing: 0.26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.figmaTextBody,
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section 3: Informasi Singkat Skrining Retina (Figma Node 76:348)
  Widget _buildSectionEdukasiRetina() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading & Tag Row (Figma Node 76:350)
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informasi Singkat Skrining Retina',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.figmaTextHeading,
                letterSpacing: -0.09,
              ),
            ),
            Text(
              'Edukasi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.figmaBlueLink,
                letterSpacing: 0.44,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Educational Bento Layout (Figma Node 76:356)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000), // rgba(0,0,0,0.05)
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Image with Gradient and Glass Overlay (Figma Node 76:357)
              SizedBox(
                height: 144,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/education_banner.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFDFF1FB),
                        child: const Center(
                          child: Icon(Icons.school_outlined, color: AppColors.figmaBlue, size: 40),
                        ),
                      ),
                    ),
                    // Gradient Fade to white at bottom (Figma Node 76:359)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    // Glass Pill: Deteksi Dini Menyelamatkan Penglihatan (Figma Node 76:360)
                    Positioned(
                      left: 16,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: AppColors.figmaBlueDark,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Deteksi Dini Menyelamatkan Penglihatan',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.figmaBlueDark,
                                letterSpacing: 0.44,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Educational Copy & Quick Facts (Figma Node 76:365)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retinopati Diabetik (DR) sering kali tidak bergejala pada tahap awal. Skrining retina digital berkala memungkinkan penanganan sebelum terjadi penurunan fungsi penglihatan permanen.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.figmaTextBody,
                        height: 1.62,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick Facts Checklist (Figma Node 76:369)
                    _buildChecklistItem(
                      icon: Icons.event_available_outlined,
                      text: 'Pemeriksaan dianjurkan minimal 1 kali per tahun bagi penderita diabetes.',
                    ),

                    const SizedBox(height: 8),

                    _buildChecklistItem(
                      icon: Icons.check_circle_outline,
                      text: 'Skrining non-invasif cepat, aman, dan tanpa rasa sakit.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.figmaBlueChip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.figmaTextHeading,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.figmaTextHeading,
                height: 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Action CTA Area (Figma Node 25:54)
  Widget _buildBottomCtaArea() {
    return Column(
      children: [
        // Primary CTA Button (Figma Node 25:55)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _navigateToUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.figmaBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x400D47A1), // rgba(13,71,161,0.25)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mulai Pemeriksaan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.43,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle (Figma Node 25:61)
        const Text(
          'Analisis citra retina secara cepat dan mudah',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.figmaTextMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
