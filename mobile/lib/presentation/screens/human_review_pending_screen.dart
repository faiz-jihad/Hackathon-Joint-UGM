import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';

class HumanReviewPendingScreen extends StatelessWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;

  const HumanReviewPendingScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
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
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusPurpleSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusPurple),
                      ),
                      child: const Text(
                        '11. STATUS HUMAN REVIEW — RELIABILITAS BORDERLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusPurple,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Dialihkan ke Telaah Dokter Spesialis Mata',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Prinsip Reliability-First: Model AI menahan klasifikasi definitif karena tingkat keyakinan berada pada batas ketidakpastian klinis (Uncertainty Margin).',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    // Reliability Gate Assessment Card (Figma 183:323)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.statusPurple.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusPurple.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.statusPurpleSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.psychology_alt, color: AppColors.statusPurple, size: 26),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Evaluasi Reliability Gate:',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      'RELIABILITY_LOW (Perlu Telaah)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.statusPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Keyakinan Model (Confidence)', '62.0%', '< Ambang 85%'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Margin Selisih Antarkelas', '0.12', '< Ambang 0.20'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Mata yang Diperiksa', 'Oculus $eyePosition', 'Mata $eyePosition'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Status Antrean FKRTL', 'PENDING_REVIEW', 'Antrean Telaah Dokter'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Assigned Reviewing Ophthalmologist Card
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
                              const Expanded(
                                child: Text(
                                  'Dokter Konsulen Ditugaskan:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.statusPurpleSurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Prioritas P2 (Subakut)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.statusPurple),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primarySurface,
                                child: Icon(Icons.person, color: AppColors.primaryDark, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'dr. Bambang Hermanto, Sp.M(K)',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'RS Mata Dr. Yap • Konsulen Vitreoretina',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      'SIP: 503/4412/SIP-D/2022 • STR: 3311100223198001',
                                      style: TextStyle(fontSize: 10, color: AppColors.textMuted.withOpacity(0.8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3-Stage Tele-ophthalmology Clinical Flow Tracker
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
                          const Text(
                            'Alur Prosedur Human Review (Perdami 2024):',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 14),
                          _buildStepTracker(1, 'Citra Fundus Diterima', 'Audit hash citra terekam di RME.', true),
                          _buildStepTracker(2, 'Telaah Split-Viewer Dokter', 'Dokter konsulen membandingkan citra & Grad-CAM.', true, isCurrent: true),
                          _buildStepTracker(3, 'Penerbitan Rekomendasi Terverifikasi', 'Diagnosis definitif & SPK rujukan disahkan TTE.', false, isLast: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Return Button
                    CustomButton(
                      label: 'Kembali ke Beranda Skrining',
                      icon: Icons.home_outlined,
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
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

  Widget _buildStepTracker(int step, String title, String subtitle, bool isCompleted, {bool isCurrent = false, bool isLast = false}) {
    final color = isCompleted
        ? (isCurrent ? AppColors.statusPurple : AppColors.statusGreen)
        : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? color.withOpacity(0.15) : AppColors.divider,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: Text(
                  step.toString(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? color.withOpacity(0.4) : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? AppColors.statusPurple : AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, String note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusPurple)),
            const SizedBox(width: 6),
            Text('($note)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}
