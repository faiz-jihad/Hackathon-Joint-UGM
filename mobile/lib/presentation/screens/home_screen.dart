import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/daily_agenda_model.dart';
import '../../data/models/smart_meal_model.dart';
import '../widgets/caresync_logo.dart';
import 'upload_fundus_screen.dart';
import 'patient_history_screen.dart';
import 'care_companion_hub_screen.dart';
import 'referral_letter_screen.dart';
import 'daily_care_agenda_screen.dart';
import 'daily_health_checkin_screen.dart';
import 'smart_meal_detail_screen.dart';
import 'sos_activation_screen.dart';
import 'profile_screen.dart';
import 'top_doctors_screen.dart';
import 'auth_welcome_screen.dart';
import '../widgets/notification_bell_widget.dart';
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
  int _currentNavIndex = 0;
  bool _previewLargeWidget = false;
  DailyAgendaSummary? _agendaSummary;
  SmartMealItem? _smartMeal;
  final TextEditingController _searchController = TextEditingController();
  String _currentUserName = '';
  Map<String, dynamic>? _latestScreening;

  PatientModel? get _activePatient => _patients.isNotEmpty ? _patients.first : null;

  // Design tokens - konsisten
  static const double _spaceSm = 12;
  static const double _spaceLg = 24;
  static const double _radiusMd = 16;

  @override
  void initState() {
    super.initState();
    WidgetService.initializeDefaultWidgetData();
    _loadLiveDashboardData();
  }

  Future<void> _loadLiveDashboardData() async {
    try {
      final savedName = await ApiClient().getCurrentUserName();
      if (mounted && savedName != null && savedName.isNotEmpty) {
        setState(() => _currentUserName = savedName);
      }
    } catch (_) {}

    try {
      final patients = await ApiClient().getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
      final activeId = patients.isNotEmpty ? patients.first.id : 'P-001';
      await _syncWidgetWithBackend(activeId);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }

    try {
      final rawScreenings = await ApiClient().getScreenings();
      Map<String, dynamic>? validLatest;
      for (final scr in rawScreenings) {
        final id = (scr['id'] ?? '').toString();
        if (id.startsWith('scr-base-') ||
            id == 'scr-base-001' ||
            id == 'scr-base-002' ||
            id.startsWith('sample-') ||
            id.startsWith('demo-')) {
          continue;
        }
        validLatest = scr;
        break;
      }
      if (mounted) {
        setState(() => _latestScreening = validLatest);
      }
    } catch (_) {}
  }


  Future<void> _syncWidgetWithBackend(String patientId) async {
    try {
      final agenda = await ApiClient().getDailyAgenda(patientId);
      final widgetState = await WidgetService.getWidgetState();

      // Merge in-place task completions made directly from launcher widget
      for (int i = 0; i < agenda.agenda.length; i++) {
        final localKey = 'item${i}Done';
        if (widgetState.containsKey(localKey)) {
          agenda.agenda[i].isCompleted = widgetState[localKey] as bool;
        }
      }

      await WidgetService.updateWidgetData(agenda);
      if (mounted) {
        setState(() {
          _agendaSummary = agenda;
        });
      }
    } catch (_) {}

    try {
      final meal = await ApiClient().getSmartMealRecommendation(patientId);
      final widgetState = await WidgetService.getWidgetState();
      if (widgetState['nextMealIsEaten'] == true) {
        meal.isEaten = true;
      }
      await WidgetService.updateNextMealData(meal);
      if (mounted) {
        setState(() {
          _smartMeal = meal;
        });
      }
    } catch (_) {}
  }

  // Navigation helpers
  Future<void> _navigateToUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadFundusScreen(
          initialPatient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
    _loadLiveDashboardData();
  }

  Future<void> _navigateToHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientHistoryScreen(),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
    _loadLiveDashboardData();
  }

  Future<void> _navigateToCareCompanion({int initialStep = 1}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CareCompanionHubScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
          initialStep: initialStep,
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
    final activeId = _patients.isNotEmpty ? _patients.first.id : 'P-001';
    _syncWidgetWithBackend(activeId);
  }

  Future<void> _navigateToReferral() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferralLetterScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
  }

  Future<void> _navigateToDailyCare() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCareAgendaScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
    final activeId = _patients.isNotEmpty ? _patients.first.id : 'P-001';
    _syncWidgetWithBackend(activeId);
  }

  Future<void> _navigateToDailyCheckIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyHealthCheckinScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
    final activeId = _patients.isNotEmpty ? _patients.first.id : 'P-001';
    _syncWidgetWithBackend(activeId);
    if (mounted) setState(() {});
  }

  Future<void> _navigateToMealDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SmartMealDetailScreen(),
      ),
    );
    final activeId = _patients.isNotEmpty ? _patients.first.id : 'P-001';
    _syncWidgetWithBackend(activeId);
  }

  void _handleGlobalSearch(String query) {
    _openGlobalSearchSheet(query.trim());
  }

  void _openGlobalSearchSheet([String initialQuery = '']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GlobalSearchSheet(
        initialQuery: initialQuery,
        onNavigateHistory: () {
          Navigator.pop(ctx);
          _navigateToHistory();
        },
        onNavigateReferral: () {
          Navigator.pop(ctx);
          _navigateToReferral();
        },
        onNavigateDoctors: (q) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TopDoctorsScreen(initialQuery: q)),
          );
        },
        onNavigateUpload: () {
          Navigator.pop(ctx);
          _navigateToUpload();
        },
        onNavigateCareCompanion: () {
          Navigator.pop(ctx);
          _navigateToCareCompanion();
        },
        onNavigateDailyCheckIn: () {
          Navigator.pop(ctx);
          _navigateToDailyCheckIn();
        },
        onNavigateMealDetail: () {
          Navigator.pop(ctx);
          _navigateToMealDetail();
        },
        onNavigateSos: () {
          Navigator.pop(ctx);
          _navigateToSos();
        },
        onNavigateProfile: () {
          Navigator.pop(ctx);
          _navigateToProfile();
        },
      ),
    );
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          patient: _patients.isNotEmpty ? _patients.first : null,
        ),
      ),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
  }

  Future<void> _navigateToTopDoctors() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TopDoctorsScreen()),
    );
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
  }

  void _navigateToSos() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SosActivationScreen(
                patientId: _patients.isNotEmpty ? _patients.first.id : null,
                patientName: _patients.isNotEmpty ? _patients.first.fullName : null,
                patientNik: _patients.isNotEmpty ? _patients.first.nik : null,
                patientPhone: _patients.isNotEmpty ? _patients.first.phone : null,
              )));

  Future<void> _onBottomNavTapped(int index) async {
    setState(() => _currentNavIndex = index);
    if (index == 1) {
      await _navigateToTopDoctors();
    } else if (index == 2) {
      await _navigateToUpload();
    } else if (index == 3) {
      await _navigateToHistory();
    } else if (index == 4) {
      await _navigateToProfile();
    }
    if (mounted) {
      setState(() => _currentNavIndex = 0);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi RETIVA Mobile? Anda dapat masuk kembali kapan saja.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiClient().clearToken();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthWelcomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _currentUserName.isNotEmpty
        ? _currentUserName
        : (_activePatient?.fullName.isNotEmpty == true
            ? _activePatient!.fullName
            : 'Pengguna');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // === CareSync TOP BAR (Navbar Tunggal dengan Logo Resmi, Notifikasi & Logout) ===
            _buildCareSyncTopBar(),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLiveDashboardData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // === SEARCH BAR (CareSync style) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _buildCareSyncSearchBar(),
                      ),
                    ),

                    // === USER GREETING & PILLS ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildUserGreeting(patientName),
                      ),
                    ),

                    // === APPOINTMENT / SCREENING REMINDER BANNER ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _buildAppointmentReminderBanner(),
                      ),
                    ),

                    // === AGENTIC AI CARE COMPANION HERO BANNER ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: _buildAgenticCareCompanionBanner(),
                      ),
                    ),

                    // === WHAT DO YOU NEED? (CareSync 2x2 Grid) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildWhatDoYouNeedGrid(),
                      ),
                    ),

                    // === WIDGET LAYAR UTAMA HP (HOME SCREEN WIDGET) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildHomeScreenWidgetSection(),
                      ),
                    ),

                    // === HEALTH OVERVIEW VITALS ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildHealthOverviewVitals(),
                      ),
                    ),

                    // === HERO RETINAL AI SCANNER BANNER ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _buildHeroScannerCard(),
                      ),
                    ),

                    // === RETIVA SOS EMERGENCY CARD ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildSosEmergencyCard(),
                      ),
                    ),

                    // === PRIMARY ACTIONS ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildPrimaryActions(),
                      ),
                    ),

                    // === HASIL SKRINING SAYA ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildMyScreeningSummarySection(),
                      ),
                    ),

                    // === FITUR 3: JURNAL KESEHATAN (DASHBOARD) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildHealthJournalDashboardCard(),
                      ),
                    ),

                    // === FITUR 4: PENGINGAT KONTROL (DASHBOARD) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, _spaceLg, 20, 0),
                        child: _buildControlReminderDashboardCard(),
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
      bottomNavigationBar: _buildCareSyncBottomNav(),
    );
  }

  // ============ 1. CareSync TOP BAR ============
  Widget _buildCareSyncTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CareSyncLogo(
            size: 32,
            showText: true,
            text: 'CareSync',
            subtitle: 'Retina & Diabetes Hub',
          ),
          Row(
            children: [
              // Notifikasi resmi dari navbar kedua yang menggantikan bell sebelumnya
              const NotificationBellWidget(),
              const SizedBox(width: 8),

              // Tombol Keluar Akun (Logout)
              InkWell(
                onTap: _showLogoutDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 2. CareSync SEARCH BAR (Global Engine) ============
  Widget _buildCareSyncSearchBar() {
    return GestureDetector(
      onTap: () => _handleGlobalSearch(_searchController.text),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF246BFD), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _searchController.text.isNotEmpty
                    ? _searchController.text
                    : 'Cari dokter spesialis, riwayat skrining, klinik...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: _searchController.text.isNotEmpty
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ============ 3. USER GREETING & PILLS ============
  Widget _buildUserGreeting(String patientName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // User Avatar
            GestureDetector(
              onTap: _navigateToProfile,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
                  color: const Color(0xFFEFF6FF),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mascot_laptop.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
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
                    'Welcome $patientName',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bagaimana kondisi penglihatan Anda hari ini?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick action pills (CareSync style)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildActionPill(
                label: 'Care Companion',
                icon: Icons.favorite_rounded,
                onTap: () => _navigateToCareCompanion(initialStep: 1),
              ),
              const SizedBox(width: 8),
              _buildActionPill(
                label: 'View Reports',
                icon: Icons.description_outlined,
                onTap: _navigateToHistory,
              ),
              const SizedBox(width: 8),
              _buildActionPill(
                label: 'View Profile',
                icon: Icons.person_outline_rounded,
                onTap: _navigateToProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFEEF4FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6E4FF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 4. APPOINTMENT REMINDER BANNER ============
  Widget _buildAppointmentReminderBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FF), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToDailyCare,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jadwal kontrol mata Anda: 3 hari lagi (Puskesmas Mlati II)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ 4B. RETIVA AGENTIC CARE COMPANION HERO BANNER ============
  Widget _buildAgenticCareCompanionBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCareCompanion(initialStep: 1),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 10),
                                    SizedBox(width: 4),
                                    Text(
                                      'AGENTIC AI • AUTONOMOUS',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF38BDF8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Retiva Care Companion™',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Asisten cerdas pre/post konsultasi Sp.M, kalkulator nutrisi Low-GI otomatis, & sinkronisasi agenda ke widget HP.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Quick AI Feature Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildAgenticFeatureChip(
                        label: 'Tanya Dokter Sp.M',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => _navigateToCareCompanion(initialStep: 1),
                      ),
                      const SizedBox(width: 8),
                      _buildAgenticFeatureChip(
                        label: 'Menu Rendah GI',
                        icon: Icons.restaurant_menu_rounded,
                        onTap: () => _navigateToCareCompanion(initialStep: 3),
                      ),
                      const SizedBox(width: 8),
                      _buildAgenticFeatureChip(
                        label: 'Catat Hasil Dokter',
                        icon: Icons.edit_note_rounded,
                        onTap: () => _navigateToCareCompanion(initialStep: 2),
                      ),
                      const SizedBox(width: 8),
                      _buildAgenticFeatureChip(
                        label: 'Cek Gejala Darurat',
                        icon: Icons.warning_amber_rounded,
                        onTap: () => _navigateToCareCompanion(initialStep: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.widgets_rounded, color: Color(0xFF38BDF8), size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Agenda & menu sinkron ke Launcher Widget',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Buka Hub',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF38BDF8), size: 13),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgenticFeatureChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 5. WHAT DO YOU NEED? (CareSync 2x2 Grid) ============
  Widget _buildWhatDoYouNeedGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What do you need?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CareSyncGridCard(
                icon: Icons.person_search_rounded,
                title: 'My doctor',
                subtitle: 'Konsultasi Sp.M',
                onTap: _navigateToTopDoctors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CareSyncGridCard(
                icon: Icons.assignment_outlined,
                title: 'Medical Reports',
                subtitle: 'Hasil AI & Fundus',
                onTap: _navigateToHistory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CareSyncGridCard(
                icon: Icons.local_hospital_outlined,
                title: 'Find Clinic',
                subtitle: 'Faskes BPJS & Rujukan',
                onTap: _navigateToReferral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CareSyncGridCard(
                icon: Icons.event_available_outlined,
                title: 'My Appointment',
                subtitle: 'Agenda & Pengingat',
                onTap: _navigateToDailyCare,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============ 5B. WIDGET LAYAR UTAMA HP (HOME SCREEN WIDGET) ============
  Widget _buildHomeScreenWidgetSection() {
    final completedCount = _agendaSummary?.completedCount ?? 2;
    final totalCount = _agendaSummary?.totalCount ?? 5;
    final progressText = '$completedCount/$totalCount Selesai';
    final mascotMessage = _agendaSummary?.contextualMascotMessage ??
        'Halo! Semangat hari ini 💙 Jaga pola makan & cek kesehatan harian.';

    final agendaList = (_agendaSummary?.agenda != null && _agendaSummary!.agenda.isNotEmpty)
        ? _agendaSummary!.agenda
        : [
            DailyAgendaItem(
              id: 'fallback-1',
              time: '07.15',
              title: 'Sarapan sehat & Minum Obat',
              subtitle: 'Rendah IG • Metformin 500mg',
              category: 'MEAL',
              badgeLabel: 'Sarapan',
              patientId: 'P-001',
              isCompleted: true,
            ),
            DailyAgendaItem(
              id: 'fallback-2',
              time: '12.30',
              title: 'Makan siang sehat (Nasi Merah & Ikan)',
              subtitle: 'Rekomendasi Menu Gizi Seimbang',
              category: 'MEAL',
              badgeLabel: 'Makan Siang',
              patientId: 'P-001',
              isCompleted: false,
            ),
            DailyAgendaItem(
              id: 'fallback-3',
              time: '20.00',
              title: 'Check-in Mandiri & Evaluasi Gejala',
              subtitle: 'Cek kondisi fisik & gejala mata',
              category: 'LIFESTYLE_CHECK',
              badgeLabel: 'Check-in Harian',
              patientId: 'P-001',
              isCompleted: false,
            ),
          ];

    final displayItems = _previewLargeWidget
        ? agendaList.take(3).toList()
        : agendaList.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: const [
                  Flexible(
                    child: Text(
                      'Widget Layar Utama',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _previewLargeWidget = !_previewLargeWidget),
              child: Text(
                _previewLargeWidget ? 'Ringkas (2x2)' : 'Lengkap (4x3)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text(
          'Pantau agenda harian & minum obat langsung di Home Screen HP Anda',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),

        // Live Widget Preview Container matching CareSync
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6E4FF), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C246BFD),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToDailyCare,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            'assets/images/retiva_app_badge.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CareSync · RETIVA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          progressText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Mascot / Context Greeting
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToDailyCare,
                  borderRadius: BorderRadius.circular(6),
                  child: Text(
                    mascotMessage,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Activity Items list
              ...displayItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildWidgetPreviewItemRow(item),
                  )),

              // Smart Meal section (for large widget mode)
              if (_previewLargeWidget) ...[
                const SizedBox(height: 4),
                _buildWidgetPreviewSmartMealCard(),
                const SizedBox(height: 12),
                _buildWidgetActionPills(),
              ] else ...[
                // Compact mode bottom quick bar
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToDailyCare,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ketuk agenda untuk membuka & mencatat tugas',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Buka',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Pin to Home Screen Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final type = _previewLargeWidget ? 'large' : 'compact';
                    final success = await WidgetService.pinWidgetToHomeScreen(type: type);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF00C566), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Permintaan terkirim! Ketuk "Add to Home screen" pada jendela Android yang muncul.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } else {
                      _showPinWidgetTutorial(context, autoPinned: false);
                    }
                  },
                  icon: const Icon(Icons.add_to_home_screen_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Pasang Widget ke Layar Depan HP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 2,
                    shadowColor: AppColors.primary.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showPinWidgetTutorial(context, autoPinned: false),
                  icon: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF64748B)),
                  label: const Text(
                    'Panduan Pasang Widget Manual di HP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetPreviewItemRow(DailyAgendaItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToDailyCare,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.time,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: item.isCompleted ? AppColors.primary : const Color(0xFF94A3B8),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetPreviewSmartMealCard() {
    final mealName = _smartMeal?.name ?? 'Nasi Merah, Ikan Kembung & Tumis Buncis';
    final mealTime = _smartMeal?.timeRecommendation ?? '12.30';
    final calories = _smartMeal?.nutrition.caloriesKcal.toInt() ?? 385;
    final cost = _smartMeal?.estimatedCostIdr.toInt() ?? 13500;
    final isEaten = _smartMeal?.isEaten ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToMealDetail,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    'Menu Gizi Seimbang · $mealTime',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isEaten ? const Color(0xFFDCFCE7) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      isEaten ? 'Sudah Dimakan ✓' : 'Rekomendasi Siang',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isEaten ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                mealName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$calories kkal · Rendah GI · Est. Rp ${cost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Buka Menu ➔',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetActionPills() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallWidgetActionBtn(
            icon: Icons.checklist_rounded,
            label: 'Agenda',
            color: AppColors.primary,
            bgColor: const Color(0xFFEFF6FF),
            onTap: _navigateToDailyCare,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallWidgetActionBtn(
            icon: Icons.favorite_border_rounded,
            label: 'Check-in',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            onTap: _navigateToDailyCheckIn,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallWidgetActionBtn(
            icon: Icons.restaurant_rounded,
            label: 'Menu Gizi',
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFF0FDF4),
            onTap: _navigateToMealDetail,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallWidgetActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinWidgetTutorial(BuildContext context, {bool autoPinned = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.widgets_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pasang Widget di Layar Depan HP',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Panduan memasang widget di Home Screen Android',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (autoPinned) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF00C566), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Permintaan terkirim! Ketuk "Add to Home screen" pada jendela Android yang muncul.',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _buildTutorialStep(
                step: '1',
                title: 'Kembali ke Layar Utama (Home Screen HP)',
                desc: 'Tekan tombol Home pada smartphone Android Anda.',
              ),
              _buildTutorialStep(
                step: '2',
                title: 'Tekan & Tahan Layar Kosong',
                desc: 'Long-press pada area layar yang masih kosong hingga menu kustomisasi muncul.',
              ),
              _buildTutorialStep(
                step: '3',
                title: 'Pilih Menu "Widgets"',
                desc: 'Cari aplikasi "CareSync Retiva" atau "Retiva Daily Care".',
              ),
              _buildTutorialStep(
                step: '4',
                title: 'Seret Widget ke Layar Depan',
                desc: 'Tarik format Ringkas (2x2) atau Lengkap (4x3). Selesai!',
                isLast: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Saya Mengerti ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTutorialStep({
    required String step,
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD6E4FF)),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ 6. HEALTH OVERVIEW VITALS ============
  Widget _buildHealthOverviewVitals() {
    final latestJournal = DailyHealthCheckinScreen.healthJournalHistory.isNotEmpty
        ? DailyHealthCheckinScreen.healthJournalHistory.first
        : null;
    final displayGlucose = latestJournal?['glucose']?.toString() ?? '118 mg/dL';
    final displayBp = latestJournal?['bp']?.toString().replaceAll(' mmHg', '') ?? '120/80';
    final displayStatus = latestJournal?['status']?.toString() ?? 'Terkontrol';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _navigateToDailyCheckIn,
                borderRadius: BorderRadius.circular(6),
                child: const Row(
                  children: [
                    Text(
                      'Health Overview',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF246BFD)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _navigateToDailyCheckIn,
                child: const Text(
                  'Catat Baru +',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildVitalItem(
                  icon: Icons.bloodtype_rounded,
                  iconColor: const Color(0xFFEF4444),
                  label: 'Gula Darah',
                  value: displayGlucose,
                  status: displayStatus,
                  onTap: _navigateToDailyCheckIn,
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildVitalItem(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF246BFD),
                  label: 'Tekanan Darah',
                  value: displayBp,
                  status: 'Terkontrol',
                  onTap: _navigateToDailyCheckIn,
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildVitalItem(
                  icon: Icons.remove_red_eye_rounded,
                  iconColor: const Color(0xFF246BFD),
                  label: 'Status Retina',
                  value: _latestScreening != null
                      ? (_latestScreening!['aiResult']?['predictedClass']?.toString() ?? 'No DR')
                      : 'No DR',
                  status: 'Terhubung Riwayat',
                  onTap: _navigateToHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============ 7. HERO RETINAL AI SCANNER BANNER ============
  Widget _buildHeroScannerCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF246BFD), Color(0xFF5089FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF246BFD).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToUpload,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SKRINING AI PERDAMI 2024',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Skrining Mata Mandiri',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Foto mata kanan (OD) & kiri (OS) dengan kamera smartphone untuk deteksi retinopati dini.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 15, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Mulai Pemindaian',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // ============ 9. RETIVA SOS EMERGENCY CARD ============
  Widget _buildSosEmergencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToSos,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
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
                        children: [
                          const Flexible(
                            child: Text(
                              'Retiva SOS Darurat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF991B1B),
                              ),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kirim sinyal bahaya & lokasi GPS saat pandangan kabur mendadak',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFB91C1C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





  // ============ PRIMARY ACTIONS ============
  Widget _buildPrimaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan Perawatan Anda',
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
            Expanded(child: _CareSyncActionCard(
              icon: Icons.calendar_month_rounded,
              title: 'Agenda Saya',
              subtitle: 'Jadwal obat & rawat',
              onTap: _navigateToDailyCare,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _CareSyncActionCard(
              icon: Icons.edit_calendar_rounded,
              title: 'Check-in Sehat',
              subtitle: 'Catat gula & tensi',
              onTap: _navigateToDailyCheckIn,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _CareSyncActionCard(
              icon: Icons.set_meal_rounded,
              title: 'Menu Nutrisi',
              subtitle: 'Porsi 3J diabetes',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SmartMealDetailScreen())),
            )),
          ],
        ),
        const SizedBox(height: _spaceSm),
        Row(
          children: [
            Expanded(child: _CareSyncActionCard(
              icon: Icons.track_changes_rounded,
              title: 'Pelacakan Rujukan',
              subtitle: 'Status SPK & RS',
              onTap: _navigateToReferral,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _CareSyncActionCard(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Rencana Dokter',
              subtitle: 'Terapi & instruksi',
              onTap: _navigateToCareCompanion,
            )),
            const SizedBox(width: _spaceSm),
            Expanded(child: _CareSyncActionCard(
              icon: Icons.school_rounded,
              title: 'Edukasi Kondisi',
              subtitle: 'Pola hidup 4 pilar',
              onTap: () => _showEducationGuideModal(context),
            )),
          ],
        ),
      ],
    );
  }

  void _showEducationGuideModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
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
            const Row(
              children: [
                Icon(Icons.school_rounded, color: Color(0xFF246BFD), size: 22),
                SizedBox(width: 8),
                Text(
                  'Edukasi Sesuai Kondisi Pasien',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Panduan 4 pilar untuk menjaga kejernihan retina dan kestabilan metabolisme diabetes.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildEduModalCard(
                    title: '1. Pola Makan (Diet 3J Diabetes)',
                    desc: 'Jadwal teratur 3x makan + 2x selingan. Jumlah kalori piring T (1/2 sayur, 1/4 karbohidrat kompleks, 1/4 protein tanpa lemak). Jenis makanan Low-GI kaya antioksidan Lutein & Zeaxanthin (bayam, brokoli, ikan kembung). Batasi gula & natrium < 2000 mg/hari.',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 10),
                  _buildEduModalCard(
                    title: '2. Aktivitas Fisik & Olahraga',
                    desc: 'Lakukan olahraga aerobik ringan 150 menit/minggu (30 menit/hari) seperti jalan santai atau senam diabetes. Perhatian: Hindari angkat beban berat atau mengejan kuat untuk mencegah risiko perdarahan retina.',
                    icon: Icons.directions_walk_rounded,
                    color: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 10),
                  _buildEduModalCard(
                    title: '3. Kepatuhan Pengobatan',
                    desc: 'Konsumsi obat antidiabetes oral atau insulin teratur sesuai dosis dokter spesialis. Jangan menghentikan pengobatan sendiri. Disiplin menggunakan obat tetes mata bila diresepkan.',
                    icon: Icons.medication_liquid_rounded,
                    color: const Color(0xFF246BFD),
                  ),
                  const SizedBox(height: 10),
                  _buildEduModalCard(
                    title: '4. Jadwal & Target Kontrol',
                    desc: 'Target HbA1c < 7.0% dan tekanan darah < 130/80 mmHg. Evaluasi funduskopi mata rutin setiap 3–6 bulan sekali tanpa menunggu timbulnya keluhan buram.',
                    icon: Icons.event_repeat_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF246BFD),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Saya Mengerti Panduan Ini', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEduModalCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // ============ HASIL SKRINING SAYA ============
  String _formatScreeningDate(String iso) {
    if (iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthName = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '${dt.month}';
      return '${dt.day} $monthName ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildMyScreeningSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hasil Skrining Retina Terakhir Saya',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _navigateToHistory,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Riwayat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                      size: 16, color: Color(0xFF246BFD)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _spaceSm),
        if (_latestScreening != null)
          _buildLatestScreeningCard(_latestScreening!)
        else if (_activePatient != null)
          _buildPatientCard(_activePatient!)
        else
          _buildEmptyPatientCard(),
      ],
    );
  }

  Widget _buildLatestScreeningCard(Map<String, dynamic> scr) {
    final createdAtIso = (scr['createdAt'] ?? '').toString();
    final dateText = _formatScreeningDate(createdAtIso);

    final images = (scr['images'] as List?) ?? [];
    final eyePosition = (images.isNotEmpty ? (images[0]['eye'] ?? 'OD') : 'OD').toString().toUpperCase();
    final eyeName = eyePosition == 'OS' ? 'Mata Kiri (OS)' : 'Mata Kanan (OD)';

    final aiResult = scr['aiResult'];
    final predictedClass = aiResult?['predictedClass']?.toString() ?? 'Tidak Ada Retinopati (No DR)';
    final humanReview = scr['humanReview'];
    final isDoctorReviewed = humanReview != null;

    return _HoverElevationCard(
      onTap: _navigateToHistory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.remove_red_eye_rounded,
                  color: Color(0xFF246BFD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemeriksaan Fundus: $eyeName',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDoctorReviewed ? Icons.verified_rounded : Icons.check_circle_outline_rounded,
                      size: 11,
                      color: const Color(0xFF246BFD),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDoctorReviewed ? 'Terverifikasi Sp.M' : 'Selesai AI',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasil Diagnosis Retina Terakhir',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        predictedClass,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF246BFD),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _navigateToHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka Riwayat',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPatientCard() {
    return _HoverElevationCard(
      onTap: _navigateToHistory,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined,
              color: Color(0xFF246BFD), size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Riwayat Skrining',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lakukan pemeriksaan fundus retina mandiri untuk deteksi dini komplikasi diabetes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToUpload,
                  icon: const Icon(Icons.camera_alt_rounded, size: 15),
                  label: const Text(
                    'Mulai Skrining',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToHistory,
                  icon: const Icon(Icons.history_rounded, size: 15, color: Color(0xFF246BFD)),
                  label: const Text(
                    'Buka Riwayat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF246BFD),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: const BorderSide(color: Color(0xFF246BFD), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return _HoverElevationCard(
      onTap: _navigateToHistory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded,
                  color: Color(0xFF246BFD), size: 24),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIK: ${patient.nik} • ${patient.age} Thn (${patient.gender == "MALE" ? "Laki-laki" : "Perempuan"})',
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
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  patient.diabetesProfile?.diabetesType ?? 'T2DM',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Retina Status Cards (OD & OS)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'STATUS KESEHATAN RETINA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 10, color: Color(0xFF246BFD)),
                          SizedBox(width: 3),
                          Text(
                            'Diverifikasi Sp.M',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF246BFD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF246BFD), size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mata Kanan (OD)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text('Normal (No DR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF246BFD), size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mata Kiri (OS)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  Text('Normal (No DR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
                                ],
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
          const SizedBox(height: 12),

          // Detail indicators
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _buildPatientDetail(
                  'Terapi Saat Ini', patient.diabetesProfile?.currentTreatment ?? 'Oral Med')),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                Expanded(child: _buildPatientDetail(
                  'HbA1c Terakhir',
                  patient.diabetesProfile?.lastHbA1c != null
                    ? '${patient.diabetesProfile!.lastHbA1c}%'
                    : '7.8%',
                )),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                Expanded(child: _buildPatientDetail('Skrining Rutin', 'Okt 2027')),
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

  // ===========================================================================
  // FITUR 3: JURNAL KESEHATAN (DASHBOARD)
  // Menyimpan hasil gula darah dan tekanan darah untuk dibawa saat konsultasi.
  // ===========================================================================
  Widget _buildHealthJournalDashboardCard() {
    final latestJournal = DailyHealthCheckinScreen.healthJournalHistory.isNotEmpty
        ? DailyHealthCheckinScreen.healthJournalHistory.first
        : null;
    final displayGlucose = latestJournal?['glucose']?.toString() ?? '118 mg/dL';
    final displayBp = latestJournal?['bp']?.toString() ?? '120/80 mmHg';
    final displayStatus = latestJournal?['status']?.toString() ?? 'Optimal';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF246BFD), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jurnal Kesehatan Pasien',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Gula darah & tekanan darah terpantau',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF246BFD)),
                    const SizedBox(width: 3),
                    Text(
                      displayStatus,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Two-metric row: Glucose & Blood Pressure
          Row(
            children: [
              Expanded(
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
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF246BFD),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Gula Darah (GDP)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayGlucose,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Target < 130 mg/dL',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF246BFD)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF246BFD),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Tekanan Darah', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayBp,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Target < 130/80 mmHg',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF246BFD)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToDailyCheckIn,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Catat Jurnal Baru', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showConsultationJournalSheet(context),
                  icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF246BFD)),
                  label: const Text('Rekap Dokter', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF246BFD))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF246BFD)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FITUR 4: PENGINGAT KONTROL (DASHBOARD)
  // Mengurangi risiko pengguna lupa atau menunda pemeriksaan mata dan diabetes.
  // ===========================================================================
  Widget _buildControlReminderDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF246BFD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pengingat Kontrol Dokter',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF246BFD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '7 Hari Lagi',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF1D4ED8)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kamis, 22 Oktober 2026 • 09:00 WIB',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Poli Mata RS Mata Dr. Yap Yogyakarta • Evaluasi Retina Rutin',
            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _navigateToCareCompanion,
              icon: const Icon(Icons.calendar_month_rounded, size: 15),
              label: const Text('Buka Rencana Perawatan & Ubah Jadwal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF246BFD),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConsultationJournalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
            const Row(
              children: [
                Icon(Icons.assignment_rounded, color: Color(0xFF246BFD), size: 22),
                SizedBox(width: 8),
                Text(
                  'Rekap Jurnal Kesehatan untuk Dokter',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tunjukkan rekap ini saat berkonsultasi dengan dokter spesialis mata atau penyakit dalam.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildJournalRekapItem('15 Okt 2026, 07:15 WIB', '118 mg/dL', 'Puasa (GDP)', '120/80 mmHg', 'Optimal'),
                  const SizedBox(height: 8),
                  _buildJournalRekapItem('14 Okt 2026, 19:30 WIB', '142 mg/dL', '2 Jam PP', '126/82 mmHg', 'Terkontrol'),
                  const SizedBox(height: 8),
                  _buildJournalRekapItem('13 Okt 2026, 07:30 WIB', '124 mg/dL', 'Puasa (GDP)', '128/84 mmHg', 'Terkontrol'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF246BFD),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tutup Rekap', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalRekapItem(String date, String glucose, String context, String bp, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text('Gula Darah: $glucose ($context)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text('Tekanan Darah: $bp', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF246BFD))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildClinicalWorkflow() {
    return _CollapsibleSection(
      title: 'Panduan Alur Perawatan Anda',
      subtitle: '4 langkah menjaga mata tetap sehat bersama Retiva',
      icon: Icons.alt_route_rounded,
      iconColor: const Color(0xFF246BFD),
      iconBg: const Color(0xFFEFF6FF),
      initiallyExpanded: false,
      child: Column(
        children: [
          _buildWorkflowStep(
            step: '1',
            title: 'Pemeriksaan Mandiri & Gejala',
            description:
              'Foto mata kanan & kiri dengan adaptor smartphone atau kamera fundus, serta catat keluhan pandangan.',
            color: const Color(0xFF246BFD),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '2',
            title: 'Telaah AI & Verifikasi Dokter Sp.M',
            description:
              'AI Retiva menganalisis risiko mikrovaskular retina dan divalidasi langsung oleh dokter spesialis mata.',
            color: const Color(0xFF246BFD),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '3',
            title: 'Rujukan Terintegrasi BPJS SatuSehat',
            description:
              'Bila terdeteksi kelainan retina, surat rujukan digital langsung diterbitkan ke RS rujukan mitra.',
            color: const Color(0xFF246BFD),
            isLast: false,
          ),
          _buildWorkflowStep(
            step: '4',
            title: 'Pendampingan Harian & Pola Hidup',
            description:
              'Jadwal pengingat obat, monitoring gula darah mandiri, rekomendasi gizi 3J, serta tombol SOS darurat.',
            color: const Color(0xFF246BFD),
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
                      Icons.health_and_safety_rounded,
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
        ],
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
                  'Edukasi Pasien Diabetes • PERDAMI',
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
                  'Pedoman Sehat',
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
            '• Skrining fundus mata wajib minimal 1x per tahun untuk deteksi dini komplikasi retina.\n'
            '• Jaga gula darah puasa stabil (80-130 mg/dL) & patuhi jadwal obat harian.\n'
            '• Tekan tombol SOS Darurat merah jika mengalami pandangan kabur mendadak atau melihat bintik hitam.',
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
  Widget _buildCareSyncBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Beranda',
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.medical_services_outlined,
                label: 'Dokter',
                isSelected: _currentNavIndex == 1,
                onTap: () => _onBottomNavTapped(1),
              ),
              _buildNavItem(
                icon: Icons.camera_alt_rounded,
                label: 'Skrining',
                isSelected: _currentNavIndex == 2,
                isPrimary: true,
                onTap: () => _onBottomNavTapped(2),
              ),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'Riwayat',
                isSelected: _currentNavIndex == 3,
                onTap: () => _onBottomNavTapped(3),
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isSelected: _currentNavIndex == 4,
                onTap: () => _onBottomNavTapped(4),
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
    required bool isSelected,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
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

class _CareSyncGridCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareSyncGridCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_CareSyncGridCard> createState() => _CareSyncGridCardState();
}

class _CareSyncGridCardState extends State<_CareSyncGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF246BFD);
    const lightBlueBg = Color(0xFFEFF6FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? primaryBlue.withOpacity(0.4) : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? primaryBlue.withOpacity(0.18) : const Color(0x06000000),
              blurRadius: _isHovered ? 16 : 10,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) => setState(() => _isHovered = hovered),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isHovered ? primaryBlue : lightBlueBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: _isHovered ? Colors.white : primaryBlue,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CareSyncActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareSyncActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_CareSyncActionCard> createState() => _CareSyncActionCardState();
}

class _CareSyncActionCardState extends State<_CareSyncActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF246BFD);
    const lightBlueBg = Color(0xFFEFF6FF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? primaryBlue.withOpacity(0.4) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? primaryBlue.withOpacity(0.18) : const Color(0x06000000),
              blurRadius: _isHovered ? 16 : 8,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) => setState(() => _isHovered = hovered),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isHovered ? primaryBlue : lightBlueBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: _isHovered ? Colors.white : primaryBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
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
                    widget.subtitle,
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
        ),
      ),
    );
  }
}

class _HoverElevationCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverElevationCard({
    required this.child,
    this.onTap,
  });

  @override
  State<_HoverElevationCard> createState() => _HoverElevationCardState();
}

class _HoverElevationCardState extends State<_HoverElevationCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF246BFD);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? primaryBlue.withOpacity(0.35) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? primaryBlue.withOpacity(0.16) : const Color(0x06000000),
              blurRadius: _isHovered ? 16 : 8,
              offset: _isHovered ? const Offset(0, 6) : const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) => setState(() => _isHovered = hovered),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GLOBAL SEARCH ENGINE MODAL
// ============================================================================

class _GlobalSearchItem {
  final String category; // 'Dokter', 'Riwayat', 'Fasilitas', 'Layanan'
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
  final List<String> tags;

  _GlobalSearchItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
    this.tags = const [],
  });
}

class _GlobalSearchSheet extends StatefulWidget {
  final String initialQuery;
  final VoidCallback onNavigateHistory;
  final VoidCallback onNavigateReferral;
  final Function(String) onNavigateDoctors;
  final VoidCallback onNavigateUpload;
  final VoidCallback onNavigateCareCompanion;
  final VoidCallback onNavigateDailyCheckIn;
  final VoidCallback onNavigateMealDetail;
  final VoidCallback onNavigateSos;
  final VoidCallback onNavigateProfile;

  const _GlobalSearchSheet({
    required this.initialQuery,
    required this.onNavigateHistory,
    required this.onNavigateReferral,
    required this.onNavigateDoctors,
    required this.onNavigateUpload,
    required this.onNavigateCareCompanion,
    required this.onNavigateDailyCheckIn,
    required this.onNavigateMealDetail,
    required this.onNavigateSos,
    required this.onNavigateProfile,
  });

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  late TextEditingController _controller;
  String _activeCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_GlobalSearchItem> _getAllItems() {
    return [
      // 1. Dokter Spesialis
      _GlobalSearchItem(
        category: 'Dokter',
        title: 'dr. Hendra Kusuma, Sp.M',
        subtitle: 'Subspesialis Vitreoretina & Makula • RS Mata Dr. Yap',
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: () => widget.onNavigateDoctors('dr. Hendra Kusuma'),
        tags: ['dokter', 'spesialis', 'mata', 'retina', 'vitreoretina', 'yap'],
      ),
      _GlobalSearchItem(
        category: 'Dokter',
        title: 'dr. Yunani Setyandriana, Sp.M',
        subtitle: 'Spesialis Vitreoretina & Oftalmologi • RS Hermina & Dr. Yap',
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: () => widget.onNavigateDoctors('dr. Yunani'),
        tags: ['dokter', 'yunani', 'spm', 'vitreoretina', 'hermina', 'yap'],
      ),
      _GlobalSearchItem(
        category: 'Dokter',
        title: 'dr. Siti Nurhaliza, Sp.M(K)',
        subtitle: 'Konsultan Retina & Diabetes • RSUP Dr. Sardjito',
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: () => widget.onNavigateDoctors('dr. Siti Nurhaliza'),
        tags: ['dokter', 'siti', 'sardjito', 'konsultan', 'retina', 'diabetes'],
      ),
      _GlobalSearchItem(
        category: 'Dokter',
        title: 'dr. Arga Pratama, Sp.M',
        subtitle: 'Spesialis Oftalmologi • RSUD Sleman (Murangan)',
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: () => widget.onNavigateDoctors('dr. Arga Pratama'),
        tags: ['dokter', 'arga', 'rsud', 'sleman', 'oftalmologi'],
      ),

      // 2. Fasilitas Kesehatan & RS Rujukan
      _GlobalSearchItem(
        category: 'Fasilitas',
        title: 'RS Mata Dr. Yap Yogyakarta',
        subtitle: 'RS Khusus Mata Tipe A • Terban, Gondokusuman (BPJS Aktif)',
        icon: Icons.local_hospital_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
        onTap: widget.onNavigateReferral,
        tags: ['faskes', 'rumah sakit', 'rs', 'yap', 'mata', 'rujukan', 'bpjs'],
      ),
      _GlobalSearchItem(
        category: 'Fasilitas',
        title: 'RSUP Dr. Sardjito Yogyakarta',
        subtitle: 'RS Rujukan Nasional Kelas A • Sendowo, Mlati, Sleman',
        icon: Icons.local_hospital_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
        onTap: widget.onNavigateReferral,
        tags: ['faskes', 'rsup', 'sardjito', 'rujukan nasional', 'sleman'],
      ),
      _GlobalSearchItem(
        category: 'Fasilitas',
        title: 'Puskesmas Sleman (FKTP 1)',
        subtitle: 'Puskesmas Rawat Inap & Skrining Retina Diabetes • Jl. Magelang Km 12',
        icon: Icons.domain_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
        onTap: widget.onNavigateReferral,
        tags: ['puskesmas', 'fktp', 'sleman', 'klinik', 'tingkat 1'],
      ),
      _GlobalSearchItem(
        category: 'Fasilitas',
        title: 'RSUD Sleman (RSUD Murangan)',
        subtitle: 'Rumah Sakit Umum Daerah Tipe B • Triharjo, Sleman',
        icon: Icons.local_hospital_rounded,
        iconColor: const Color(0xFF059669),
        iconBg: const Color(0xFFECFDF5),
        onTap: widget.onNavigateReferral,
        tags: ['rsud', 'sleman', 'murangan', 'rumah sakit'],
      ),

      // 3. Riwayat Skrining & SPK
      _GlobalSearchItem(
        category: 'Riwayat',
        title: 'Riwayat Pemeriksaan Retina Pasien',
        subtitle: 'Daftar riwayat foto fundus bilateral OD/OS & telaah dokter',
        icon: Icons.history_edu_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
        onTap: widget.onNavigateHistory,
        tags: ['riwayat', 'skrining', 'pemeriksaan', 'rekam medis', 'foto', 'fundus'],
      ),
      _GlobalSearchItem(
        category: 'Riwayat',
        title: 'Surat Pengantar Rujukan (SPK BPJS)',
        subtitle: 'Dokumen SPK elektronik integrasi SatuSehat & BPJS VClaim',
        icon: Icons.description_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
        onTap: widget.onNavigateReferral,
        tags: ['spk', 'surat', 'pengantar', 'rujukan', 'bpjs', 'vclaim', 'satusehat'],
      ),
      _GlobalSearchItem(
        category: 'Riwayat',
        title: 'Hasil Evaluasi Grad-CAM & Lesi',
        subtitle: 'Heatmap perhatian AI pada mikroaneurisma & eksudat retina',
        icon: Icons.remove_red_eye_rounded,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
        onTap: widget.onNavigateHistory,
        tags: ['grad-cam', 'gradcam', 'heatmap', 'lesi', 'hasil', 'npdr'],
      ),

      // 4. Fitur & Layanan Utama
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Skrining Baru Foto Fundus Bilateral',
        subtitle: 'Ambil atau unggah foto retina mata kanan OD & kiri OS dengan AI',
        icon: Icons.camera_alt_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: widget.onNavigateUpload,
        tags: ['skrining', 'foto', 'kamera', 'ambil', 'upload', 'fundus', 'od', 'os', 'baru'],
      ),
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Retiva Care Companion™',
        subtitle: 'Asisten cerdas pendamping perawatan, kontrol & kalkulator nutrisi',
        icon: Icons.smart_toy_rounded,
        iconColor: const Color(0xFF246BFD),
        iconBg: const Color(0xFFEFF6FF),
        onTap: widget.onNavigateCareCompanion,
        tags: ['care companion', 'pendamping', 'asisten', 'ai', 'nutrisi', 'obat'],
      ),
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Check-in Harian & Jurnal Gula Darah',
        subtitle: 'Pencatatan kadar glukosa darah puasa/sewaktu & tensi mandiri',
        icon: Icons.bloodtype_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBg: const Color(0xFFFEF2F2),
        onTap: widget.onNavigateDailyCheckIn,
        tags: ['gula darah', 'glukosa', 'check-in', 'jurnal', 'tensi', 'darah'],
      ),
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Menu Ramah Kantong (Low-GI)',
        subtitle: 'Kalkulator menu gizi harian ramah diabetes mulai Rp 25.000',
        icon: Icons.restaurant_menu_rounded,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFFFBEB),
        onTap: widget.onNavigateMealDetail,
        tags: ['menu', 'makanan', 'diet', 'nutrisi', 'gizi', 'low-gi', 'kantong'],
      ),
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Aktivasi Darurat Retina (SOS)',
        subtitle: 'Protokol pertolongan cepat jika penglihatan gelap atau kilatan mendadak',
        icon: Icons.emergency_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBg: const Color(0xFFFEF2F2),
        onTap: widget.onNavigateSos,
        tags: ['sos', 'darurat', 'bahaya', 'bantuan', 'kilatan', 'buram mendadak'],
      ),
      _GlobalSearchItem(
        category: 'Layanan',
        title: 'Profil Pasien & Rekam Medis',
        subtitle: 'Lihat data identitas NIK, riwayat medis & akun RETIVA',
        icon: Icons.account_circle_rounded,
        iconColor: const Color(0xFF475569),
        iconBg: const Color(0xFFF1F5F9),
        onTap: widget.onNavigateProfile,
        tags: ['profil', 'akun', 'nik', 'pasien', 'data', 'pengaturan'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final allItems = _getAllItems();

    final filtered = allItems.where((item) {
      if (_activeCategory != 'Semua' && item.category != _activeCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final matchTitle = item.title.toLowerCase().contains(query);
      final matchSubtitle = item.subtitle.toLowerCase().contains(query);
      final matchCategory = item.category.toLowerCase().contains(query);
      final matchTags = item.tags.any((t) => t.toLowerCase().contains(query));
      return matchTitle || matchSubtitle || matchCategory || matchTags;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Cari dokter, riwayat, RS, gula darah, rujukan...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF246BFD), size: 22),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                'Semua',
                'Dokter',
                'Fasilitas',
                'Riwayat',
                'Layanan',
              ].map((cat) {
                final isSelected = _activeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat == 'Semua'
                          ? 'Semua (${allItems.length})'
                          : cat == 'Dokter'
                              ? '👨‍⚕️ Dokter Spesialis'
                              : cat == 'Fasilitas'
                                  ? '🏥 Rumah Sakit & FKTP'
                                  : cat == 'Riwayat'
                                      ? '📋 Riwayat & SPK'
                                      : '⚡ Layanan & Fitur',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: const Color(0xFF246BFD),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (_) => setState(() => _activeCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Results List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: Color(0xFF246BFD),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tidak ada hasil untuk "${_controller.text}"',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Coba cari dengan kata kunci lain seperti "Dr. Yap", "Hendra", "Puskesmas", "Gula Darah", "Skrining", atau "SPK".',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return Material(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: item.onTap,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: item.iconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(item.icon, color: item.iconColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.iconBg,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: item.iconColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}