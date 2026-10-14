import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'retina_insight_screen.dart';

class ScreeningResultScreen extends StatelessWidget {
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
        return 2; // Default moderate as in reference frame
    }
  }

  String _getSeverityShortName(int index) {
    switch (index) {
      case 0:
        return 'NO DR';
      case 1:
        return 'MILD';
      case 2:
        return 'MODERATE';
      case 3:
        return 'SEVERE';
      case 4:
        return 'PDR';
      default:
        return 'MODERATE';
    }
  }

  String _getClinicalDescription(int index) {
    switch (index) {
      case 0:
        return 'Tidak teridentifikasi tanda-tanda retinopati diabetik pada citra retina. Struktur fovea dan mikrovaskular tampak baik dalam batas normal.';
      case 1:
        return 'Teridentifikasi mikroaneurisma minimal pada citra retina tanpa eksudat luas. Disarankan skrining berkala 6-12 bulan sekali.';
      case 2:
        return 'Teridentifikasi indikasi retinopati diabetik tingkat sedang pada citra retina. Terdapat tanda awal mikroaneurisma & eksudat halus.';
      case 3:
        return 'Teridentifikasi perdarahan intraretina luas (>20 per kuadran) dan kelainan mikrovaskular signifikan. Memerlukan evaluasi spesialis mata segera.';
      case 4:
        return 'Teridentifikasi neovaskularisasi aktif atau perdarahan preretina/vitreus berisiko tinggi. Memerlukan penanganan segera dokter spesialis mata.';
      default:
        return 'Teridentifikasi indikasi retinopati diabetik tingkat sedang pada citra retina. Terdapat tanda awal mikroaneurisma & eksudat halus.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityIndex = _getSeverityIndex(result.aiResult.predictedClass);
    final severityName = _getSeverityShortName(severityIndex);
    final severityFullTitle = ClinicalHelpers.getSeverityTitle(result.aiResult.predictedClass);
    final confidencePct = (result.aiResult.confidence * 100).toStringAsFixed(1);
    final scanNumber = patient != null && patient!.nik.length >= 3
        ? patient!.nik.substring(patient!.nik.length - 3)
        : result.screeningId.length >= 3
            ? result.screeningId.substring(result.screeningId.length - 3)
            : '001';
    final eyeLabel = eyePosition == 'OD' ? 'Mata Kanan (OD)' : 'Mata Kiri (OS)';

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper Breadcrumb (Langkah 4 dari 4)
                    _buildStepperBreadcrumb(),

                    const SizedBox(height: 16),

                    // Heading 3
                    const Text(
                      'Hasil Pemeriksaan Retina',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF246BFD),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main Result Card
                    _buildMainResultCard(
                      severityName: severityName,
                      severityFullTitle: severityFullTitle,
                      confidencePct: confidencePct,
                      severityIndex: severityIndex,
                    ),

                    const SizedBox(height: 12),

                    // Quick Retina Image Thumbnail Strip
                    _buildQuickThumbnailStrip(scanNumber, eyeLabel),

                    const SizedBox(height: 12),

                    // Medical Disclaimer Card (Consistent Blue Medical Palette)
                    _buildMedicalDisclaimerCard(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom CTA Actions (Fixed Bottom)
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
            'Hasil Pemeriksaan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF246BFD),
            ),
          ),
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
          Row(
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
                    '4',
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
              const Text(
                'Langkah 4 dari 4: Hasil Pemeriksaan',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003178),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildStepIndicator(isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isCurrent: true),
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

  Widget _buildMainResultCard({
    required String severityName,
    required String severityFullTitle,
    required String confidencePct,
    required int severityIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: DETEKSI AI vs Confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETEKSI AI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.55,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      severityFullTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Confidence',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$confidencePct%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Diagnostic Description
          Text(
            _getClinicalDescription(severityIndex),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          const SizedBox(height: 16),

          // Visual Severity Scale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TINGKAT KEPARAHAN (SEVERITY)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                severityName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF246BFD),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 5-bar severity meter
          Row(
            children: List.generate(5, (index) {
              final isCurrent = index == severityIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 5 : 0),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF246BFD) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: isCurrent
                        ? const [
                            BoxShadow(
                              color: Color(0xFF93C5FD),
                              spreadRadius: 2.5,
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.white,
                              spreadRadius: 1,
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // Severity labels below bars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSeverityLabel('No DR', isActive: severityIndex == 0),
              _buildSeverityLabel('Mild', isActive: severityIndex == 1),
              _buildSeverityLabel('Moderate', isActive: severityIndex == 2),
              _buildSeverityLabel('Severe', isActive: severityIndex == 3),
              _buildSeverityLabel('PDR', isActive: severityIndex == 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityLabel(String label, {required bool isActive}) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isActive ? const Color(0xFF246BFD) : const Color(0xFF434652),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildQuickThumbnailStrip(String scanNumber, String eyeLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // 48x48 rounded thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: originalBytes != null
                  ? Image.memory(originalBytes!, fit: BoxFit.cover)
                  : Image.asset(
                      'assets/images/thumbnail_retina_sample.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/fundus_thumbnail.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Citra Fundus #$scanNumber',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$eyeLabel • Kualitas ${(result.qualityOD.overallScore * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Tervalidasi badge
          Row(
            children: const [
              Text(
                'Tervalidasi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2196F3),
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(0xFF2196F3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xB3E3F2FD), // rgba(227,242,253,0.7)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4D2196F3)), // rgba(33,150,243,0.3)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xFF246BFD),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Medis:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Hasil ini merupakan dukungan skrining berbasis AI dan bukan diagnosis medis. Keputusan klinis tetap berada pada dokter spesialis mata.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF434652),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40246BFD),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RetinaInsightScreen(
                  result: result,
                  eyePosition: eyePosition,
                  patient: patient,
                  originalBytes: originalBytes,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF246BFD),
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Insight Retina',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
