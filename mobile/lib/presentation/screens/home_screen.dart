import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
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
import 'auth_screen.dart';
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

  PatientModel? get _activePatient => _patients.isNotEmpty ? _patients.first : null;

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
      final activeId = patients.isNotEmpty ? patients.first.id : 'P-001';
      await _syncWidgetWithBackend(activeId);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
  void _navigateToUpload() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => UploadFundusScreen(
        initialPatient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToHistory() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const PatientHistoryScreen()));

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
    final activeId = _patients.isNotEmpty ? _patients.first.id : 'P-001';
    _syncWidgetWithBackend(activeId);
  }

  void _navigateToReferral() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ReferralLetterScreen(
        patient: _patients.isNotEmpty ? _patients.first : null)));

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

  void _navigateToProfile() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ProfileScreen(
        patient: _patients.isNotEmpty ? _patients.first : null)));

  void _navigateToTopDoctors() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const TopDoctorsScreen()));

  void _navigateToSos() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SosActivationScreen(
                patientId: _patients.isNotEmpty ? _patients.first.id : null,
                patientName: _patients.isNotEmpty ? _patients.first.fullName : null,
                patientNik: _patients.isNotEmpty ? _patients.first.nik : null,
                patientPhone: _patients.isNotEmpty ? _patients.first.phone : null,
              )));

  void _onBottomNavTapped(int index) {
    setState(() => _currentNavIndex = index);
    if (index == 1) {
      _navigateToTopDoctors();
    } else if (index == 2) {
      _navigateToUpload();
    } else if (index == 3) {
      _navigateToHistory();
    } else if (index == 4) {
      _navigateToProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _activePatient?.fullName.isNotEmpty == true
        ? _activePatient!.fullName
        : 'Rohit';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // === CareSync TOP BAR ===
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

                    // === TOP DOCTORS (CareSync Section) ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildTopDoctorsSection(),
                      ),
                    ),

                    // === RETIVA SOS EMERGENCY CARD ===
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _buildSosEmergencyCard(),
                      ),
                    ),

                    // Bottom padding for bottom navigation
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
            size: 30,
            showText: true,
            text: 'CareSync',
            subtitle: 'Retina & Diabetes Hub',
          ),
          Row(
            children: [
              // Server online status pill
              _buildOnlineStatusBadge(),
              const SizedBox(width: 8),

              // Notification bell button
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak ada notifikasi baru hari ini.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 2. CareSync SEARCH BAR ============
  Widget _buildCareSyncSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for doctors, screenings, clinics...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                label: 'Care Companion 🤖',
                icon: Icons.psychology_rounded,
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
                          Row(
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
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                                    SizedBox(width: 4),
                                    Text(
                                      'Widget Sinkron',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34D399),
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
                      Row(
                        children: [
                          const Icon(Icons.widgets_rounded, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Agenda & menu sinkron ke Launcher Widget',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                      Row(
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
              child: _buildCareSyncGridCard(
                icon: Icons.person_search_rounded,
                iconColor: const Color(0xFF246BFD),
                iconBg: const Color(0xFFEFF6FF),
                title: 'My doctor',
                subtitle: 'Konsultasi Sp.M',
                onTap: _navigateToTopDoctors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCareSyncGridCard(
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF00C566),
                iconBg: const Color(0xFFE8F8F0),
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
              child: _buildCareSyncGridCard(
                icon: Icons.local_hospital_outlined,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
                title: 'Find Clinic',
                subtitle: 'Faskes BPJS & Rujukan',
                onTap: _navigateToReferral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCareSyncGridCard(
                icon: Icons.event_available_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFFFBEB),
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

  Widget _buildCareSyncGridCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
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
                  subtitle,
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
              subtitle: 'Cek kondisi fisik & gejala mata (30 detik)',
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
            Row(
              children: [
                const Text(
                  'Widget Layar Utama HP',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: const Text(
                    'Luar Aplikasi',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() => _previewLargeWidget = !_previewLargeWidget),
              child: Text(
                _previewLargeWidget ? 'Beralih Ringkas (2x2)' : 'Beralih Lengkap (4x3)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 16),
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
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          progressText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00C566),
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
                  color: item.isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.time,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: item.isCompleted ? const Color(0xFF00C566) : AppColors.primary,
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
                color: item.isCompleted ? const Color(0xFF00C566) : const Color(0xFF94A3B8),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Overview',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
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
                    color: AppColors.primary,
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
                  iconColor: const Color(0xFF00C566),
                  label: 'Gula Darah',
                  value: '90 mg/dL',
                  status: 'Normal Puasa',
                  onTap: _navigateToDailyCheckIn,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildVitalItem(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFF246BFD),
                  label: 'Tekanan Darah',
                  value: '120/80',
                  status: 'Terkontrol',
                  onTap: _navigateToDailyCheckIn,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildVitalItem(
                  icon: Icons.remove_red_eye_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Status Retina',
                  value: 'No DR',
                  status: 'Aman 1 Tahun',
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
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

  // ============ 8. TOP DOCTORS (CareSync Section) ============
  Widget _buildTopDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Doctors',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            GestureDetector(
              onTap: _navigateToTopDoctors,
              child: const Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Doctor Card 1
        _buildDoctorMiniCard(
          name: 'dr. Amanda Sp.M (K)',
          specialty: 'Spesialis Vitreoretina',
          rating: '4.9',
          hospital: 'RSUP Dr. Sardjito',
          onAppointment: _navigateToTopDoctors,
        ),
        const SizedBox(height: 10),

        // Doctor Card 2
        _buildDoctorMiniCard(
          name: 'dr. Aditya Wijaya Sp.M',
          specialty: 'Spesialis Retinopati Diabetik',
          rating: '4.8',
          hospital: 'RS Mata Dr. Yap',
          onAppointment: _navigateToTopDoctors,
        ),
      ],
    );
  }

  Widget _buildDoctorMiniCard({
    required String name,
    required String specialty,
    required String rating,
    required String hospital,
    required VoidCallback onAppointment,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6E4FF)),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$specialty • $hospital',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Appointment',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retiva SOS Darurat Mata & Diabetes',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
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

  Widget _buildOnlineStatusBadge() {
    final isOnline = ApiConstants.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
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
              color: isOnline ? const Color(0xFF00C566) : const Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isOnline ? const Color(0xFF065F46) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  // ============ 10. CareSync BOTTOM NAV ============
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
                label: 'Home',
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _buildNavItem(
                icon: Icons.medical_services_outlined,
                label: 'Doctors',
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
                label: 'Reports',
                isSelected: _currentNavIndex == 3,
                onTap: () => _onBottomNavTapped(3),
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
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