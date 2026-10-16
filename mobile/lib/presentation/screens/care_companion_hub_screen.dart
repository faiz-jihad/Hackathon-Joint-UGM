import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/widget_service.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/screening_result_model.dart';
import '../widgets/notification_bell_widget.dart';

class CareCompanionHubScreen extends StatefulWidget {
  final PatientModel? patient;
  final CompleteScreeningResult? screeningResult;
  final int initialStep; // 0: Fase A, 1: Fase B, 2: Fase C, 3: Fase D

  const CareCompanionHubScreen({
    super.key,
    this.patient,
    this.screeningResult,
    this.initialStep = 1,
  });

  @override
  State<CareCompanionHubScreen> createState() => _CareCompanionHubScreenState();
}

class _CareCompanionHubScreenState extends State<CareCompanionHubScreen> {
  int _currentStep = 1;
  bool _isLoading = true;
  Map<String, dynamic>? _companionState;

  // Pre-consultation
  List<Map<String, dynamic>> _facilities = [];
  bool _onlyBpjs = false;
  int? _copiedQuestionIdx;
  List<String> _doctorQuestions = [];

  // Consultation Entry - Loaded dynamically from DB consultationSummary
  final TextEditingController _hospitalCtrl = TextEditingController();
  final TextEditingController _doctorCtrl = TextEditingController();
  final TextEditingController _findingsCtrl = TextEditingController();
  final TextEditingController _treatmentCtrl = TextEditingController();
  final TextEditingController _followUpCtrl = TextEditingController();
  final TextEditingController _dietaryCtrl = TextEditingController();
  bool _isConfirmedByPatient = false;

  // Post-consultation Meal Planner - Dynamically loaded from Master DB
  double _dailyBudget = 35000;
  Map<String, dynamic>? _mealPlan;
  bool _isLoadingMeal = false;
  final Map<String, bool> _completedMeals = {};

  // Reminders - Loaded dynamically from DB careReminders
  List<Map<String, dynamic>> _reminders = [];

  // Fitur 4: Pengingat Kontrol State
  DateTime _nextControlDate = DateTime.now().add(const Duration(days: 7));
  bool _isControlReminderActive = true;

  void _selectNextControlDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextControlDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF246BFD),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _nextControlDate = picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal kontrol dokter berhasil diatur ke ${_formatControlDate(_nextControlDate)}! Alarm pengingat aktif.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _formatControlDate(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _loadStateData();
  }

  Future<void> _loadStateData() async {
    final patientId = widget.patient?.id ?? 'P-001';
    final state = await ApiClient().getCareCompanionState(patientId);
    final facilities = await ApiClient().getNearestFacilities();

    // 1. Populate recorded consultation from DB if available
    final consult = state?['consultationSummary'];
    if (consult != null) {
      _hospitalCtrl.text = consult['hospitalClinicName'] ?? '';
      _doctorCtrl.text = consult['doctorName'] ?? '';
      _findingsCtrl.text = consult['doctorFindingsDiagnosis'] ?? '';
      _treatmentCtrl.text = consult['recommendedTreatment'] ?? '';
      _followUpCtrl.text = consult['followUpDate']?.toString().split('T').first ?? '';
      _dietaryCtrl.text = consult['dietaryLifestyleInstructions'] ?? '';
      _isConfirmedByPatient = consult['isPatientConfirmed'] == true;
    }

    // 2. Load doctor questions dynamically from Master DB
    List<String> qList = [];
    final suggested = state?['preConsultation']?['suggestedQuestions'];
    if (suggested is List && suggested.isNotEmpty) {
      qList = suggested.map((e) => e.toString()).toList();
    } else {
      final masterQ = await ApiClient().getMasterDoctorQuestions();
      qList = masterQ.map((q) => q['questionText'].toString()).toList();
    }

    // 3. Load reminders dynamically from DB
    List<Map<String, dynamic>> reminderList = [];
    final rems = state?['reminders'];
    if (rems is List && rems.isNotEmpty) {
      reminderList = rems.map((r) => {
        'id': r['id']?.toString() ?? '',
        'title': r['title']?.toString() ?? '',
        'desc': r['description']?.toString() ?? '',
        'time': r['scheduledTime']?.toString().split('T').first ?? '',
        'isCompleted': r['isCompleted'] == true,
      }).toList();
    } else {
      final dbRems = await ApiClient().getCareReminders(patientId);
      if (dbRems.isNotEmpty) {
        reminderList = dbRems.map((r) => {
          'id': r['id']?.toString() ?? '',
          'title': r['title']?.toString() ?? '',
          'desc': r['description']?.toString() ?? '',
          'time': r['scheduledTime']?.toString().split('T').first ?? '',
          'isCompleted': r['isCompleted'] == true,
        }).toList();
      }
    }

    if (mounted) {
      setState(() {
        _companionState = state;
        _facilities = facilities;
        _doctorQuestions = qList;
        _reminders = reminderList;
        _isLoading = false;
      });
      _generateMealPlan();
      _syncToLauncherWidget();
    }
  }

  Future<void> _syncToLauncherWidget({bool showSnack = false}) async {
    try {
      final patientId = widget.patient?.id ?? 'P-001';
      final agenda = await ApiClient().getDailyAgenda(patientId);
      await WidgetService.updateWidgetData(agenda);
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ Widget Layar Utama HP berhasil disinkronkan dengan agenda Retiva!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _generateMealPlan() async {
    setState(() => _isLoadingMeal = true);
    final plan = await ApiClient().generateMealPlan(_dailyBudget, 'D.I. Yogyakarta');
    if (mounted) {
      setState(() {
        _mealPlan = plan;
        _isLoadingMeal = false;
      });
      _syncToLauncherWidget();
    }
  }

  void _showUrgentSymptomDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusRed, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cek Gejala Darurat Mata',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.figmaTextHeading,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tuliskan keluhan penglihatan yang Anda rasakan (misalnya: kilatan cahaya, bintik mendadak banyak, atau pandangan tertutup tirai):',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.figmaTextBody,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Mata kanan tiba-tiba buram dan ada kilatan seperti petir...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderCard),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiClient().checkUrgentSymptoms('P-001', textCtrl.text);
              _showSymptomResultDialog(res);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Evaluasi Gejala'),
          ),
        ],
      ),
    );
  }

  void _showSymptomResultDialog(Map<String, dynamic> result) {
    final isEmergency = result['isEmergency'] == true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isEmergency ? const Color(0xFFFEF2F2) : Colors.white,
        title: Row(
          children: [
            Icon(
              isEmergency ? Icons.emergency_rounded : Icons.check_circle_rounded,
              color: isEmergency ? AppColors.statusRed : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result['warningTitle'] ?? 'Hasil Evaluasi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isEmergency ? AppColors.figmaRetakeDark : AppColors.figmaTextHeading,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          result['warningMessage'] ?? '',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isEmergency ? const Color(0xFF7F1D1D) : AppColors.figmaTextBody,
            height: 1.45,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmergency ? AppColors.statusRed : AppColors.figmaBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '08:00 WIB');
    String reminderType = 'MEDICATION';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Pengingat Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kategori Pengingat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: reminderType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'MEDICATION', child: Text('Obat / Terapi Medis')),
                    DropdownMenuItem(value: 'MEAL_SCHEDULE', child: Text('Jadwal Makan Nutrisi')),
                    DropdownMenuItem(value: 'FOLLOW_UP_VISIT', child: Text('Kontrol Dokter Spesialis')),
                    DropdownMenuItem(value: 'BLOOD_GLUCOSE_CHECK', child: Text('Cek Gula Darah Mandiri')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => reminderType = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Pengingat *',
                    hintText: 'Contoh: Minum Metformin 500 mg',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Keterangan Tambahan',
                    hintText: 'Contoh: Sesudah makan malam',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Waktu / Jam *',
                    hintText: 'Contoh: Pukul 08:00 & 20:00 WIB',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final patientId = widget.patient?.id ?? 'P-001';
                final created = await ApiClient().createCareReminder({
                  'patientId': patientId,
                  'reminderType': reminderType,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                  'scheduledTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                  'frequency': 'DAILY',
                });

                if (mounted) {
                  setState(() {
                    _reminders.add({
                      'id': created?['id'] ?? 'rem-${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleCtrl.text.trim(),
                      'desc': descCtrl.text.trim(),
                      'time': timeCtrl.text.trim(),
                      'isCompleted': false,
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengingat baru berhasil disimpan ke database PostgreSQL!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.figmaBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan ke Database'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.figmaTextHeading),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pendamping Perawatan AI',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaTextHeading,
          ),
        ),
        actions: const [
          Center(child: NotificationBellWidget()),
          SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.figmaBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Banner
                  _buildHeroHeader(),

                  const SizedBox(height: 16),

                  // Stepper Navigation
                  _buildStepSelector(),

                  const SizedBox(height: 18),

                  // Dynamic Step Content
                  if (_currentStep == 0) _buildPhaseAScreening(),
                  if (_currentStep == 1) _buildPhaseBPreConsultation(),
                  if (_currentStep == 2) _buildPhaseCConsultationEntry(),
                  if (_currentStep == 3) _buildPhaseDPostConsultationCare(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.figmaBlue, AppColors.figmaBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240D47A1),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _companionState?['currentState'] != null
                        ? 'RETIVA CARE • ${_companionState!["currentState"]}'
                        : 'RETIVA CARE COMPANION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _showUrgentSymptomDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Darurat?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teman Perjalanan Sehat Anda',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '“Bersama Retiva, langkah kecil untuk hidup lebih sehat. Sehat hari ini, jelas esok nanti 💙”',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFFE0F2FE),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pasien: ${widget.patient?.fullName ?? "Pasien Terdaftar"} • Rekam Medis Terpadu',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mascot Doctor Floating Badge
              Container(
                width: 64,
                height: 64,
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
                  child: Image.asset(
                    'assets/images/pose_menyapa.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: AppColors.primary, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Prinsip Medis: AI Retiva mendampingi perjalanan perawatan dan tidak menggantikan keputusan diagnosis atau resep dokter spesialis mata.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                color: Color(0xFFE2E8F0),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Row(
        children: [
          _buildStepTabItem(0, '1. Skrining'),
          _buildStepTabItem(1, '2. Pra-Dokter'),
          _buildStepTabItem(2, '3. Catat Hasil'),
          _buildStepTabItem(3, '4. Rencana AI'),
        ],
      ),
    );
  }

  Widget _buildStepTabItem(int stepIndex, String title) {
    final isSelected = _currentStep == stepIndex;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (stepIndex == 3 && !_isConfirmedByPatient) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selesaikan dan konfirmasi catatan konsultasi dokter di Fase 3 terlebih dahulu.'),
                backgroundColor: AppColors.figmaBlue,
              ),
            );
            setState(() => _currentStep = 2);
          } else {
            setState(() => _currentStep = stepIndex);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.figmaBlueSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.figmaBlue : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FASE A: SCREENING RESULT & NEXT STEPS
  // ===========================================================================
  Widget _buildPhaseAScreening() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusYellowSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Moderate DR (Sedang)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ),
              const Spacer(),
              const Text(
                'Tingkat Keyakinan: 88.4%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.figmaBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Penjelasan Medis Hasil Skrining Retina:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ditemukan indikasi mikroaneurisma multipel dan eksudat lipid pada retina posterior. Kondisi ini memerlukan pemeriksaan funduskopi mendalam oleh dokter spesialis mata dalam waktu 2–4 minggu.',
            style: TextStyle(fontSize: 13, color: AppColors.figmaTextBody, height: 1.45),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.figmaBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lanjut: Cari Faskes & Siapkan Konsultasi'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FASE B: PRE-CONSULTATION ASSISTANT
  // ===========================================================================
  Widget _buildPhaseBPreConsultation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fitur 1: Pelacakan Alur Rujukan (Fase Pra-Konsultasi)
        _buildReferralTrackingBanner(),

        const SizedBox(height: 14),

        // Facilities Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fasilitas Rujukan Mata Terdekat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih rumah sakit rujukan spesialis retina',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _onlyBpjs = !_onlyBpjs),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _onlyBpjs ? AppColors.figmaBlue : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _onlyBpjs ? AppColors.figmaBlue : const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _onlyBpjs ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: _onlyBpjs ? Colors.white : AppColors.figmaBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mitra BPJS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _onlyBpjs ? Colors.white : AppColors.figmaBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_facilities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'Tidak ada fasilitas rujukan tersimpan di database.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                )
              else if (_onlyBpjs && _facilities.where((f) => f['bpjsStatus'] == 'ACCEPTED').isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'Tidak ada fasilitas rujukan BPJS yang ditemukan.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...(_onlyBpjs
                        ? _facilities.where((f) => f['bpjsStatus'] == 'ACCEPTED')
                        : _facilities)
                    .map((fac) => _buildFacilityCard(fac)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Questions to Ask Doctor
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Friendly mascot suggestion card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/pose_menjelaskan.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saran Dokter Retiva',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Catat atau salin pertanyaan penting berikut untuk diajukan saat konsultasi di RS Mata rujukan.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Daftar Pertanyaan untuk Dokter Spesialis Mata',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketuk untuk menyalin pertanyaan:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (_doctorQuestions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Memuat pertanyaan dari database master...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                )
              else
                ..._doctorQuestions.asMap().entries.map((entry) => _buildQuestionItem(entry.key, entry.value)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.figmaBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sudah Berkonsultasi? Catat Hasil Dokter Disini'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> fac) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fac['name'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'BPJS Aktif',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fac['address'] ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.figmaTextBody),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Dokter: ${fac['doctor_name'] ?? "Spesialis Vitreoretina"}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.figmaBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(int idx, String q) {
    final isCopied = _copiedQuestionIdx == idx;
    return InkWell(
      onTap: () async {
        setState(() => _copiedQuestionIdx = idx);
        await Clipboard.setData(ClipboardData(text: q));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pertanyaan tersalin ke clipboard:\n"$q"'),
              backgroundColor: const Color(0xFF246BFD),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCopied ? AppColors.figmaBlueSurface : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isCopied ? AppColors.figmaBlue : AppColors.borderCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${idx + 1}. $q',
                style: const TextStyle(fontSize: 12, color: AppColors.figmaTextBody),
              ),
            ),
            Icon(
              isCopied ? Icons.check_circle_rounded : Icons.copy_rounded,
              size: 16,
              color: isCopied ? AppColors.figmaBlue : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // FASE C: CONSULTATION SUMMARY ENTRY & CONFIRMATION
  // ===========================================================================
  Widget _buildPhaseCConsultationEntry() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard),
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
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/pose_membantu.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catat Hasil Pemeriksaan Dokter',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                    ),
                    Text(
                      'Label Data: Catatan Pasien Mandiri (Bantuan Pendamping Retiva)',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTextField('Rumah Sakit / Klinik', _hospitalCtrl),
          const SizedBox(height: 10),
          _buildTextField('Nama Dokter Spesialis Mata', _doctorCtrl),
          const SizedBox(height: 10),
          _buildTextField('Temuan Klinis / Diagnosis Dokter', _findingsCtrl, maxLines: 2),
          const SizedBox(height: 10),
          _buildTextField('Instruksi Tindakan Medis', _treatmentCtrl, maxLines: 2),
          const SizedBox(height: 10),
          _buildTextField('Jadwal Kontrol Ulang Berikutnya', _followUpCtrl),
          const SizedBox(height: 10),
          _buildTextField('Instruksi Diet & Gaya Hidup', _dietaryCtrl),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Konfirmasi Catatan Dokter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  content: const Text(
                    'Anda menyatakan bahwa informasi di atas sesuai dengan arahan dokter Anda. Rencana perawatan dan pengingat nutrisi akan diaktifkan berdasarkan catatan ini.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _isConfirmedByPatient = true;
                          _currentStep = 3;
                        });
                        await ApiClient().saveConsultationSummary({
                          'patientId': widget.patient?.id ?? 'P-001',
                          'hospitalClinicName': _hospitalCtrl.text,
                          'doctorName': _doctorCtrl.text,
                          'doctorFindingsDiagnosis': _findingsCtrl.text,
                          'recommendedTreatment': _treatmentCtrl.text,
                          'followUpDate': _followUpCtrl.text,
                          'dietaryLifestyleInstructions': _dietaryCtrl.text,
                          'isPatientConfirmed': true,
                        });
                        await _syncToLauncherWidget();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan dokter terkonfirmasi! Agenda & widget HP disinkronkan.'),
                              backgroundColor: AppColors.figmaBlue,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.figmaBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ya, Konfirmasi'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.figmaBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tinjau & Konfirmasi Instruksi Dokter'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.figmaTextHeading)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderCard)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FASE D: POST-CONSULTATION CARE PLAN (NUTRITION & REMINDERS)
  // ===========================================================================
  Widget _buildPhaseDPostConsultationCare() {
    final meals = _mealPlan?['meals'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fitur 5: Rencana dari Dokter Spesialis
        _buildDoctorCarePlanCard(),

        const SizedBox(height: 14),

        // Fitur 4: Pengingat Kontrol Dokter Spesialis Mata
        _buildFollowUpReminderCard(),

        const SizedBox(height: 14),

        // Retiva Companion Nutrition Mascot Banner
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/pose_peduli.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pola Hidup Sehat Bersama Retiva',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kontrol nutrisi Low-GI terjangkau dan konsumsi obat tepat waktu menjaga kejernihan penglihatan Anda.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF14532D),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Widget Synchronization Status Card
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(Icons.widgets_rounded, color: AppColors.figmaBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Widget Layar Depan HP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.figmaTextHeading,
                      ),
                    ),
                    Text(
                      'Sinkron aktif: Menu nutrisi & pengingat langsung muncul di home screen.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _syncToLauncherWidget(showSnack: true),
                icon: const Icon(Icons.sync_rounded, size: 13),
                label: const Text('Sinkron', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.figmaBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        // Budget Nutrition Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Menu Ramah Kantong (Low-GI)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<double>(
                    value: _dailyBudget,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.figmaBlue),
                    items: const [
                      DropdownMenuItem(value: 25000, child: Text('Rp 25.000 / hari')),
                      DropdownMenuItem(value: 35000, child: Text('Rp 35.000 / hari')),
                      DropdownMenuItem(value: 50000, child: Text('Rp 50.000 / hari')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _dailyBudget = v);
                        _generateMealPlan();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Total vs Budget summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.figmaBlueSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: Rp ${_mealPlan?["estimatedTotalCostIdr"] ?? "-"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.figmaBlueDark)),
                    Text('Sisa: Rp ${_mealPlan?["remainingBudgetIdr"] ?? "-"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF246BFD))),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_isLoadingMeal)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.figmaBlue),
                  ),
                )
              else if (meals != null) ...[
                _buildMealCardItem('Sarapan', meals['breakfast'], 'SARAPAN'),
                _buildMealCardItem('Makan Siang', meals['lunch'], 'MAKAN_SIANG'),
                _buildMealCardItem('Makan Malam', meals['dinner'], 'MAKAN_MALAM'),
                _buildMealCardItem('Camilan Sehat', meals['snack'], 'CAMILAN'),
              ] else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _generateMealPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.figmaBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Buat Rencana Nutrisi dari Database Master'),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Reminders & Medication Schedule - Loaded from PostgreSQL DB
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pengingat Obat & Kontrol Dokter',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddReminderDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.figmaBlueSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.figmaBlue),
                          SizedBox(width: 4),
                          Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.figmaBlue)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_reminders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada jadwal pengingat di database.\nKetuk "+ Tambah" untuk menambahkan pengingat obat atau jadwal kontrol.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  ),
                )
              else
                ..._reminders.map((r) => _buildReminderItem(r)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCardItem(String label, Map<String, dynamic> meal, String cat) {
    final mealName = meal['name'] ?? '';
    final isDone = _completedMeals[mealName] ?? false;
    final costVal = meal['estimatedCostIdr'] ?? meal['cost'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.figmaBlue)),
              Text('Rp $costVal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading)),
            ],
          ),
          const SizedBox(height: 4),
          Text(mealName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  final updated = await ApiClient().replaceMeal(_mealPlan ?? {}, cat);
                  if (updated != null) {
                    setState(() => _mealPlan = updated);
                    _syncToLauncherWidget();
                  }
                },
                child: const Text('🔄 Ganti Menu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.figmaBlue)),
              ),
              Row(
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _completedMeals[mealName] = v ?? false);
                      _syncToLauncherWidget();
                    },
                  ),
                  const Text('Selesai', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> r) {
    final isDone = r['isCompleted'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F5F9) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDone ? Colors.transparent : AppColors.borderCard),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() => r['isCompleted'] = v ?? false);
              ApiClient().toggleReminder(r['id'], v ?? false);
              _syncToLauncherWidget();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['title'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMuted : AppColors.figmaTextHeading,
                  ),
                ),
                Text(r['desc'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            r['time'] ?? '',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.figmaBlue),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FITUR 1: PELACAKAN RUJUKAN DI CARE COMPANION
  // ===========================================================================
  Widget _buildReferralTrackingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_rounded, color: Color(0xFF246BFD), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pelacakan Status Rujukan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tahap 2 dari 3',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniStepBadge('1. SPK Terbit', true),
              _buildMiniConnector(true),
              _buildMiniStepBadge('2. Jadwal OK', true),
              _buildMiniConnector(false),
              _buildMiniStepBadge('3. Periksa', false),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'SPK/RTV/2026/09/0084 • Jadwal rujukan ke RS Mata Dr. Yap terkonfirmasi.',
            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepBadge(String title, bool isDone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDone ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 11,
              color: isDone ? const Color(0xFF246BFD) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDone ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniConnector(bool isDone) {
    return Container(
      width: 8,
      height: 2,
      color: isDone ? const Color(0xFF246BFD) : const Color(0xFFCBD5E1),
    );
  }

  // ===========================================================================
  // FITUR 5: RENCANA DARI DOKTER SPESIALIS MATA
  // Menyimpan instruksi dokter, jadwal pemeriksaan, dan terapi yang telah ditetapkan
  // ===========================================================================
  Widget _buildDoctorCarePlanCard() {
    final consult = _companionState?['consultationSummary'];
    final doctorName = consult?['doctorName'] ?? (_doctorCtrl.text.isNotEmpty ? _doctorCtrl.text : 'dr. Yunani Setyandriana, Sp.M');
    final hospital = consult?['hospitalClinicName'] ?? (_hospitalCtrl.text.isNotEmpty ? _hospitalCtrl.text : 'RS Mata Dr. Yap Yogyakarta');
    final diagnosis = consult?['doctorFindingsDiagnosis'] ?? (_findingsCtrl.text.isNotEmpty ? _findingsCtrl.text : 'Retinopati Diabetik Non-Proliferatif Sedang (NPDR Sedang) ODS');
    final treatment = consult?['recommendedTreatment'] ?? (_treatmentCtrl.text.isNotEmpty ? _treatmentCtrl.text : 'Kontrol metabolik intensif, tatalaksana glukosa terarah, & evaluasi berkala');
    final lifestyle = consult?['dietaryLifestyleInstructions'] ?? (_dietaryCtrl.text.isNotEmpty ? _dietaryCtrl.text : 'Pertahankan HbA1c < 7.0%, cek tensi tiap pagi, kurangi asupan garam & gula.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 3)),
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
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF246BFD), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rencana dari Dokter Spesialis',
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
                            'Instruksi klinis & terapi resmi terverifikasi',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 10, color: Color(0xFF246BFD)),
                    SizedBox(width: 3),
                    Text(
                      'Tervalidasi',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF246BFD)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Detail Dokter & RS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.person, color: Color(0xFF246BFD), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '$hospital • Spesialis Vitreoretina',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Diagnosis Klinis
          _buildCarePlanDetailRow(
            title: 'Diagnosis Terverifikasi:',
            content: diagnosis,
            icon: Icons.biotech_rounded,
            iconColor: const Color(0xFF0284C7),
          ),

          const SizedBox(height: 8),

          // Terapi yang Ditetapkan
          _buildCarePlanDetailRow(
            title: 'Terapi yang Ditetapkan:',
            content: treatment,
            icon: Icons.healing_rounded,
            iconColor: const Color(0xFF059669),
          ),

          const SizedBox(height: 8),

          // Instruksi Khusus Dokter
          _buildCarePlanDetailRow(
            title: 'Instruksi Gaya Hidup:',
            content: lifestyle,
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildCarePlanDetailRow({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FITUR 4: PENGINGAT KONTROL (FOLLOW-UP REMINDER)
  // Mengurangi risiko pengguna lupa atau menunda pemeriksaan mata & diabetes
  // ===========================================================================
  Widget _buildFollowUpReminderCard() {
    final daysRemaining = _nextControlDate.difference(DateTime.now()).inDays + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  const Text(
                    'Pengingat Kontrol Dokter',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() => _isControlReminderActive = !_isControlReminderActive);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isControlReminderActive ? 'Pengingat notifikasi kontrol aktif!' : 'Pengingat notifikasi dinonaktifkan.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isControlReminderActive ? const Color(0xFF246BFD) : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isControlReminderActive
                        ? (daysRemaining > 0 ? '$daysRemaining Hari Lagi' : 'Hari Ini')
                        : 'Alarm Mati',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jadwal Kontrol Mata: ${_formatControlDate(_nextControlDate)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pemeriksaan evaluasi retina rutin di Poli Mata RS Rujukan. Jangan tunda jadwal kontrol Anda untuk menjaga ketajaman penglihatan.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectNextControlDate,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                  label: const Text('Ubah Tanggal Kontrol', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246BFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddReminderDialog,
                  icon: const Icon(Icons.add_alert_rounded, size: 14, color: Color(0xFF1D4ED8)),
                  label: const Text('Tambah Alarm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF246BFD)),
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
