import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import 'upload_fundus_screen.dart';
import 'patient_history_screen.dart';
import 'care_companion_hub_screen.dart';
import 'referral_letter_screen.dart';

/// Screen 01: Homepage Faskes Retinopati Diabetik
/// Desain Bersih, Modern, dan Disesuaikan untuk Fasilitas Kesehatan (Puskesmas / FKTP).
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

  void _navigateToReferral() {
    final patient = _patients.isNotEmpty ? _patients.first : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferralLetterScreen(
          patient: patient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Faskes dengan Status Koneksi Interaktif
            const BrandHeader(),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.figmaBlue),
              ),

            // Konten Utama
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLiveDashboardData,
                color: AppColors.figmaBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Banner Faskes & Nakes Duty Card
                      _buildFaskesDutyBanner(),

                      const SizedBox(height: 18),

                      // 2. Primary Action Hero (Mulai Skrining Fundus Baru)
                      _buildHeroScannerCta(),

                      const SizedBox(height: 16),

                      // 3. Quick Action Hub (Antrean, Care Companion, Rujukan)
                      _buildQuickActionHub(),

                      const SizedBox(height: 24),

                      // 4. Circular Retina HUD Visual (Non-Generic Clinical Lens)
                      _buildRetinaHudViewer(),

                      const SizedBox(height: 24),

                      // 5. Kasus Pasien Terakhir Terskrining
                      _buildSectionSkriningTerakhir(),

                      const SizedBox(height: 24),

                      // 6. Tiga Alur Keputusan Klinis (Triase ICDR)
                      _buildSectionTigaJalurSistem(),

                      const SizedBox(height: 24),

                      // 7. Edukasi & Standar Klinis Kemenkes / PERDAMI
                      _buildSectionStandarKlinis(),

                      const SizedBox(height: 20),
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

  /// Banner Konteks Faskes Puskesmas
  Widget _buildFaskesDutyBanner() {
    final isOnline = ApiConstants.currentEnvironment == BackendEnvironment.onlineVps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: AppColors.figmaBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puskesmas Digital • FKTP Pratama',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaTextHeading,
                      ),
                    ),
                    Text(
                      'Poli Pengendalian DM & Skrining Komplikasi Mata',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.figmaTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: AppColors.figmaBlue),
                    SizedBox(width: 4),
                    Text(
                      'SATUSEHAT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 3 Metrik Triase Operasional Hari Ini
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Pasien Terdaftar',
                  value: '${_patients.length}',
                  sublabel: 'Database RM',
                  icon: Icons.people_outline,
                  color: AppColors.figmaBlue,
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricTile(
                  label: 'Model Inferensi',
                  value: '96.4%',
                  sublabel: 'AUC Efisiensi B3',
                  icon: Icons.auto_awesome_outlined,
                  color: const Color(0xFF059669),
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricTile(
                  label: 'Status Cloud',
                  value: isOnline ? 'Online' : 'Lokal',
                  sublabel: isOnline ? 'VPS Aktif' : 'Laptop Wi-Fi',
                  icon: isOnline ? Icons.cloud_done_outlined : Icons.wifi_off_outlined,
                  color: isOnline ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.figmaTextHeading,
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: AppColors.figmaTextMuted,
          ),
        ),
      ],
    );
  }

  /// Primary Action Scanner CTA (Tampilan Non-Generik untuk Nakes)
  Widget _buildHeroScannerCta() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF002171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330D47A1),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToUpload,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mulai Skrining Fundus',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.bolt, color: Color(0xFFFDE047), size: 16),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload foto mata OD/OS • Quality Gate AI • Diagnosis ICDR instan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFFE2E8F0),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hub Menu Cepat Khusus Alur Faskes (3 Kartu Aksi Tambahan)
  Widget _buildQuickActionHub() {
    return Row(
      children: [
        // 1. Data Pasien
        Expanded(
          child: _buildActionTile(
            title: 'Rekam Medis',
            subtitle: 'Antrean NIK',
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF0369A1),
            bgColor: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBAE6FD),
            onTap: _navigateToHistory,
          ),
        ),
        const SizedBox(width: 10),

        // 2. Care Companion
        Expanded(
          child: _buildActionTile(
            title: 'Care Companion',
            subtitle: 'Gizi & Edukasi',
            icon: Icons.psychology_outlined,
            iconColor: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFEEF2FF),
            borderColor: const Color(0xFFC7D2FE),
            onTap: _navigateToCareCompanion,
          ),
        ),
        const SizedBox(width: 10),

        // 3. Rujukan Sp.M
        Expanded(
          child: _buildActionTile(
            title: 'Rujukan Sp.M',
            subtitle: 'Format BPJS',
            icon: Icons.note_alt_outlined,
            iconColor: const Color(0xFFC2410C),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFED7AA),
            onTap: _navigateToReferral,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.figmaTextHeading,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.figmaTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Retina HUD Visual (Desain Lensa Klinis Modern)
  Widget _buildRetinaHudViewer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visualisasi Area Fundus',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.figmaTextHeading,
                    ),
                  ),
                  Text(
                    'Fokus Deteksi: Makula & Diskus Optikus',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.figmaTextMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Quality Gate >80%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Lensa Retina dengan HUD Ring
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer HUD Ring
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Target Lines (Optic Disc & Macula Guides)
                      Container(
                        width: 176,
                        height: 176,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: const Color(0xFF0A0F1D),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/retina_hero.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.remove_red_eye_rounded, color: Color(0xFF38BDF8), size: 54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Model Benchmark Spec
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HudDetailItem(label: 'Arsitektur', value: 'EfficientNet-B3'),
                _HudDetailItem(label: 'Standar Triase', value: 'ICDR 5-Grade'),
                _HudDetailItem(label: 'Heatmap', value: 'Grad-CAM XAI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kasus Pasien Terakhir Terskrining
  Widget _buildSectionSkriningTerakhir() {
    final latestPatient = _patients.isNotEmpty ? _patients.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Skrining Terakhir di Poli',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.figmaTextHeading,
              ),
            ),
            InkWell(
              onTap: _navigateToHistory,
              borderRadius: BorderRadius.circular(4),
              child: const Row(
                children: [
                  Text(
                    'Semua Pasien',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.figmaBlue,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.figmaBlue),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (latestPatient == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_late_outlined, color: AppColors.figmaTextMuted, size: 36),
                const SizedBox(height: 10),
                const Text(
                  'Belum Ada Riwayat Hari Ini',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.figmaTextHeading,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ambil foto fundus retina pasien diabetes untuk memulai skrining.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.figmaTextMuted),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _navigateToUpload,
                  icon: const Icon(Icons.add_a_photo, size: 14),
                  label: const Text('Mulai Pasien Pertama'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.figmaBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: AppColors.figmaBlue, size: 24),
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.figmaTextHeading,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIK: ${latestPatient.nik} • ${latestPatient.age} Thn (${latestPatient.gender == "MALE" ? "L" : "P"})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.figmaTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        latestPatient.diabetesProfile?.diabetesType ?? 'T2DM',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPatientBadge(
                      label: 'Terapi DM',
                      value: latestPatient.diabetesProfile?.currentTreatment ?? 'Oral Med',
                    ),
                    _buildPatientBadge(
                      label: 'HbA1c Terakhir',
                      value: latestPatient.diabetesProfile?.lastHbA1c != null
                          ? '${latestPatient.diabetesProfile!.lastHbA1c}%'
                          : '7.8%',
                    ),
                    _buildPatientBadge(
                      label: 'Target Mata',
                      value: 'OD & OS',
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPatientBadge({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.figmaTextMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaTextHeading,
          ),
        ),
      ],
    );
  }

  /// Tiga Alur Keputusan Klinis (Triase ICDR Standard)
  Widget _buildSectionTigaJalurSistem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standar Triase Klinis Retiva',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaTextHeading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '3 cabang alur otomatis untuk mencegah misdiagnosis di fasilitas kesehatan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.figmaTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        // 1. RETAKE Card
        _buildTriaseCard(
          icon: Icons.cameraswitch_outlined,
          iconBg: const Color(0xFFFEE2E2),
          iconColor: const Color(0xFFDC2626),
          title: '1. RETAKE (Kualitas Gagal)',
          tagText: 'Skor < 80%',
          tagBg: const Color(0xFFFEE2E2),
          tagTextColor: const Color(0xFFB91C1C),
          desc: 'Citra buram atau artefak silau ditolak oleh Quality Gate AI sebelum dianalisis.',
        ),
        const SizedBox(height: 10),

        // 2. ANALYZE Card
        _buildTriaseCard(
          icon: Icons.auto_awesome_rounded,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0369A1),
          title: '2. ANALYZE (Inferensi Mandiri)',
          tagText: 'Reliability > 85%',
          tagBg: const Color(0xFFE0F2FE),
          tagTextColor: const Color(0xFF0369A1),
          desc: 'Akurasi tinggi; model memetakan eksudat, mikroaneurisma, dan perdarahan retina secara mandiri.',
        ),
        const SizedBox(height: 10),

        // 3. HUMAN REVIEW Card
        _buildTriaseCard(
          icon: Icons.medical_services_outlined,
          iconBg: const Color(0xFFEDE9FE),
          iconColor: const Color(0xFF6D28D9),
          title: '3. HUMAN REVIEW (Spesialis Sp.M)',
          tagText: 'Tele-Oftalmologi',
          tagBg: const Color(0xFFEDE9FE),
          tagTextColor: const Color(0xFF6D28D9),
          desc: 'Hasil ambang batas dialihkan ke dokter spesialis mata (Sp.M) untuk validasi resmi sekunder.',
        ),
      ],
    );
  }

  Widget _buildTriaseCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String tagText,
    required Color tagBg,
    required Color tagTextColor,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaTextHeading,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tagText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: tagTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Edukasi & Standar Klinis
  Widget _buildSectionStandarKlinis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.figmaBlue, size: 16),
              SizedBox(width: 8),
              Text(
                'Pedoman Klinis Skrining Nasional (PERDAMI)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.figmaTextHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Skrining fundus wajib dilakukan minimal 1 kali per tahun bagi setiap penderita Diabetes Melitus tipe 1 & 2.\n• Rujukan ke FKRTL (RS Mata) diberikan bila terdeteksi NPDR sedang, berat, atau PDR.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudDetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _HudDetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: AppColors.figmaTextMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaTextHeading,
          ),
        ),
      ],
    );
  }
}
