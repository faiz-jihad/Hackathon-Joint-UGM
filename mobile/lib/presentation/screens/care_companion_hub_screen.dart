import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/widget_service.dart';
import '../../data/models/daily_agenda_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/models/screening_result_model.dart';

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              color: isEmergency ? AppColors.statusRed : AppColors.statusGreen,
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
                      backgroundColor: AppColors.statusGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.figmaBlue, foregroundColor: Colors.white),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.statusRed),
            tooltip: 'Cek Gejala Darurat',
            onPressed: _showUrgentSymptomDialog,
          ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _companionState?['currentState'] != null
                      ? 'RETIVA CARE • ${_companionState!["currentState"]}'
                      : 'RETIVA CARE COMPANION',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
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
                  const Text(
                    'Fasilitas Rujukan Mata Terdekat',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _onlyBpjs,
                        activeColor: AppColors.figmaBlue,
                        onChanged: (v) => setState(() => _onlyBpjs = v ?? false),
                      ),
                      const Text('BPJS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.statusGreenSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BPJS Aktif',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.statusGreenDark),
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
      onTap: () {
        setState(() => _copiedQuestionIdx = idx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pertanyaan tersalin ke clipboard!'), duration: Duration(seconds: 1)),
        );
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.figmaBlue, foregroundColor: Colors.white),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu Ramah Kantong (Low-GI)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                  ),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusGreenDark)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengingat Obat & Kontrol Dokter',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.figmaTextHeading),
                  ),
                  InkWell(
                    onTap: _showAddReminderDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.figmaBlueSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
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
                    activeColor: AppColors.statusGreen,
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
            activeColor: AppColors.statusGreen,
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
}
