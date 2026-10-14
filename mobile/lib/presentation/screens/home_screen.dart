// home_screen.dart - REFACTORED VERSION
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
import 'daily_care_agenda_screen.dart';
import 'daily_health_checkin_screen.dart';
import 'smart_meal_detail_screen.dart';
import 'sos_activation_screen.dart';
import '../../core/services/widget_service.dart';

class HomeScreen extends StatefulWidget {
  final String title;
  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  // Design tokens - konsisten
  static const double _spaceXs = 8;
  static const double _spaceSm = 12;
  static const double _spaceMd = 16;
  static const double _spaceLg = 24;
  static const double _spaceXl = 32;
  static const double _radiusSm = 12;
  static const double _radiusMd = 16;
  static const double _radiusLg = 20;

  @override
  void initState() {
    super.initState();
    WidgetService.initializeDefaultWidgetData();
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

  // Navigation helpers
  void _navigateToUpload() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => UploadFundusScreen(
        initialPatient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToHistory() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const PatientHistoryScreen()));

  void _navigateToCareCompanion() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => CareCompanionHubScreen(
        patient: _patients.isNotEmpty ? _patients.first : null, initialStep: 1)));

  void _navigateToReferral() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ReferralLetterScreen(
        patient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToDailyCare() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DailyCareAgendaScreen(
        patient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToDailyCheckIn() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DailyHealthCheckinScreen(
        patient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToSos() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SosActivationScreen(
                patientId: _patients.isNotEmpty ? _patients.first.id : null,
                patientName: _patients.isNotEmpty ? _patients.first.fullName : null,
                patientNik: _patients.isNotEmpty ? _patients.first.nik : null,
                patientPhone: _patients.isNotEmpty ? _patients.first.phone : null,
              )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSos,
        backgroundColor: const Color(0xFFDC2626),
        elevation: 6,
        icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
        label: const Text(
          'SOS DARURAT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BrandHeader(),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.figmaBlue),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLiveDashboardData,
                color: AppColors.figmaBlue,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // === HERO SECTION ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildHeroSection(),
                      ),
                    ),

                    // === RETIVA SOS EMERGENCY CARD ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceMd, 20, 0),
                        child: _buildSosEmergencyCard(),
                      ),
                    ),

                    // === QUICK STATS ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceMd, 20, 0),
                        child: _buildQuickStats(),
                      ),
                    ),

                    // === PRIMARY ACTIONS ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildPrimaryActions(),
                      ),
                    ),

                    // === RECENT PATIENT ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildRecentPatientSection(),
                      ),
                    ),

                    // === CLINICAL WORKFLOW (Collapsible) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildClinicalWorkflow(),
                      ),
                    ),

                    // === RETIVA COMPANION ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildRetivaCompanion(),
                      ),
                    ),

                    // === FOOTER INFO ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, _spaceLg),
                        child: _buildFooterInfo(),
                      ),
                    ),

                    // Bottom padding untuk bottom nav
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ============ HERO SECTION ============
  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Poli Retinopati DM',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildOnlineStatusBadge(),
          ],
        ),
        const SizedBox(height: _spaceMd),

        // Hero Scanner Card - LEBIH BESAR & MENONJOL
        _buildHeroScannerCard(),
      ],
    );
  }

  Widget _buildSosEmergencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToSos,
          borderRadius: BorderRadius.circular(_radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
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
                          const Text(
                            'Retiva SOS Darurat',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SIAGA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Kirim sinyal bahaya, lokasi GPS, dan notifikasi ke keluarga & Puskesmas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F1D1D),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFFB91C1C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi, Dokter';
    if (hour < 15) return 'Selamat siang, Dokter';
    if (hour < 18) return 'Selamat sore, Dokter';
    return 'Selamat malam, Dokter';
  }

  Widget _buildOnlineStatusBadge() {
    final isOnline = ApiConstants.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF059669) : const Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScannerCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E5EFF), Color(0xFF4B83FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E5EFF).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToUpload,
          borderRadius: BorderRadius.circular(_radiusLg),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                color: Color(0xFFFDE047), size: 12),
                              SizedBox(width: 4),
                              Text(
                                'AI-POWERED',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Skrining Fundus Baru',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload foto OD/OS • Quality Gate AI • Diagnosis ICDR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                size: 16, color: Color(0xFF1E5EFF)),
                              SizedBox(width: 8),
                              Text(
                                'Ambil Foto',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5EFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ QUICK STATS ============
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF1E5EFF),
          iconBg: const Color(0xFFEFF6FF),
          value: '${_patients.length}',
          label: 'Total Pasien',
        )),
        const SizedBox(width: _spaceSm),
        Expanded(child: _buildStatCard(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF059669),
          iconBg: const Color(0xFFECFDF5),
          value: '96.4%',
          label: 'Akurasi AI',
        )),
        const SizedBox(width: _spaceSm),
        Expanded(child: _buildStatCard(
          icon: Icons.schedule_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFFFBEB),
          value: '24',
          label: 'Hari Ini',
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============ PRIMARY ACTIONS ============
  Widget _buildPrimaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Cepat',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: _spaceSm),
        Row(
          children: [
            Expanded(child: _buildActionCard(
              icon: Icons.folder_shared_rounded,
              iconColor: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
              title: 'Rekam Medis',
              subtitle: 'Database pasien',
              onTap: _navigateToHistory,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _buildActionCard(
              icon: Icons.psychology_rounded,
              iconColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFF5F3FF),
              borderColor: const Color(0xFFDDD6FE),
              title: 'Care AI',
              subtitle: 'Edukasi & gizi',
              onTap: _navigateToCareCompanion,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _buildActionCard(
              icon: Icons.description_rounded,
              iconColor: const Color(0xFFFF7A00),
              bgColor: const Color(0xFFFFF4EC),
              borderColor: const Color(0xFFFFD8BF),
              title: 'Rujukan',
              subtitle: 'Format BPJS',
              onTap: _navigateToReferral,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(_radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radiusMd),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
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
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ RECENT PATIENT ============
  Widget _buildRecentPatientSection() {
    final latestPatient = _patients.isNotEmpty ? _patients.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pasien Terakhir',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: _navigateToHistory,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E5EFF),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                    size: 16, color: Color(0xFF1E5EFF)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: _spaceSm),
        if (latestPatient == null)
          _buildEmptyPatientCard()
        else
          _buildPatientCard(latestPatient),
      ],
    );
  }

  Widget _buildEmptyPatientCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
              color: Color(0xFF94A3B8), size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Pasien',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai skrining pasien diabetes pertama',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5EFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mulai Skrining',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded,
                  color: Color(0xFF1E5EFF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIK: ${patient.nik} • ${patient.age} Thn (${patient.gender == "MALE" ? "L" : "P"})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  patient.diabetesProfile?.diabetesType ?? 'T2DM',
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _buildPatientDetail(
                  'Terapi', patient.diabetesProfile?.currentTreatment ?? 'Oral Med')),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                Expanded(child: _buildPatientDetail(
                  'HbA1c',
                  patient.diabetesProfile?.lastHbA1c != null
                    ? '${patient.diabetesProfile!.lastHbA1c}%'
                    : '7.8%',
                )),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                Expanded(child: _buildPatientDetail('Target', 'OD & OS')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ============ CLINICAL WORKFLOW (Collapsible) ============
  Widget _buildClinicalWorkflow() {
    return _CollapsibleSection(
      title: 'Alur Klinis Retiva',
      subtitle: '4 tahap penanganan pasien retinopati DM',
      icon: Icons.alt_route_rounded,
      iconColor: const Color(0xFF1E5EFF),
      iconBg: const Color(0xFFEFF6FF),
      initiallyExpanded: false,
      child: Column(
        children: [
          _buildWorkflowStep(
            step: '1',
            title: 'Anamnesis & Faktor Risiko',
            description:
              'Identifikasi keluhan visual, durasi DM, HbA1c terakhir, dan mata terperiksa.',
            color: const Color(0xFFF59E0B),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '2',
            title: 'Diagnosis & Verifikasi Sp.M',
            description:
              'Klasifikasi ICDR, kode ICD-10, heatmap Grad-CAM, validasi dokter spesialis.',
            color: const Color(0xFF1E5EFF),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '3',
            title: 'Tindakan & Rujukan BPJS',
            description:
              'Protokol medis akut, SPK BPJS SatuSehat, pilihan RS Mata rujukan.',
            color: const Color(0xFF00C566),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '4',
            title: 'Monitoring Berkelanjutan',
            description:
              'Jadwal kontrol PERDAMI, target metabolik, nutrisi retina, AI companion.',
            color: const Color(0xFF8B5CF6),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep({
    required String step,
    required String title,
    required String description,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
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
          ),
        ],
      ),
    );
  }

  // ============ RETIVA COMPANION ============
  Widget _buildRetivaCompanion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F5FF), Color(0xFFE8F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E5EFF).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/mascot_laptop.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF1E5EFF), size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retiva Companion',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Teman kesehatan harian Anda 💙',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: const Color(0xFF1E5EFF).withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '"Jangan lupa cek gula darah hari ini! Kesehatan kamu penting."',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCompanionButton(
                  icon: Icons.calendar_month_rounded,
                  label: 'Agenda',
                  isPrimary: true,
                  onTap: _navigateToDailyCare,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompanionButton(
                  icon: Icons.timer_outlined,
                  label: 'Check-in',
                  isPrimary: false,
                  onTap: _navigateToDailyCheckIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompanionButton(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Menu',
                  isPrimary: false,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SmartMealDetailScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF1E5EFF) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isPrimary
              ? null
              : Border.all(color: const Color(0xFF1E5EFF).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                size: 14,
                color: isPrimary ? Colors.white : const Color(0xFF1E5EFF)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : const Color(0xFF1E5EFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ FOOTER INFO ============
  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                color: Color(0xFF1E5EFF), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pedoman Klinis PERDAMI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'v2.1',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E5EFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Skrining fundus wajib minimal 1x/tahun untuk penderita DM tipe 1 & 2.\n'
            '• Rujukan FKRTL diberikan bila terdeteksi NPDR sedang, berat, atau PDR.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============ BOTTOM NAV ============
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                icon: Icons.psychology_rounded,
                label: 'Care AI',
                isActive: false,
                onTap: _navigateToCareCompanion,
              ),
              _buildNavItem(
                icon: Icons.camera_alt_rounded,
                label: 'Skrining',
                isActive: false,
                isPrimary: true,
                onTap: _navigateToUpload,
              ),
              _buildNavItem(
                icon: Icons.folder_rounded,
                label: 'Pasien',
                isActive: false,
                onTap: _navigateToHistory,
              ),
              _buildNavItem(
                icon: Icons.description_rounded,
                label: 'Rujukan',
                isActive: false,
                onTap: _navigateToReferral,
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
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5EFF), Color(0xFF4B83FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E5EFF).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF1E5EFF) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF1E5EFF) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ COLLAPSIBLE SECTION WIDGET ============
class _CollapsibleSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon,
                        color: widget.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B), size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}