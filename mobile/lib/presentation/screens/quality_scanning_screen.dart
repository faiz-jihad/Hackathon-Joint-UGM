import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/quality_indicator_tile.dart';
import 'quality_failed_retake_screen.dart';
import 'ai_analyzing_screen.dart';

class QualityScanningScreen extends StatefulWidget {
  final File? imageFile;
  final String eyePosition;
  final String demoBranch;
  final PatientModel? patient;

  const QualityScanningScreen({
    super.key,
    this.imageFile,
    required this.eyePosition,
    required this.demoBranch,
    this.patient,
  });

  @override
  State<QualityScanningScreen> createState() => _QualityScanningScreenState();
}

class _QualityScanningScreenState extends State<QualityScanningScreen> {
  bool _isEvaluating = true;
  CompleteScreeningResult? _result;

  @override
  void initState() {
    super.initState();
    _startQualityEvaluation();
  }

  Future<void> _startQualityEvaluation() async {
    // Artificial scanning step progression for visual feedback
    await Future.delayed(const Duration(milliseconds: 1200));

    // Call API Client
    final result = await ApiClient().executeScreening(
      imageFile: widget.imageFile ?? File(''),
      eyePosition: widget.eyePosition,
      simulateRetake: widget.demoBranch == 'RETAKE',
      simulateHumanReview: widget.demoBranch == 'HUMAN_REVIEW',
    );

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _result = result;
      });

      // If quality check failed -> navigate directly to Retake screen (Figma Branch 2)
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

  @override
  Widget build(BuildContext context) {
    final passed = _result?.qualityOD.passed ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(showBack: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge & Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isEvaluating
                                ? AppColors.primarySurface
                                : (passed ? AppColors.statusGreenSurface : AppColors.statusRedSurface),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isEvaluating
                                  ? AppColors.primaryLight
                                  : (passed ? AppColors.statusGreen : AppColors.statusRed),
                            ),
                          ),
                          child: Text(
                            _isEvaluating
                                ? 'Memindai Kualitas Citra...'
                                : (passed ? 'KUALITAS JELAS' : 'KUALITAS GAGAL'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _isEvaluating
                                  ? AppColors.primaryDark
                                  : (passed ? AppColors.statusGreen : AppColors.statusRed),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Mata ${widget.eyePosition}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _isEvaluating
                          ? 'Kendali Mutu Citra Otomatis'
                          : 'Hasil Evaluasi Quality Gate',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Memastikan citra fundus memenuhi ambang batas diagnostik sebelum diproses oleh model AI.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                    ),

                    const SizedBox(height: 24),

                    // Scanning Radar Graphic / Scanner Container
                    _buildScannerGraphic(passed),

                    const SizedBox(height: 24),

                    // Progressive Parameter Tiles
                    QualityIndicatorTile(
                      title: 'Indeks Ketajaman (Sharpness Laplacian)',
                      standardText: 'Ambang Batas Minimum: >= 0.40',
                      score: _isEvaluating ? 0.45 : (_result?.qualityOD.blurScore ?? 0.88),
                      threshold: 0.40,
                      isPassed: _isEvaluating ? true : passed,
                    ),

                    QualityIndicatorTile(
                      title: 'Keseimbangan Pencahayaan Kanal Hijau',
                      standardText: 'Ambang Batas Intensitas: 15% - 85%',
                      score: _isEvaluating ? 0.60 : (_result?.qualityOD.illuminationScore ?? 0.91),
                      threshold: 0.50,
                      isPassed: _isEvaluating ? true : passed,
                    ),

                    QualityIndicatorTile(
                      title: 'Cakupan Bidang Pandang Retina (FOV)',
                      standardText: 'Minimal 45° mencakup makula & diskus optikus',
                      score: _isEvaluating ? 0.70 : (_result?.qualityOD.fovScore ?? 0.94),
                      threshold: 0.70,
                      isPassed: _isEvaluating ? true : passed,
                    ),

                    const SizedBox(height: 24),

                    if (!_isEvaluating && passed)
                      CustomButton(
                        label: 'Lanjutkan ke Analisis Inferensi AI',
                        icon: Icons.psychology,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AiAnalyzingScreen(
                                result: _result!,
                                eyePosition: widget.eyePosition,
                                demoBranch: widget.demoBranch,
                                patient: widget.patient,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerGraphic(bool passed) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEvaluating) ...[
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mengevaluasi Varians Operator Laplacian...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: passed ? AppColors.statusGreenSurface : AppColors.statusRedSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  size: 44,
                  color: passed ? AppColors.statusGreen : AppColors.statusRed,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                passed ? 'Citra Lolos Uji Kendali Mutu' : 'Uji Kendali Mutu Gagal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: passed ? AppColors.statusGreen : AppColors.statusRed,
                ),
              ),
              Text(
                passed ? 'Skor komposit mutu: 92% (Optimal)' : 'Ketajaman tidak memenuhi standar',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
