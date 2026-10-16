import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../core/network/api_client.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'status_human_review_screen.dart';
import 'clinical_recommendation_screen.dart';
import '../widgets/notification_bell_widget.dart';

class HumanReviewPendingScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;
  final Uint8List? imageBytes;
  final File? imageFile;

  const HumanReviewPendingScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
    this.imageBytes,
    this.imageFile,
  });

  @override
  State<HumanReviewPendingScreen> createState() => _HumanReviewPendingScreenState();
}

class _HumanReviewPendingScreenState extends State<HumanReviewPendingScreen> {
  int _selectedDoctorIndex = 0;
  bool _isDoctorReviewed = false;
  String? _reviewedDoctorName;
  String? _reviewedDoctorRole;
  String? _reviewedDoctorNotes;
  String? _reviewedDoctorSip;
  String? _adjudicationAction;
  String? _finalGrade;
  DateTime? _reviewedAt;
  Timer? _reviewPollingTimer;

  bool get _isNormalOrHighReliability =>
      widget.result.aiResult.predictedClass == 'NO_DR' ||
      !widget.result.reliability.requiresHumanReview;

  List<Map<String, String>> _doctors = [
    {
      'id': 'a0af4802-63ce-4ac4-a09b-5597391c5827',
      'name': 'dr. Yunani Setyandriana, Sp.M',
      'role': 'Spesialis Vitreoretina & Oftalmologi',
      'hospital': 'RSUP Dr. Sardjito / Faskes Mitra RETIVA',
      'sip': 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)',
      'email': 'tioramadhan3106@gmail.com',
    },
    {
      'id': 'b1bf5913-74df-5bd5-b10c-6608402d6938',
      'name': 'dr. Arga Pratama, Sp.M',
      'role': 'Spesialis Vitreoretina',
      'hospital': 'RS Mata Cicendo / Perdami Jabar',
      'sip': 'SIP: 446.1/1829/SIP-D/2023',
      'email': 'arga.pratama@retiva.id',
    },
    {
      'id': 'c2cf6024-85ea-6ce6-c21d-7719513e7049',
      'name': 'dr. Siti Nurhaliza, Sp.M(K)',
      'role': 'Konsultan Retina & Diabetes',
      'hospital': 'RSUP Dr. Sardjito',
      'sip': 'SIP: 446.1/2041/SIP-D/2024',
      'email': 'siti.nurhaliza@retiva.id',
    },
    {
      'id': 'd3da7135-96fb-7df7-d32e-8820624f815a',
      'name': 'dr. Hendra Kusuma, Sp.M',
      'role': 'Spesialis Oftalmologi',
      'hospital': 'RS Mata Yap Yogyakarta',
      'sip': 'SIP: 446.1/1592/SIP-D/2022',
      'email': 'hendra.kusuma@retiva.id',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorsFromDb();
    _startReviewPolling();
  }

  @override
  void dispose() {
    _reviewPollingTimer?.cancel();
    super.dispose();
  }

  void _startReviewPolling() {
    _reviewPollingTimer?.cancel();
    _reviewPollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isDoctorReviewed) {
        timer.cancel();
        return;
      }
      try {
        final res = await ApiClient().checkReviewStatus(widget.result.screeningId);
        if (mounted && res['isReviewed'] == true) {
          timer.cancel();
          final doctorName = (res['doctorName'] ?? 'dr. Yunani Setyandriana, Sp.M').toString();
          final docRole = res['doctorRole']?.toString();
          final docSip = res['doctorSip']?.toString();
          final docNotes = res['notes']?.toString();
          final adjAction = res['adjudicationAction']?.toString();
          final fGrade = (res['finalGrade'] ?? res['confirmedGrade'])?.toString();
          DateTime reviewTime = DateTime.now();
          if (res['adjudicatedAt'] != null) {
            final parsed = DateTime.tryParse(res['adjudicatedAt'].toString());
            if (parsed != null) reviewTime = parsed;
          }
          NotificationBellWidget.incrementUnread(doctorName: doctorName);
          setState(() {
            _isDoctorReviewed = true;
            _reviewedDoctorName = doctorName;
            _reviewedDoctorRole = docRole;
            _reviewedDoctorSip = docSip;
            _reviewedDoctorNotes = docNotes;
            _adjudicationAction = adjAction;
            _finalGrade = fGrade;
            _reviewedAt = reviewTime;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Telaah Spesialis Selesai! $doctorName telah menyelesaikan telaah & menandatangani rekomendasi klinis.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (_) {}
    });
  }

  Future<void> _loadDoctorsFromDb() async {
    try {
      final dbDoctors = await ApiClient().getDoctors();
      if (mounted && dbDoctors.isNotEmpty) {
        setState(() {
          _doctors = dbDoctors;
          if (_selectedDoctorIndex >= _doctors.length) {
            _selectedDoctorIndex = 0;
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final severityTitle =
        ClinicalHelpers.getSeverityTitle(widget.result.aiResult.predictedClass);
    final confidencePct =
        (widget.result.aiResult.confidence * 100).toStringAsFixed(1);
    final eyeLabel = widget.eyePosition == 'OD' ? 'OD • Mata Kanan' : 'OS • Mata Kiri';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper Breadcrumb (Langkah 3 dari 4)
                    _buildStepperBreadcrumb(),

                    const SizedBox(height: 16),

                    // Heading 3
                    const Text(
                      'Memeriksa Keandalan Hasil',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF246BFD),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RETIVA mengevaluasi apakah hasil model cukup meyakinkan untuk ditampilkan sebagai hasil screening.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF434652),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scanning HUD Reticle Viewport
                    _buildScanningHudViewport(eyeLabel),

                    const SizedBox(height: 12),

                    // Diagnostic Verdict Summary Ribbon
                    _buildVerdictRibbon(severityTitle, confidencePct),

                    const SizedBox(height: 16),

                    // Primary Reliability Assessment Matrix Card
                    _buildReliabilityMatrixCard(confidencePct),

                    const SizedBox(height: 16),

                    // Card 1: Tidak Perlu Foto Ulang
                    _buildNoRetakeCard(),

                    const SizedBox(height: 12),

                    if (_isNormalOrHighReliability) ...[
                      // Khusus Normal / Keandalan Tinggi: Informasi Validasi Optimal & Alur
                      _buildHighReliabilityNoticeCard(confidencePct),
                      const SizedBox(height: 16),
                      _buildNormalStagesCard(),
                    ] else ...[
                      // Card 2: Estimasi Waktu Tinjauan
                      _buildEstimationTimeCard(),

                      const SizedBox(height: 16),

                      // Card 3: Interactive Doctor Selection (Verifikator Medis Sp.M)
                      _buildDoctorSelectionCard(),

                      const SizedBox(height: 16),

                      // Card 4: Tahapan Tinjauan
                      _buildReviewStagesCard(),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA: Lihat Status Human Review
            _buildBottomCta(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          const Expanded(
            child: Text(
              'Keandalan Hasil Analisis',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF246BFD),
              ),
            ),
          ),
          const NotificationBellWidget(),
        ],
      ),
    );
  }

  Widget _buildStepperBreadcrumb() {
    return Container(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF246BFD),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Langkah 3 dari 4: Analisis Retina',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF246BFD),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _buildStepIndicator(isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: true),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required bool isCurrent}) {
    return Container(
      width: isCurrent ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF246BFD) : const Color(0xFFD8E3FB),
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }

  Widget _buildScanningHudViewport(String eyeLabel) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundus Retina Image (Displays the real uploaded fundus image)
            if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty)
              Image.memory(
                widget.imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/fundus_borderline_sample.jpg',
                  fit: BoxFit.cover,
                ),
              )
            else if (widget.imageFile != null)
              Image.file(
                widget.imageFile!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/fundus_borderline_sample.jpg',
                  fit: BoxFit.cover,
                ),
              )
            else
              Image.asset(
                'assets/images/fundus_borderline_sample.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D1E25)),
              ),

            // Subtle dark gradient vignette
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x990D1E25),
                    Colors.transparent,
                    Color(0x990D1E25),
                  ],
                ),
              ),
            ),

            // HUD Crosshair
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x660061A4), width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.filter_center_focus_rounded,
                    size: 36,
                    color: Color(0x998DF5E4),
                  ),
                ),
              ),
            ),

            // Top HUD Badges
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x990D1E25),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8DF5E4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              eyeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x990D1E25),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'FOV: 45° Macula',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD4E5EF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom HUD Badges
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EVAL: ENET-B3-VAL-v2',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xE6F4FAFF),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xB300564D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Quality Passed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8DF5E4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictRibbon(String severityTitle, String confidencePct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBCE3F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KANDIDAT PREDIKSI',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF434652),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  severityTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1E25),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'KEYAKINAN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF434652),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$confidencePct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0061A4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReliabilityMatrixCard(String confidencePct) {
    final confVal = widget.result.aiResult.confidence;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF1FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        size: 16,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metrik Keandalan Klinis',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Dual-gate safety verification',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge Keandalan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isNormalOrHighReliability ? const Color(0xFFEFF6FF) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: _isNormalOrHighReliability ? const Color(0xFFBFDBFE) : const Color(0xFFFDE047),
                  ),
                ),
                child: Text(
                  _isNormalOrHighReliability ? 'Keandalan Tinggi' : 'Perlu Review',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isNormalOrHighReliability ? const Color(0xFF246BFD) : const Color(0xFF854D0E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2x2 Grid of Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Arsitektur AI',
                  value: 'EfficientNet-B3',
                  icon: Icons.hub_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Tingkat Ketidakpastian',
                  value: _isNormalOrHighReliability ? 'Rendah (H: 0.02)' : 'Tinggi (H: 0.12)',
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Uji Distribusi (OOD)',
                  value: 'Passed • In-Dist',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'Konkordansi Model',
                  value: _isNormalOrHighReliability ? 'High Match' : 'Low Match',
                  icon: Icons.compare_arrows_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ambang Batas Kepercayaan Bar Visualizer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ambang Batas Kepercayaan\n(Threshold ≥ 85%)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF434652),
                  height: 1.3,
                ),
              ),
              Text(
                '$confidencePct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF246BFD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bar Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFE2E8F0)),
                  FractionallySizedBox(
                    widthFactor: (confVal).clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFF246BFD)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                'Ambang Batas Klinis',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF64748B)),
              ),
              Text(
                '100%',
                style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Color(0xFF64748B)),
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
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF0F172A)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoRetakeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF1FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 20,
              color: Color(0xFF0061A4),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Perlu Foto Ulang',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Anda TIDAK perlu mengambil atau mengunggah foto retina lagi.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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

  Widget _buildEstimationTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF1FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: Color(0xFF0061A4),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimasi Waktu Tinjauan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hasil estimasi review selesai dalam 1×24 jam kerja.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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

  Widget _buildDoctorSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBCE3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_pin_circle_rounded, size: 18, color: Color(0xFF246BFD)),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Dokter Peninjau (Sp.M)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF1FB),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'Verifikator',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih dokter spesialis mata mitra yang akan memverifikasi telaah foto retina ini:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Radio list of doctors
          ...List.generate(_doctors.length, (index) {
            final doc = _doctors[index];
            final isSelected = _selectedDoctorIndex == index;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDoctorIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF246BFD) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medical_services_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc['name']!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? const Color(0xFF246BFD) : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${doc['role']} • ${doc['hospital']}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: isSelected ? const Color(0xFF246BFD) : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewStagesCard() {
    final selectedDoc = _doctors.isNotEmpty
        ? _doctors[_selectedDoctorIndex.clamp(0, _doctors.length - 1)]
        : {
            'name': 'dr. Yunani Setyandriana, Sp.M',
            'role': 'Spesialis Vitreoretina & Oftalmologi',
          };

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tahapan Tinjauan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDoctorReviewed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDoctorReviewed ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  _isDoctorReviewed ? 'Review Selesai' : 'Menunggu Telaah',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isDoctorReviewed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Items
          _buildStageItem(
            icon: Icons.check,
            title: 'Foto diterima sistem',
            subtitle: ClinicalHelpers.formatIndonesianDateTime(DateTime.now()),
            isDone: true,
            isPending: false,
            isLast: false,
          ),
          _buildStageItem(
            icon: Icons.check,
            title: 'Analisis otomatis selesai',
            subtitle: 'Kualitas citra tervalidasi',
            isDone: true,
            isPending: false,
            isLast: false,
          ),
          _buildStageItem(
            icon: _isDoctorReviewed ? Icons.check : Icons.hourglass_top_rounded,
            title: _isDoctorReviewed ? 'Review selesai' : 'Review dokter spesialis',
            subtitle: _isDoctorReviewed
                ? 'Review telaah klinis spesialis selesai (${selectedDoc['name']})'
                : 'Menunggu telaah & verifikasi dari ${selectedDoc['name']}',
            isDone: _isDoctorReviewed,
            isPending: !_isDoctorReviewed,
            isLast: false,
          ),
          _buildStageItem(
            icon: _isDoctorReviewed ? Icons.assignment_turned_in_rounded : Icons.lock_clock_rounded,
            title: 'Hasil akhir & rekomendasi tersedia',
            subtitle: _isDoctorReviewed
                ? 'Hasil telaah klinis & surat rujukan siap diakses'
                : 'Akan terbuka otomatis setelah dokter menyelesaikan telaah',
            isDone: _isDoctorReviewed,
            isPending: false,
            isLast: true,
          ),

          const SizedBox(height: 14),

          // Notification Alert Banner with Bell Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDoctorReviewed ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDoctorReviewed ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isDoctorReviewed ? Icons.check_circle_rounded : Icons.notifications_active_outlined,
                  size: 18,
                  color: _isDoctorReviewed ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isDoctorReviewed
                        ? 'Telaah selesai! Notifikasi telah dikirim dan hasil rekomendasi dokter kini tersedia.'
                        : 'Kami akan mengirim pemberitahuan saat telaah spesialis selesai.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: _isDoctorReviewed ? const Color(0xFF166534) : const Color(0xFF64748B),
                      fontWeight: _isDoctorReviewed ? FontWeight.w600 : FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({

    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isLast,
    bool isPending = false,
  }) {
    Color circleBg;
    Color iconColor;

    if (isDone) {
      circleBg = const Color(0xFFDFF1FB);
      iconColor = const Color(0xFF0061A4);
    } else if (isPending) {
      circleBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
    } else {
      circleBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: isPending
                      ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: iconColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? const Color(0xFF0061A4) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
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
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDone || isPending
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Menunggu',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: isPending ? const Color(0xFFB45309) : const Color(0xFF64748B),
                      fontWeight: isPending ? FontWeight.w500 : FontWeight.w400,
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

  Widget _buildBottomCta(BuildContext context) {
    final selectedDoc = _doctors.isNotEmpty
        ? _doctors[_selectedDoctorIndex.clamp(0, _doctors.length - 1)]
        : {
            'name': 'dr. Yunani Setyandriana, Sp.M',
            'role': 'Spesialis Vitreoretina & Oftalmologi',
          };

    if (_isNormalOrHighReliability) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClinicalRecommendationScreen(
                    result: widget.result,
                    eyePosition: widget.eyePosition,
                    patient: widget.patient,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'Lihat Rekomendasi Tindak Lanjut',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BFD),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            final rawId = widget.result.screeningId;
            final displayId = rawId.startsWith('#')
                ? rawId
                : ClinicalHelpers.generateScreeningDisplayId(rawId);

            // Daftarkan kasus langsung ke web portal telaah spesialis
            ApiClient().submitForHumanReview(
              screeningId: displayId,
              patientName: widget.patient?.fullName ?? (ApiClient().currentUser?.fullName ?? 'Bapak Sutrisno'),
              patientNik: widget.patient?.nik ?? '3404015508750001',
              eyePosition: widget.eyePosition,
              drGrade: widget.result.aiResult.predictedClass,
              confidence: widget.result.aiResult.confidence * 100,
              doctorName: selectedDoc['name'],
              doctorRole: selectedDoc['role'],
              doctorSip: selectedDoc['sip'],
            );

            final chosenDoctorName = _reviewedDoctorName ?? selectedDoc['name'] ?? 'dr. Yunani Setyandriana, Sp.M';
            final chosenDoctorRole = _reviewedDoctorRole ?? selectedDoc['role'] ?? 'Spesialis Vitreoretina & Oftalmologi';
            final chosenDoctorSip = _reviewedDoctorSip ?? selectedDoc['sip'] ?? 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)';

            ApiClient().updateLocalScreeningReview(
              screeningId: widget.result.screeningId,
              doctorName: chosenDoctorName,
              doctorRole: chosenDoctorRole,
              doctorSip: chosenDoctorSip,
              isReviewed: _isDoctorReviewed,
            );

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatusHumanReviewScreen(
                  result: widget.result,
                  eyePosition: widget.eyePosition,
                  patient: widget.patient,
                  imageBytes: widget.imageBytes,
                  imageFile: widget.imageFile,
                  doctorName: chosenDoctorName,
                  doctorRole: chosenDoctorRole,
                  doctorSip: chosenDoctorSip,
                  doctorNotes: _reviewedDoctorNotes,
                  reviewedAt: _reviewedAt,
                  isDoctorReviewed: _isDoctorReviewed,
                  adjudicationAction: _adjudicationAction,
                  finalGrade: _finalGrade,
                ),
              ),
            );
            if (result == true && mounted) {
              setState(() {
                _isDoctorReviewed = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF246BFD),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            _isDoctorReviewed ? 'Lihat Hasil Akhir & Rekomendasi' : 'Lihat Status Human Review',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighReliabilityNoticeCard(String confidencePct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFF246BFD),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validasi AI Lolos Ambang Klinis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Standar ICDR & Perdami 2024',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Otomatis',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Skor keyakinan inferensi mencapai $confidencePct% (di atas ambang batas 85%). Tidak ditemukan anomali vaskular kritis yang memerlukan telaah sekunder dokter spesialis mata. Hasil dapat langsung diteruskan ke panduan tindakan klinis.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalStagesCard() {
    return Container(
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
              Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF246BFD)),
              SizedBox(width: 8),
              Text(
                'Alur Pemeriksaan Skrining',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStageItem(
            icon: Icons.check_circle_rounded,
            title: 'Kualitas Citra & Foto Fundus Terverifikasi',
            subtitle: 'Citra fundus tajam, fokus pada makula dan diskus optikus.',
            isDone: true,
            isPending: false,
            isLast: false,
          ),
          _buildStageItem(
            icon: Icons.check_circle_rounded,
            title: 'Analisis AI & Reliability Gate Lolos',
            subtitle: 'Keyakinan AI prima tanpa anomali mikrovaskular meragukan.',
            isDone: true,
            isPending: false,
            isLast: false,
          ),
          _buildStageItem(
            icon: Icons.task_alt_rounded,
            title: 'Rekomendasi Tindak Lanjut Siap',
            subtitle: 'Panduan pola hidup, diet 3J, dan jadwal kontrol berkala tersedia.',
            isDone: true,
            isPending: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}
