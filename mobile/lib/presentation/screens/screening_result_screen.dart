import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/brand_header.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradcam_viewer_widget.dart';
import 'clinical_recommendation_screen.dart';

class ScreeningResultScreen extends StatelessWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;

  const ScreeningResultScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final severityTitle = ClinicalHelpers.getSeverityTitle(result.aiResult.predictedClass);
    final severityDesc = ClinicalHelpers.getSeverityDescription(result.aiResult.predictedClass);
    final severityColor = ClinicalHelpers.getSeverityColor(result.aiResult.predictedClass);
    final severitySurface = ClinicalHelpers.getSeveritySurfaceColor(result.aiResult.predictedClass);
    final isNoDr = result.aiResult.predictedClass == 'NO_DR';
    final isSevereOrPdr = result.aiResult.predictedClass == 'SEVERE_DR' || result.aiResult.predictedClass == 'PROLIFERATIVE_DR';

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
                    // Result Header Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusGreenSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.statusGreen),
                          ),
                          child: const Text(
                            '11. HASIL SKRINING — KEANDALAN TINGGI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.statusGreen,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Oculus ${eyePosition == "OD" ? "Dextra (OD)" : "Sinistra (OS)"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Patient Banner (Demographics & Glycaemic context)
                    if (patient != null) _buildPatientContextBanner(patient!),

                    const SizedBox(height: 12),

                    // Severity Classification Card (Figma 30:1290)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: severitySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: severityColor.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: severityColor.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
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
                                  color: severityColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Skala ICDR',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isNoDr ? 'ICD-10: E11.9' : 'ICD-10: E11.319',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: severityColor),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(result.aiResult.confidence * 100).toStringAsFixed(1)}% Keyakinan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: severityColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            severityTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: severityColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            severityDesc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Grad-CAM Explainability Heatmap Viewer (Figma 30:1511 & 36:1714)
                    const Text(
                      'Peta Atensi Grad-CAM & Bukti Citra',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GradCamViewerWidget(
                      gradcamBase64: result.gradcamImageBase64,
                      originalBase64: result.rawImageBase64,
                    ),

                    const SizedBox(height: 20),

                    // Clinical Lesion Feature Analysis Matrix (Ophthalmologist Grade)
                    _buildLesionMatrixCard(isNoDr, isSevereOrPdr),

                    const SizedBox(height: 20),

                    // 5-Class Probability Distribution Chart
                    _buildProbabilitiesCard(result.aiResult.rawProbabilities),

                    const SizedBox(height: 20),

                    // Permenkes 24/2022 & Electronic Medical Record Security Box
                    _buildRmeSecurityCard(),

                    const SizedBox(height: 24),

                    // Next Action Button
                    CustomButton(
                      label: 'Lihat Rekomendasi & Faskes Rujukan',
                      icon: Icons.assignment_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClinicalRecommendationScreen(
                              result: result,
                              eyePosition: eyePosition,
                              patient: patient,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Secondary Action: Tele-consultation Request with Sp.M
                    OutlinedButton.icon(
                      onPressed: () => _showTeleconsultationSheet(context),
                      icon: const Icon(Icons.support_agent, size: 18, color: AppColors.primaryDark),
                      label: const Text(
                        'Konsultasi Tele-Oftalmologi (Sp.M Mitra)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildPatientContextBanner(PatientModel pat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              pat.fullName.isNotEmpty ? pat.fullName[0] : 'P',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pat.fullName} (${pat.age} th) • ${pat.gender == "MALE" ? "Laki-laki" : "Perempuan"}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  'NIK: ${pat.nik} ${pat.diabetesProfile != null ? "• HbA1c: ${pat.diabetesProfile!.lastHbA1c}%" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLesionMatrixCard(bool isNoDr, bool isSevereOrPdr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.biotech, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Analisis Biomarker & Temuan Lesi Mikrovaskular',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildLesionRow(
            'Mikroaneurisma Fokal (Microaneurysms)',
            isNoDr ? 'Tidak Ditemukan' : 'Terdeteksi (Kuadran Temporal)',
            isNoDr ? AppColors.statusGreen : AppColors.statusOrange,
          ),
          _buildLesionRow(
            'Perdarahan Intraretina (Dot-blot Hemorrhages)',
            isNoDr ? 'Tidak Ditemukan' : (isSevereOrPdr ? 'Multikuadran (Aturan 4-2-1)' : 'Tersebar Fokal (< 20 titik)'),
            isNoDr ? AppColors.statusGreen : (isSevereOrPdr ? AppColors.statusRed : AppColors.statusOrange),
          ),
          _buildLesionRow(
            'Eksudat Keras / Lipid (Hard Exudates)',
            isNoDr ? 'Nihil' : 'Teramati di Perifovea',
            isNoDr ? AppColors.statusGreen : AppColors.statusYellow,
          ),
          _buildLesionRow(
            'Cotton Wool Spots (Infark Saraf)',
            isNoDr ? 'Nihil' : 'Minimal (< 2 area)',
            isNoDr ? AppColors.statusGreen : AppColors.textSecondary,
          ),
          _buildLesionRow(
            'Neovaskularisasi Papila / Retina (NVD/NVE)',
            isSevereOrPdr ? 'Risiko Tinggi (PDR)' : 'Tidak Ditemukan (Non-Proliferatif)',
            isSevereOrPdr ? AppColors.statusRed : AppColors.statusGreen,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLesionRow(String label, String status, Color color, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilitiesCard(Map<String, double> probabilities) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Distribusi Probabilitas Model 5-Kelas ICDR:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProbRow('No DR (Normal)', probabilities['NO_DR'] ?? 0.03),
          _buildProbRow('Mild NPDR (Ringan)', probabilities['MILD_DR'] ?? 0.05),
          _buildProbRow('Moderate NPDR (Sedang)', probabilities['MODERATE_DR'] ?? 0.88),
          _buildProbRow('Severe NPDR (Berat)', probabilities['SEVERE_DR'] ?? 0.03),
          _buildProbRow('PDR (Proliferatif)', probabilities['PROLIFERATIVE_DR'] ?? 0.01),
        ],
      ),
    );
  }

  Widget _buildProbRow(String label, double prob) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                '${(prob * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: prob,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                prob > 0.5 ? AppColors.primary : AppColors.textMuted,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRmeSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kesesuaian RME Permenkes RI No. 24/2022',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Integritas citra divalidasi SHA-256 dan siap sinkronisasi ke SATUSEHAT Kemenkes.',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTeleconsultationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Konsultasi Tele-Oftalmologi Sp.M',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ajukan permintaan telaah sekunder kepada Dokter Spesialis Mata konsulen yang bertugas hari ini:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryDark,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('dr. Bambang Hermanto, Sp.M(K)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      Text('RS Mata Dr. Yap • Subspesialis Vitreoretina', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text('SIP: 503/4412/SIP-D/2022', style: TextStyle(fontSize: 10, color: AppColors.primaryDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Kirim Permintaan Telaah Konsulen',
              icon: Icons.send,
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permintaan tele-oftalmologi berhasil dikirimkan ke dr. Bambang Hermanto, Sp.M(K).'),
                    backgroundColor: AppColors.statusGreen,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
