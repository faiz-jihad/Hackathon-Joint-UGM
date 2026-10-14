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

                      const SizedBox(height: 16),

                      // 1b. Maskot Retiva Greeting & Health Reminder
                      _buildRetivaMascotGreetingCard(),

                      const SizedBox(height: 16),

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

                      // 6b. Alur Klinis Pasien 4 Tahap (Masalah -> Diagnosis -> Solusi -> Penanganan)
                      _buildSectionAlurEmpatTahap(),

                      const SizedBox(height: 24),

                      // 7. Edukasi & Standar Klinis Kemenkes / PERDAMI
                      _buildSectionStandarKlinis(),

                      const SizedBox(height: 24),

                      // 8. Sahabat Sehat Retiva & Nilai Kepribadian
                      _buildSectionSahabatRetiva(),

                      const SizedBox(height: 20),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildMedicaBottomNav(),
      );
    }

  Widget _buildMedicaBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.camera_alt_rounded,
                label: 'Skrining AI',
                isActive: false,
                isSpecial: true,
                onTap: _navigateToUpload,
              ),
              _buildNavItem(
                icon: Icons.psychology_rounded,
                label: 'Care AI',
                isActive: false,
                onTap: _navigateToCareCompanion,
              ),
              _buildNavItem(
                icon: Icons.badge_outlined,
                label: 'Pasien RM',
                isActive: false,
                onTap: _navigateToHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    if (isSpecial) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33246BFD),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner Konteks Faskes Puskesmas
  Widget _buildFaskesDutyBanner() {
    final isOnline = ApiConstants.isOnline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
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
                    SizedBox(height: 2),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'SATUSEHAT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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

  /// 1b. Retiva Companion Mascot Warm Greeting Card
  Widget _buildRetivaMascotGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E4FF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A246BFD),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x142196F3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/mascot_laptop.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset('assets/images/pose_menyapa.png', fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TEMAN KESEHATAN',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Retiva Companion',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '“Jangan lupa cek gula darah hari ini, ya! 💙 Kesehatan kamu penting!”',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bersama Retiva, langkah kecil untuk hidup lebih sehat.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Primary Action Scanner CTA (Medica Style Hero Banner with Doctor Mascot)
  Widget _buildHeroScannerCta() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF246BFD), Color(0xFF5089FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D246BFD),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToUpload,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Mascot Doctor Avatar
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Image.asset(
                        'assets/images/pose_menyapa.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Mulai Skrining Fundus',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.bolt, color: Color(0xFFFDE047), size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload foto OD/OS • Quality Gate AI • Diagnosis ICDR',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFFF0F5FF),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ambil Foto Sekarang',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                          ],
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

  /// Hub Menu Cepat Khusus Alur Faskes dengan Maskot Retiva
  Widget _buildQuickActionHub() {
    return Row(
      children: [
        // 1. Data Pasien
        Expanded(
          child: _buildActionTile(
            title: 'Rekam Medis',
            subtitle: 'Antrean NIK',
            imageAsset: 'assets/images/pose_melangkah.png',
            iconColor: const Color(0xFF0284C7),
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
            imageAsset: 'assets/images/pose_peduli.png',
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            borderColor: const Color(0xFFDDD6FE),
            onTap: _navigateToCareCompanion,
          ),
        ),
        const SizedBox(width: 10),

        // 3. Rujukan Sp.M
        Expanded(
          child: _buildActionTile(
            title: 'Rujukan Sp.M',
            subtitle: 'Format BPJS',
            imageAsset: 'assets/images/pose_menjelaskan.png',
            iconColor: const Color(0xFFFF7A00),
            bgColor: const Color(0xFFFFF4EC),
            borderColor: const Color(0xFFFFD8BF),
            onTap: _navigateToReferral,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    IconData? icon,
    String? imageAsset,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageAsset != null
                        ? Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(icon ?? Icons.circle, color: iconColor, size: 18),
                            ),
                          )
                        : Icon(icon ?? Icons.circle, color: iconColor, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: AppColors.softCardShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 3),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.statusGreenSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        latestPatient.diabetesProfile?.diabetesType ?? 'T2DM',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusGreenDark,
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

  /// Alur Klinis Pasien 4 Tahap (Masalah -> Diagnosis -> Solusi -> Penanganan Kedepan)
  Widget _buildSectionAlurEmpatTahap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alur Klinis Pasien 4 Tahap',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.figmaTextHeading,
                    ),
                  ),
                  Text(
                    'Alur terstruktur & transparan dari skrining awal hingga monitoring jangka panjang',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.figmaTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tahap 1 Card: MASALAH
        _buildPathwayStageCard(
          number: '1',
          stageName: 'MASALAH',
          title: 'Anamnesis Pasien & Faktor Risiko',
          description:
              'Identifikasi keluhan visual subjektif (pandangan kabur, floaters), durasi diabetes melitus, kadar HbA1c terakhir, profil tekanan darah, dan mata terperiksa (OD/OS).',
          accentColor: const Color(0xFFF59E0B),
          icon: Icons.assignment_late_outlined,
          badgeText: 'Faktor Risiko & Gejala',
        ),
        const SizedBox(height: 10),

        // Tahap 2 Card: DIAGNOSIS
        _buildPathwayStageCard(
          number: '2',
          stageName: 'DIAGNOSIS',
          title: 'Temuan Medis & Verifikasi Dokter Sp.M',
          description:
              'Klasifikasi ICDR (No DR s/d PDR), kode ICD-10 resmi (H36.0), peta atensi Grad-CAM, biomarker mikrovaskular (mikroaneurisma, eksudat), dan validasi dokter spesialis mata.',
          accentColor: const Color(0xFF246BFD),
          icon: Icons.biotech_outlined,
          badgeText: 'ICD-10 & Explainable AI',
        ),
        const SizedBox(height: 10),

        // Tahap 3 Card: SOLUSI
        _buildPathwayStageCard(
          number: '3',
          stageName: 'SOLUSI',
          title: 'Tindakan Medis & Rujukan BPJS',
          description:
              'Protokol tindakan medis akut (evaluasi OCT makula, laser PRP/anti-VEGF jika terindikasi), penerbitan Surat Pengantar Rujukan (SPK) BPJS SatuSehat, dan pilihan RS Mata rujukan.',
          accentColor: const Color(0xFF00C566),
          icon: Icons.medical_services_outlined,
          badgeText: 'SPK BPJS & Tindakan Cito',
        ),
        const SizedBox(height: 10),

        // Tahap 4 Card: PENANGANAN
        _buildPathwayStageCard(
          number: '4',
          stageName: 'PENANGANAN',
          title: 'Monitoring Berkelanjutan & Target Sehat',
          description:
              'Jadwal kontrol berkala PERDAMI, target metabolik (<7% HbA1c, <130/80 mmHg), nutrisi ramah retina (Lutein & Omega-3), tanda bahaya darurat (Red Flags), serta AI Care Companion.',
          accentColor: const Color(0xFF8B5CF6),
          icon: Icons.event_repeat_rounded,
          badgeText: 'Jadwal Kontrol & Edukasi',
        ),
      ],
    );
  }

  Widget _buildPathwayStageCard({
    required String number,
    required String stageName,
    required String title,
    required String description,
    required Color accentColor,
    required IconData icon,
    required String badgeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
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
                      '$stageName: $title',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
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
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.4,
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

  /// Sahabat Sehat Retiva & Nilai Kepribadian Brand
  Widget _buildSectionSahabatRetiva() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F246BFD),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/retiva_app_badge.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sahabat Sehat Retiva',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.figmaTextHeading,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '“Sehat hari ini, jelas esok nanti 💙”',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Retiva hadir sebagai teman perjalanan Anda dalam menjaga kesehatan mata dan mengelola diabetes dengan pendekatan yang ramah, hangat, dan terpercaya sesuai standar PERDAMI.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildValuePill('💙 Hangat & Peduli', const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildValuePill('✨ Ramah & Positif', const Color(0xFFECFDF5), const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildValuePill('🛡️ Terpercaya & Klinis', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              _buildValuePill('💪 Semangat Sehat', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuePill(String text, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
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
