import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'quality_failed_retake_screen.dart';
import 'ai_analyzing_screen.dart';

/// Screens 04 & 05: 04. Kualitas I/II & 05. Kualitas Jelas (Figma Frames 133:49, 133:478, & 85:1054)
/// Authoritative 1:1 Implementation matching Figma source of truth.
class QualityScanningScreen extends StatefulWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String eyePosition;
  final String demoBranch;
  final PatientModel? patient;

  const QualityScanningScreen({
    super.key,
    this.imageFile,
    this.imageBytes,
    required this.eyePosition,
    required this.demoBranch,
    this.patient,
  });

  @override
  State<QualityScanningScreen> createState() => _QualityScanningScreenState();
}

class _QualityScanningScreenState extends State<QualityScanningScreen> with SingleTickerProviderStateMixin {
  bool _isEvaluating = true;
  double _scanProgress = 0.18;
  CompleteScreeningResult? _result;
  Timer? _progressTimer;
  late AnimationController _scannerAnimCtrl;

  @override
  void initState() {
    super.initState();
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startQualityEvaluation();
  }

  @override
  void dispose() {
    _scannerAnimCtrl.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startQualityEvaluation() async {
    // Progressive percentage animation matching Figma 18% -> 43% -> 100%
    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (mounted && _isEvaluating) {
        setState(() {
          if (_scanProgress < 0.90) {
            _scanProgress += 0.22;
          }
        });
      }
    });

    // Execute real screening or simulation via ApiClient
    final result = await ApiClient().executeScreening(
      imageFile: widget.imageFile,
      imageBytes: widget.imageBytes,
      eyePosition: widget.eyePosition,
      simulateRetake: widget.demoBranch == 'RETAKE',
      simulateHumanReview: widget.demoBranch == 'HUMAN_REVIEW',
    );

    // Give visual satisfaction before transitioning to "05. Kualitas Jelas"
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      _progressTimer?.cancel();
      setState(() {
        _isEvaluating = false;
        _scanProgress = 1.0;
        _result = result;
      });

      // If quality check failed -> navigate to Retake screen
      if (!result.qualityOD.passed) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QualityFailedRetakeScreen(
                  eyePosition: widget.eyePosition,
                  qualityResult: result.qualityOD,
                ),
              ),
            );
          }
        });
      }
    }
  }

  void _proceedToAnalysis() {
    if (_result == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalyzingScreen(
          result: _result!,
          eyePosition: widget.eyePosition,
          demoBranch: widget.demoBranch,
          patient: widget.patient,
          imageBytes: widget.imageBytes,
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
            // Top Bar with Back Button (Figma Node 133:89 / 85:1083)
            _buildTopBar(),

            // Main Scrollable Inner Page Content (Figma Node 133:50 / 85:1055)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper Breadcrumb: Langkah 2 dari 4: Kualitas Citra (Figma Node 133:55 / 133:1153)
                    _buildStepperBreadcrumb(),

                    const SizedBox(height: 16),

                    // Heading & Subtitle (Figma Node 133:66 / 85:1060)
                    _buildHeadingSection(),

                    const SizedBox(height: 16),

                    // Fundus Scanning Viewport (Figma Node 133:71 / 133:1134)
                    Center(child: _buildFundusScanningViewport()),

                    const SizedBox(height: 20),

                    // Metrics Section (Toggled State: Evaluating Cards vs Passed 3-Factor Breakdown)
                    if (_isEvaluating) ...[
                      _buildEvaluatingMetricsList(),
                      const SizedBox(height: 16),
                      _buildRealtimeValidationBanner(),
                    ] else ...[
                      _buildDiagnosticBreakdownSection(),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom CTA Button (Figma Node 85:1154) - Only shown when evaluation passed
            if (!_isEvaluating && (_result?.qualityOD.passed ?? true))
              _buildBottomCtaArea(),
          ],
        ),
      ),
    );
  }

  /// Top Bar with Back Button (Figma Node 133:89 / 85:1083)
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: AppColors.figmaBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Kualitas Foto Retina',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.figmaBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Stepper Breadcrumb: Langkah 2 dari 4 (Figma Node 133:55 / 133:1153)
  Widget _buildStepperBreadcrumb() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.figmaBlue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '2',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Langkah 2 dari 4: Kualitas Citra',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.figmaBlueDark,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),

        // Step 2 is active (24px width in #0D47A1)
        Row(
          children: [
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 24,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.figmaBlue,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E3FB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Heading Section: Memeriksa Kualitas Citra vs Kualitas Citra Baik (Figma Node 133:66 / 85:1060)
  Widget _buildHeadingSection() {
    final title = _isEvaluating ? 'Memeriksa Kualitas Citra' : 'Kualitas Citra Baik';
    final subtitle = _isEvaluating
        ? 'Verifikasi kelayakan citra sebelum proses AI'
        : 'Citra retina memenuhi kualitas minimum untuk dilakukan analisis. Sistem akan melanjutkan ke pemeriksaan retina.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.figmaBlue,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF475569),
            height: 1.38,
          ),
        ),
      ],
    );
  }

  /// Fundus Scanning Viewport (290x290 with 266x266 inner frame) (Figma Node 133:71 / 133:1134)
  Widget _buildFundusScanningViewport() {
    return Container(
      width: 290,
      height: 290,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1E25),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundus Image Rendering
            if (widget.imageBytes != null)
              Image.memory(widget.imageBytes!, fit: BoxFit.cover)
            else if (widget.imageFile != null && !kIsWeb)
              Image.file(widget.imageFile!, fit: BoxFit.cover)
            else
              Image.asset('assets/images/upload_preview_sample.png', fit: BoxFit.cover),

            // Dark Clinical Tint Overlay (Figma Node 133:74 / 133:1137)
            Container(color: const Color(0x1A003178)), // rgba(0,49,120,0.1)

            // Animated Laser Scanner Bar (Only while evaluating)
            if (_isEvaluating)
              AnimatedBuilder(
                animation: _scannerAnimCtrl,
                builder: (context, child) {
                  return Positioned(
                    top: _scannerAnimCtrl.value * 230,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF38BDF8),
                            Colors.white,
                            Color(0xFF38BDF8),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x8038BDF8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Top-left Glass HUD Badge: HUD SCAN: AKTIF (Figma Node 133:83)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xB30D1E25), // rgba(13,30,37,0.7)
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF33A0FD),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isEvaluating ? 'HUD SCAN: AKTIF' : 'KONTROL MUTU: LOLOS',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.44,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right Glass Badge: FOV 45° OD (Figma Node 133:87)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xBF0D1E25), // rgba(13,30,37,0.75)
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'FOV 45° ${widget.eyePosition}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// State 1: 4 Evaluating Quality Metric Cards (Figma Frame 133:49)
  Widget _buildEvaluatingMetricsList() {
    final sharpnessVal = '${(_scanProgress * 100).clamp(18, 95).toInt()}%';
    final lightingVal = '${(_scanProgress * 100).clamp(25, 91).toInt()}%';

    return Column(
      children: [
        _buildMetricProgressCard(
          title: '1. Ketajaman Citra',
          statusText: sharpnessVal,
          description: 'Sedang memeriksa kontras pembuluh darah retina',
        ),
        const SizedBox(height: 8),
        _buildMetricProgressCard(
          title: '2. Pencahayaan & Iluminasi',
          statusText: lightingVal,
          description: 'Tidak ditemukan artefak overexposure',
        ),
        const SizedBox(height: 8),
        _buildMetricProgressCard(
          title: '3. Cakupan Fundus',
          statusText: 'Optimal',
          description: 'Diskus optikus & fovea sentralis tercakup penuh',
        ),
        const SizedBox(height: 8),
        _buildMetricProgressCard(
          title: '4. Kelayakan Analisis',
          statusText: 'Evaluasi',
          description: 'Menilai kesesuaian untuk model EfficientNet-B3',
        ),
      ],
    );
  }

  Widget _buildMetricProgressCard({
    required String title,
    required String statusText,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.figmaBlueDark,
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
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.figmaTextHeading,
                        letterSpacing: 0.26,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF1FB),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.figmaBlueDark,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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

  /// Realtime Validation Banner (Figma Node 133:149)
  Widget _buildRealtimeValidationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATUS VALIDASI REALTIME',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.figmaBlueDark,
                  letterSpacing: 0.28,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1E4FF),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'Memindai',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00497D),
                    letterSpacing: 0.44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: _scanProgress.clamp(0.18, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFD4E5EF),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.figmaBlueDark),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Memvalidasi kecukupan gradien pembuluh darah mikro retina...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.figmaTextBody,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }

  /// State 2: Diagnostic Breakdown Metrics (Figma Frame 85:1054 / Node 92:1403)
  Widget _buildDiagnosticBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row (Figma Node 92:1404)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Penyebab Kualitas Tinggi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.figmaTextHeading,
                letterSpacing: 0.26,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD9EBF5),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text(
                '3 Faktor',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0061A4),
                  letterSpacing: 0.44,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 3 High Quality Verified Factors (Figma Node 92:1411, 92:1419, 92:1427)
        _buildQualityFactorCard(
          title: 'Ketajaman citra baik',
          subtitle: 'Skor Ketajaman 95%',
        ),
        const SizedBox(height: 8),
        _buildQualityFactorCard(
          title: 'Pencahayaan cukup merata',
          subtitle: 'Tidak ditemukan refleksi berlebih yang mengganggu',
        ),
        const SizedBox(height: 8),
        _buildQualityFactorCard(
          title: 'Cakupan retina mencukupi',
          subtitle: 'Area retina dan pembuluh darah terlihat dengan baik',
        ),
      ],
    );
  }

  Widget _buildQualityFactorCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Color(0xFF0061A4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.figmaTextHeading,
                    letterSpacing: 0.26,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  /// Bottom CTA Button: Lanjut Analisis (Figma Node 85:1154)
  Widget _buildBottomCtaArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _proceedToAnalysis,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.figmaBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjut Analisis',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.15,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
