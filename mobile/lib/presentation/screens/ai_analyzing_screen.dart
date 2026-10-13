import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import 'screening_result_screen.dart';
import 'human_review_pending_screen.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final String demoBranch;
  final PatientModel? patient;

  const AiAnalyzingScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    required this.demoBranch,
    this.patient,
  });

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen> {
  int _currentStep = 0;
  final List<String> _analysisSteps = [
    'Ekstraksi Fitur Konvolusi (EfficientNet-B3)...',
    'Segmentasi Mikroaneurisma & Perdarahan Intraretina...',
    'Komputasi Distribusi Probabilitas 5-Kelas ICDR...',
    'Evaluasi Ambang Batas Keandalan (Reliability Gate)...',
    'Inferensi Medis Selesai.',
  ];

  @override
  void initState() {
    super.initState();
    _runAnalysisSteps();
  }

  Future<void> _runAnalysisSteps() async {
    for (int i = 0; i < _analysisSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (mounted) {
        setState(() => _currentStep = i);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      if (widget.result.reliability.requiresHumanReview || widget.demoBranch == 'HUMAN_REVIEW') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HumanReviewPendingScreen(
              result: widget.result,
              eyePosition: widget.eyePosition,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScreeningResultScreen(
              result: widget.result,
              eyePosition: widget.eyePosition,
              patient: widget.patient,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const BrandHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Processing Aperture Icon with pulse
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight, width: 2),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Menganalisis Citra Retina Fundus',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Model: EfficientNet-B3 (PyTorch / ONNX) • Input: 300x300 RGB\nEvaluasi Bilateral Mata ${widget.eyePosition}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Progressive Step List
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_analysisSteps.length, (index) {
                          final isDone = index < _currentStep;
                          final isCurrent = index == _currentStep;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : (isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                  size: 18,
                                  color: isDone
                                      ? AppColors.statusGreen
                                      : (isCurrent ? AppColors.primary : AppColors.textMuted),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _analysisSteps[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      color: isCurrent
                                          ? AppColors.primaryDark
                                          : (isDone ? AppColors.textPrimary : AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
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
}
