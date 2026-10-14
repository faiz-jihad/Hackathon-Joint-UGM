import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/custom_button.dart';
import 'ai_analyzing_screen.dart';

class QualityFailedRetakeScreen extends StatelessWidget {
  final String eyePosition;
  final QualityCheckResult qualityResult;
  final CompleteScreeningResult? screeningResult;
  final PatientModel? patient;
  final Uint8List? imageBytes;

  const QualityFailedRetakeScreen({
    super.key,
    required this.eyePosition,
    required this.qualityResult,
    this.screeningResult,
    this.patient,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Standard Figma Retiva Top Bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  const Text(
                    'Pemeriksaan Kualitas Citra',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF246BFD),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Red Warning Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusRedSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusRed),
                      ),
                      child: const Text(
                        '05. KUALITAS BURAM — FOTO ULANG DIPERLUKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusRed,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Citra Fundus Ditolak oleh Quality Gate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Prinsip Keamanan Medis: Model AI tidak diperkenankan memproses citra yang gagal kendali mutu untuk mencegah false negative akibat lesi yang tertutup artefak.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    // Diagnostic Failure Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.statusRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.statusRedSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.blur_on, color: AppColors.statusRed, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alasan Penolakan Citra:',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      qualityResult.retakeReason ?? 'Citra Buram & Kurang Pencahayaan',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.statusRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildMetricRow('Indeks Ketajaman Laplacian', '${(qualityResult.blurScore * 100).toInt()}%', '< 40% (Gagal)'),
                          const SizedBox(height: 8),
                          _buildMetricRow('Keseimbangan Pencahayaan', '${(qualityResult.illuminationScore * 100).toInt()}%', 'Kurang Optimal'),
                          const SizedBox(height: 8),
                          _buildMetricRow('Mata yang Diperiksa', 'Oculus $eyePosition', 'Mata $eyePosition'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Corrective Guidance for Nakes
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/images/pose_menjelaskan.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Petunjuk Koreksi dari Dokter Retiva:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInstructionStep('1', 'Pastikan jarak moncong kamera fundus 1.5 - 2 cm dari kornea mata pasien.'),
                          _buildInstructionStep('2', 'Instruksikan pasien untuk memfiksasi pandangan pada titik lampu target dan tidak berkedip.'),
                          _buildInstructionStep('3', 'Sesuaikan dial diopter lensa kamera jika media refrakta pasien memiliki kelainan kacamata.'),
                          _buildInstructionStep('4', 'Lakukan pengambilan ulang foto (Retake).'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Retake Button
                    CustomButton(
                      label: 'Ambil Ulang Foto Sekarang (Retake)',
                      icon: Icons.replay,
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.pop(context); // Back to upload screen
                      },
                    ),

                    const SizedBox(height: 12),

                    // Human-in-the-Loop Clinical Override Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                      label: const Text(
                        'Tetap Teruskan ke Telaah Sp.M (Override)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _escalateToDoctorReview(context),
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

  void _escalateToDoctorReview(BuildContext context) {
    final base = screeningResult ??
        CompleteScreeningResult(
          screeningId: 'scr-override-${DateTime.now().millisecondsSinceEpoch}',
          status: 'HUMAN_REVIEW',
          qualityOD: qualityResult,
          aiResult: AIInferenceResult(
            predictedClass: 'MODERATE_DR',
            confidence: 0.65,
            rawProbabilities: {
              'NO_DR': 0.05,
              'MILD_DR': 0.20,
              'MODERATE_DR': 0.65,
              'SEVERE_DR': 0.08,
              'PROLIFERATIVE_DR': 0.02,
            },
            isHighRisk: false,
          ),
          reliability: ReliabilityResult(
            status: 'HUMAN_REVIEW',
            score: 0.65,
            requiresHumanReview: true,
            reasoning: 'Kualitas citra borderline. Nakes mengajukan telaah visual langsung oleh Dokter Spesialis Mata (Sp.M).',
          ),
          recommendation: RecommendationResult(
            summary: 'Kasus dialihkan ke antrean telaah dokter spesialis mata (Sp.M). Menunggu validasi klinis.',
            recommendedAction: 'SPECIALIST_OPHTHALMOLOGY_REVIEW',
            urgencyLevel: 'MEDIUM',
            referralIndicated: true,
            clinicalGuideline: 'Alur Human-in-the-Loop Pedoman Perdami 2024',
          ),
        );

    final overrideResult = CompleteScreeningResult(
      screeningId: base.screeningId,
      status: 'HUMAN_REVIEW',
      qualityOD: QualityCheckResult(
        passed: true,
        overallScore: qualityResult.overallScore > 0 ? qualityResult.overallScore : 0.62,
        blurScore: qualityResult.blurScore,
        illuminationScore: qualityResult.illuminationScore,
        fovScore: qualityResult.fovScore,
        retakeReason: 'MUTU_DISEPAKATI_NAKES_OVERRIDE',
        retakeInstructions: 'Nakes memilih eskalasi langsung ke telaah Sp.M.',
      ),
      aiResult: base.aiResult.predictedClass != 'UNKNOWN'
          ? base.aiResult
          : AIInferenceResult(
              predictedClass: 'MODERATE_DR',
              confidence: 0.65,
              rawProbabilities: {
                'NO_DR': 0.05,
                'MILD_DR': 0.20,
                'MODERATE_DR': 0.65,
                'SEVERE_DR': 0.08,
                'PROLIFERATIVE_DR': 0.02,
              },
              isHighRisk: false,
            ),
      reliability: ReliabilityResult(
        status: 'HUMAN_REVIEW',
        score: 0.65,
        requiresHumanReview: true,
        reasoning: 'Kualitas citra borderline. Nakes mengajukan telaah visual langsung oleh Dokter Spesialis Mata (Sp.M).',
      ),
      recommendation: base.recommendation,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalyzingScreen(
          result: overrideResult,
          eyePosition: eyePosition,
          demoBranch: 'HUMAN_REVIEW',
          patient: patient,
          imageBytes: imageBytes,
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusRed)),
            const SizedBox(width: 6),
            Text('($note)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
