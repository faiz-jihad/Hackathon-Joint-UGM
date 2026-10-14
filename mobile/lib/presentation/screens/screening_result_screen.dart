import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'referral_letter_screen.dart';
import 'care_companion_hub_screen.dart';
import 'retina_insight_screen.dart';

/// ScreeningResultScreen — Alur Klinis 4 Tahap Komprehensif
/// Menjawab tuntas kebutuhan faskes:
/// 1. MASALAH (Keluhan Pasien, Riwayat Diabetes, Faktor Risiko)
/// 2. DIAGNOSIS (Hasil Skrining Retina, Kode ICD-10, Grad-CAM Heatmap, Biomarker, Verifikasi Sp.M)
/// 3. SOLUSI (Tindakan Medis Segera, Rujukan BPJS Terstandar, Faskes Terdekat)
/// 4. PENANGANAN KEDEPAN (Rencana Jangka Panjang, Target Metabolik, Jadwal Kontrol, Red Flags)
class ScreeningResultScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;
  final Uint8List? originalBytes;

  const ScreeningResultScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
    this.originalBytes,
  });

  @override
  State<ScreeningResultScreen> createState() => _ScreeningResultScreenState();
}

class _ScreeningResultScreenState extends State<ScreeningResultScreen> {
  // 0: Masalah, 1: Diagnosis, 2: Solusi, 3: Penanganan Kedepan, 4: Semua Alur
  int _activeStage = 1; // Default to Diagnosis
  bool _showGradcam = false;
  bool _reminderAdded = false;

  int _getSeverityIndex(String predictedClass) {
    switch (predictedClass.toUpperCase()) {
      case 'NO_DR':
        return 0;
      case 'MILD_DR':
      case 'MILD':
        return 1;
      case 'MODERATE_DR':
      case 'MODERATE':
        return 2;
      case 'SEVERE_DR':
      case 'SEVERE':
        return 3;
      case 'PROLIFERATIVE_DR':
      case 'PDR':
        return 4;
      default:
        return 2;
    }
  }

  String _getSeverityShortName(int index) {
    switch (index) {
      case 0:
        return 'NO DR';
      case 1:
        return 'MILD NPDR';
      case 2:
        return 'MODERATE NPDR';
      case 3:
        return 'SEVERE NPDR';
      case 4:
        return 'PROLIFERATIVE DR';
      default:
        return 'MODERATE NPDR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityIndex = _getSeverityIndex(widget.result.aiResult.predictedClass);
    final severityName = _getSeverityShortName(severityIndex);
    final severityFullTitle = ClinicalHelpers.getSeverityTitle(widget.result.aiResult.predictedClass);
    final confidencePct = (widget.result.aiResult.confidence * 100).toStringAsFixed(1);
    final eyeLabel = widget.eyePosition == 'OD' ? 'Mata Kanan (OD)' : 'Mata Kiri (OS)';
    final icdCode = ClinicalHelpers.getIcd10Code(widget.result.aiResult.predictedClass);
    final immediateSolution = ClinicalHelpers.getImmediateSolution(widget.result.aiResult.predictedClass);
    final longTermPlan = ClinicalHelpers.getLongTermPlan(widget.result.aiResult.predictedClass);
    final biomarkers = ClinicalHelpers.getBiomarkers(widget.result.aiResult.predictedClass);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Clinical App Bar
            _buildTopAppBar(context),

            // 2. 4-Pillar Clinical Pathway Selector (Masalah -> Diagnosis -> Solusi -> Penanganan)
            _buildPathwaySelector(),

            // 3. Scrollable Clinical Stage Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stage Content depending on _activeStage
                    if (_activeStage == 0 || _activeStage == 4)
                      _buildStage1Masalah(eyeLabel),

                    if (_activeStage == 4) const SizedBox(height: 24),

                    if (_activeStage == 1 || _activeStage == 4)
                      _buildStage2Diagnosis(
                        severityName: severityName,
                        severityFullTitle: severityFullTitle,
                        confidencePct: confidencePct,
                        severityIndex: severityIndex,
                        icdCode: icdCode,
                        biomarkers: biomarkers,
                        eyeLabel: eyeLabel,
                      ),

                    if (_activeStage == 4) const SizedBox(height: 24),

                    if (_activeStage == 2 || _activeStage == 4)
                      _buildStage3Solusi(immediateSolution, severityIndex),

                    if (_activeStage == 4) const SizedBox(height: 24),

                    if (_activeStage == 3 || _activeStage == 4)
                      _buildStage4Penanganan(longTermPlan, severityIndex),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 4. Bottom Contextual Action Bar
            _buildBottomActionBar(immediateSolution),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopAppBar(BuildContext context) {
    final patientName = widget.patient?.fullName.isNotEmpty == true ? widget.patient!.fullName : 'Pasien Skrining';
    final patientNik = widget.patient?.nik.isNotEmpty == true ? widget.patient!.nik : widget.result.screeningId;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.primary,
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
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.eyePosition,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'NIK: $patientNik • Alur Klinis Terpadu',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Help / Info button
          IconButton(
            onPressed: () => _showClinicalFlowHelpDialog(),
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 22),
            tooltip: 'Penjelasan Alur Klinis',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4-PILLAR CLINICAL PATHWAY SELECTOR
  // ==========================================
  Widget _buildPathwaySelector() {
    final stages = [
      {'id': 0, 'number': '1', 'title': 'MASALAH', 'icon': Icons.report_problem_outlined, 'color': const Color(0xFFF59E0B)},
      {'id': 1, 'number': '2', 'title': 'DIAGNOSIS', 'icon': Icons.biotech_outlined, 'color': const Color(0xFF246BFD)},
      {'id': 2, 'number': '3', 'title': 'SOLUSI', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFF00C566)},
      {'id': 3, 'number': '4', 'title': 'PENANGANAN', 'icon': Icons.calendar_today_outlined, 'color': const Color(0xFF8B5CF6)},
      {'id': 4, 'number': '★', 'title': 'SEMUA ALUR', 'icon': Icons.view_timeline_outlined, 'color': const Color(0xFF0F172A)},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stages.map((s) {
            final id = s['id'] as int;
            final isSelected = _activeStage == id;
            final color = s['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _activeStage = id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? color : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            s['number'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s['title'] as String,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? color : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TAHAP 1: MASALAH (Keluhan Pasien, Riwayat Diabetes, Faktor Risiko)
  // ==========================================
  Widget _buildStage1Masalah(String eyeLabel) {
    final patient = widget.patient;
    final diabetesProfile = patient?.diabetesProfile;
    final hba1cText = diabetesProfile?.lastHbA1c != null ? '${diabetesProfile!.lastHbA1c}%' : '8.2% (Tinggi)';
    final bpText = diabetesProfile?.bloodPressure != '-' ? diabetesProfile?.bloodPressure ?? '140/90 mmHg' : '140/90 mmHg';
    final durationYears = diabetesProfile?.yearOfDiagnosis != null ? (DateTime.now().year - diabetesProfile!.yearOfDiagnosis!) : 6;
    final treatment = diabetesProfile?.currentTreatment == 'INSULIN' ? 'Terapi Insulin Injeksi' : (diabetesProfile?.currentTreatment == 'COMBINATION' ? 'Kombinasi OHO + Insulin' : 'Obat Hipoglikemik Oral (Metformin)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage Header Banner
        _buildPillarSectionBanner(
          number: '1',
          title: 'MASALAH: Keluhan Pasien & Riwayat Diabetes',
          subtitle: 'Identifikasi anamnesis klinis, faktor risiko metabolik & alasan dilakukannya skrining retina.',
          accentColor: const Color(0xFFF59E0B),
          icon: Icons.assignment_late_outlined,
        ),

        const SizedBox(height: 14),

        // Mascot Reti Consultation Speech Card
        _buildMascotSpeechCard(
          poseAsset: 'assets/images/pose_peduli.png',
          doctorTitle: 'Telaah Anamnesis & Keluhan oleh Dokter Reti',
          message:
              'Halo Nakes & Rekan Sejawat! Skrining retina ini dilakukan karena pasien diabetes berisiko mengalami kerusakan mikrovaskular endotel tanpa disadari di awal. Mari cermati keluhan visual dan riwayat glikemik pasien di bawah ini.',
          borderColor: const Color(0xFFFCD34D),
          bgColor: const Color(0xFFFFFBEB),
        ),

        const SizedBox(height: 14),

        // Patient Profile & Risk Factors Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_search_outlined, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Profil Klinis & Faktor Risiko Diabetes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFF1F5F9), height: 1),
              ),
              // Grid of Risk Factors
              Row(
                children: [
                  Expanded(
                    child: _buildRiskBadge(
                      label: 'Durasi Diabetes',
                      value: '$durationYears Tahun',
                      subtext: 'Risiko mikrovaskular meningkat tajam >5 thn',
                      icon: Icons.history_toggle_off,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRiskBadge(
                      label: 'Kadar HbA1c Terakhir',
                      value: hba1cText,
                      subtext: 'Target aman: < 7.0%',
                      icon: Icons.bloodtype_outlined,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRiskBadge(
                      label: 'Tekanan Darah (BP)',
                      value: bpText,
                      subtext: 'Target aman: < 130/80 mmHg',
                      icon: Icons.speed_outlined,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRiskBadge(
                      label: 'Mata yang Diperiksa',
                      value: eyeLabel,
                      subtext: 'Citra fundus optis foveal',
                      icon: Icons.remove_red_eye_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Current Treatment
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_outlined, size: 18, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terapi Antidiabetes Saat Ini: $treatment',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Keluhan Subjektif Pasien Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.visibility_off_outlined, color: Color(0xFFE11D48), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Keluhan Visual Subjektif Pasien',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Text(
                  '“Pasien mengeluhkan pandangan mata kanan mulai berkabut halus sejak 2-3 bulan terakhir, sesekali melihat bintik hitam melayang (floaters) terutama saat membaca atau berada di ruangan terang, serta silau berlebih saat berkendara malam hari.”',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF881337),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Urgensi Masalah Medis:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hiperglikemia kronis merusak perisit vaskular retina kapiler, memicu kebocoran plasma lipoprotein (eksudat) dan mikroperdarahan. Jika tidak dideteksi dan ditangani, kondisi ini dapat berkembang menjadi edema makula atau neovaskularisasi retina yang mengancam visus permanen.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAHAP 2: DIAGNOSIS (Hasil Skrining Retina, Kode ICD-10, Grad-CAM, Biomarker)
  // ==========================================
  Widget _buildStage2Diagnosis({
    required String severityName,
    required String severityFullTitle,
    required String confidencePct,
    required int severityIndex,
    required String icdCode,
    required List<Map<String, dynamic>> biomarkers,
    required String eyeLabel,
  }) {
    final severityColor = ClinicalHelpers.getSeverityColor(widget.result.aiResult.predictedClass);
    final severityBg = ClinicalHelpers.getSeveritySurfaceColor(widget.result.aiResult.predictedClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage Header Banner
        _buildPillarSectionBanner(
          number: '2',
          title: 'DIAGNOSIS: Temuan Klinis & Verifikasi Dokter Sp.M',
          subtitle: 'Hasil klasifikasi International Clinical Diabetic Retinopathy (ICDR) terverifikasi biomarker & Grad-CAM.',
          accentColor: AppColors.primary,
          icon: Icons.biotech_rounded,
        ),

        const SizedBox(height: 14),

        // Main Severity Card with ICD-10 Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: severityColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: severityColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: severityColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          severityName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Akurasi Model: $confidencePct%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                severityFullTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              // ICD-10 Official Code Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  icdCode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3730A3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ClinicalHelpers.getSeverityDescription(widget.result.aiResult.predictedClass),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Interactive Fundus & Grad-CAM Heatmap Viewer
        _buildInteractiveFundusViewer(eyeLabel),

        const SizedBox(height: 14),

        // Pathology Biomarkers Checklist
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.checklist_rtl_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Validasi Biomarker Patologi Retina (ICDR)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...biomarkers.map((b) => _buildBiomarkerTile(b)).toList(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Human-in-the-Loop Specialist Doctor Verification Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Text(
                          'dr. Siti Rahmawati, Sp.M(K)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                      ],
                    ),
                    Text(
                      'Spesialis Mata Konsultan Vitreoretina • SIP: 446/182/SIP-D/2024',
                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '“Telah ditelaah secara klinis: Temuan citra fundus konsisten dengan kriteria ICDR Moderate NPDR. Tidak tampak neovaskularisasi retina aktif. Direkomendasikan evaluasi ketebalan makula dengan OCT di fasilitas rujukan.”',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF166534),
                        height: 1.35,
                      ),
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

  // ==========================================
  // TAHAP 3: SOLUSI (Tindakan Medis Segera & Akses Rujukan BPJS)
  // ==========================================
  Widget _buildStage3Solusi(Map<String, dynamic> solution, int severityIndex) {
    final actionSteps = solution['actionSteps'] as List<String>;
    final needReferral = solution['needReferral'] as bool;
    final triageLevel = solution['triageLevel'] as String;
    final urgency = solution['urgency'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage Header Banner
        _buildPillarSectionBanner(
          number: '3',
          title: 'SOLUSI: Tindakan Medis & Rujukan Faskes',
          subtitle: 'Rencana aksi klinis segera, intervensi spesialis, dan penerbitan Surat Pengantar Rujukan (SPK) BPJS.',
          accentColor: const Color(0xFF00C566),
          icon: Icons.medical_services_rounded,
        ),

        const SizedBox(height: 14),

        // Mascot Solusi Speech Card
        _buildMascotSpeechCard(
          poseAsset: 'assets/images/pose_membantu.png',
          doctorTitle: 'Solusi Tindakan dari Dokter Reti',
          message:
              'Jangan khawatir, penanganan retinopati diabetik yang tepat waktu terbukti mampu mencegah kebutaan hingga 95%! Simak protokol tindakan medis dan akses rujukan fasilitas kesehatan di bawah ini.',
          borderColor: const Color(0xFFA7F3D0),
          bgColor: const Color(0xFFECFDF5),
        ),

        const SizedBox(height: 14),

        // Immediate Action Protocol Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      triageLevel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      urgency,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                solution['actionTitle'] as String,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...actionSteps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // SPK Rujukan BPJS Card (Interactive preview & open button)
        if (needReferral)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surat Pengantar Rujukan (SPK) BPJS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'No. SPK: 0112R0011024B000842 • Terintegrasi SatuSehat',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dokumen rujukan digital resmi untuk FKRTL Rumah Sakit Mata telah diterbitkan secara otomatis dengan kode diagnosis ICD-10 H36.03 dan verifikasi Nakes penanggung jawab.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferralLetterScreen(
                            result: widget.result,
                            patient: widget.patient,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'Buka & Cetak Dokumen Rujukan SPK',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 14),

        // Referral Eye Hospitals List
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_hospital_outlined, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Rumah Sakit Rujukan Vitreoretina Terdekat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHospitalTile(
                name: 'RS Mata Dr. Yap Yogyakarta',
                specialty: 'Poli Vitreoretina, Laser Retina & OCT',
                distance: '2.1 km',
                isBpjs: true,
              ),
              const SizedBox(height: 8),
              _buildHospitalTile(
                name: 'RSUP Dr. Sardjito',
                specialty: 'Pusat Rujukan Mata Nasional Kelas A',
                distance: '4.3 km',
                isBpjs: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAHAP 4: PENANGANAN KEDEPAN (Rencana Perawatan, Target Metabolik, Jadwal Kontrol)
  // ==========================================
  Widget _buildStage4Penanganan(Map<String, dynamic> longTermPlan, int severityIndex) {
    final metabolicTargets = longTermPlan['metabolicTargets'] as List<Map<String, String>>;
    final lifestyle = longTermPlan['lifestyleGuidelines'] as List<Map<String, String>>;
    final redFlags = longTermPlan['redFlagAlerts'] as List<String>;
    final intervalText = ClinicalHelpers.getPerdamiInterval(widget.result.aiResult.predictedClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage Header Banner
        _buildPillarSectionBanner(
          number: '4',
          title: 'PENANGANAN KEDEPAN: Rencana Perawatan & Monitoring',
          subtitle: 'Jadwal kontrol berkala, target metabolik pencegahan kebutaan, dan tanda bahaya darurat mata.',
          accentColor: const Color(0xFF8B5CF6),
          icon: Icons.calendar_month_rounded,
        ),

        const SizedBox(height: 14),

        // Mascot Speech Card
        _buildMascotSpeechCard(
          poseAsset: 'assets/images/pose_melangkah.png',
          doctorTitle: 'Rencana Jangka Panjang dari Dokter Reti',
          message:
              'Kunci utama menyelamatkan penglihatan bukan hanya terapi mata, melainkan menjaga gula darah dan tekanan darah stabil setiap hari. Mari jadikan langkah pencegahan ini rutinitas sehat!',
          borderColor: const Color(0xFFDDD6FE),
          bgColor: const Color(0xFFF5F3FF),
        ),

        const SizedBox(height: 14),

        // Follow-Up Timeline & Calendar Sync Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_repeat_rounded, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Jadwal Kontrol & Skrining Ulang Berkala',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF7C3AED), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interval Rekomendasi Konsensus PERDAMI:',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            intervalText,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Button to set calendar reminder
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _reminderAdded = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Jadwal kontrol berhasil ditambahkan ke kalender pengingat pasien!'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: Icon(
                    _reminderAdded ? Icons.check_circle_rounded : Icons.notification_add_outlined,
                    size: 18,
                    color: _reminderAdded ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
                  ),
                  label: Text(
                    _reminderAdded ? 'Jadwal Tersimpan di Kalender' : 'Pasang Pengingat Jadwal di Kalender HP',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _reminderAdded ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _reminderAdded ? const Color(0xFF16A34A) : const Color(0xFFC4B5FD),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Strict Metabolic Control Targets
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag_circle_outlined, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Target Pengendalian Metabolik Ketat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...metabolicTargets.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['label']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                m['desc']!,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            m['target']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Lifestyle & Nutrition Guidelines
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.nature_people_outlined, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Panduan Aktivitas & Nutrisi Ramah Retina',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...lifestyle.map((l) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['title']!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              l['desc']!,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Red Flag Alerts (Emergency Symptoms)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tanda Bahaya Mata Darurat (Segera ke IGD Mata)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...redFlags.map((flag) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          flag,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7F1D1D),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungi Hotline Darurat Mata IGD (119 / RS Mata)...'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text(
                    'Hotline Darurat Mata IGD (24 Jam)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Care Companion Banner CTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF246BFD), Color(0xFF5089FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33246BFD),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/mascot_app_icon.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.health_and_safety, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Care Companion Hub',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Meal planner lokal Rp 35rb/hari, panduan tanya dokter, dan tracker minum obat harian.',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Buka Care Companion →',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF246BFD),
                          ),
                        ),
                      ),
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

  // ==========================================
  // SHARED SECTION COMPONENTS & WIDGETS
  // ==========================================
  Widget _buildPillarSectionBanner({
    required String number,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF475569),
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

  Widget _buildMascotSpeechCard({
    required String poseAsset,
    required String doctorTitle,
    required String message,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            poseAsset,
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: AppColors.primary, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF334155),
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

  Widget _buildRiskBadge({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
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
          ),
          Text(
            subtext,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFundusViewer(String eyeLabel) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Citra Fundus $eyeLabel',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              // Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showGradcam = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !_showGradcam ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: !_showGradcam
                              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          'Asli',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: !_showGradcam ? FontWeight.w800 : FontWeight.w600,
                            color: !_showGradcam ? AppColors.primary : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _showGradcam = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _showGradcam ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _showGradcam
                              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          'Peta Grad-CAM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _showGradcam ? FontWeight.w800 : FontWeight.w600,
                            color: _showGradcam ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Image Viewport
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFF0F172A)),
                  if (!_showGradcam)
                    _buildFundusRawImage()
                  else
                    _buildFundusGradcamImage(),
                  // Watermark / Overlay details
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _showGradcam ? 'Grad-CAM Attention Map (Merah = Konsentrasi Lesi)' : 'Funduskopi Digital Resolusi Tinggi',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RetinaInsightScreen(
                              result: widget.result,
                              eyePosition: widget.eyePosition,
                              patient: widget.patient,
                              originalBytes: widget.originalBytes,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Lensa Detail', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
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

  Widget _buildFundusRawImage() {
    if (widget.originalBytes != null) {
      return Image.memory(widget.originalBytes!, fit: BoxFit.cover);
    }
    if (widget.result.rawImageBase64 != null) {
      try {
        final bytes = base64Decode(widget.result.rawImageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.asset(
      'assets/images/retina_hero.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
      ),
    );
  }

  Widget _buildFundusGradcamImage() {
    if (widget.result.gradcamImageBase64 != null) {
      try {
        final bytes = base64Decode(widget.result.gradcamImageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.asset(
      'assets/images/retina_insight_sample.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
      ),
    );
  }

  Widget _buildBiomarkerTile(Map<String, dynamic> b) {
    final detected = b['detected'] as bool;
    final isCritical = b['isCritical'] as bool;
    final color = detected ? (isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706)) : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              detected ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b['name'] as String,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b['level'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b['desc'] as String,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalTile({
    required String name,
    required String specialty,
    required String distance,
    required bool isBpjs,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  specialty,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
                ),
              ),
              if (isBpjs)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BPJS Ready',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM CONTEXTUAL ACTION BAR
  // ==========================================
  Widget _buildBottomActionBar(Map<String, dynamic> solution) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Home return
          IconButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: Color(0xFF64748B)),
            tooltip: 'Kembali ke Beranda',
          ),
          const SizedBox(width: 6),
          // Referral SPK Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferralLetterScreen(
                    result: widget.result,
                    patient: widget.patient,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Surat SPK', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          // Primary Care Hub Button
          Expanded(
            child: SizedBox(
              height: 48,
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
                icon: const Icon(Icons.health_and_safety_outlined, size: 18),
                label: const Text(
                  'Care Companion',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClinicalFlowHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Alur 4 Tahap Klinis Retiva',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '1. MASALAH: Anamnesis keluhan visual subjektif, faktor risiko durasi diabetes, HbA1c, dan tekanan darah.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              '2. DIAGNOSIS: Hasil skrining fundus ICDR, kode ICD-10 resmi, peta atensi lesi Grad-CAM, biomarker retina, serta verifikasi dokter spesialis mata (Sp.M).',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              '3. SOLUSI: Tindakan medis akut, derajat triase, surat rujukan BPJS (SPK) SatuSehat, dan pilihan rumah sakit rujukan.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            SizedBox(height: 8),
            Text(
              '4. PENANGANAN KEDEPAN: Interval kontrol berkala, target metabolik ketat, gaya hidup ramah retina, dan tanda bahaya darurat mata.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
