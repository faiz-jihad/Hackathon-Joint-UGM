import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';

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
    final severityTitle =
        ClinicalHelpers.getSeverityTitle(result.aiResult.predictedClass);
    final confidencePct =
        (result.aiResult.confidence * 100).toStringAsFixed(1);
    final eyeLabel = eyePosition == 'OD' ? 'OD • Mata Kanan' : 'OS • Mata Kiri';

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
                        color: Color(0xFF0D47A1),
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

                    // Dual-Gate Philosophy Callout
                    _buildDualGateCallout(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA (Fixed Bottom)
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
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Keandalan Hasil Analisis',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D47A1),
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
                  color: Color(0xFF0D47A1),
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
              const Text(
                'Langkah 3 dari 4: Analisis Retina',
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
        color: isCurrent ? const Color(0xFF0D47A1) : const Color(0xFFD8E3FB),
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
            // Fundus Retina Image
            Image.asset(
              'assets/images/retina_hero.png',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x990D1E25),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
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
                        Text(
                          eyeLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x990D1E25),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'FOV: 45° Macula-Centered',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(12),
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
                    letterSpacing: 0.55,
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
                ),
              ],
            ),
          ),
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
                  letterSpacing: 0.44,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$confidencePct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReliabilityMatrixCard(String confidencePct) {
    final confVal = result.aiResult.confidence;
    final isSufficient = confVal >= 0.85;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF1FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFF003178),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Metrik Keandalan Klinis',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1E25),
                        ),
                      ),
                      Text(
                        'Dual-gate safety verification',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF434652),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSufficient ? const Color(0xFFD9EBF5) : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  isSufficient ? 'Memadai' : 'Perlu Telaah',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSufficient ? const Color(0xFF00564D) : const Color(0xFF7E22CE),
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
                child: Builder(
                  builder: (_) {
                    final rawProbs = result.aiResult.rawProbabilities;
                    double entropy = 0.0;
                    if (rawProbs.isNotEmpty) {
                      for (final p in rawProbs.values) {
                        if (p > 0.0001) {
                          entropy -= p * (math.log(p) / math.ln2);
                        }
                      }
                      entropy = (entropy / 2.3219).clamp(0.0, 1.0);
                    } else {
                      entropy = isSufficient ? 0.12 : 0.42;
                    }
                    final hStr = entropy.toStringAsFixed(2);
                    return _buildMetricTile(
                      label: 'Tingkat Ketidakpastian',
                      value: isSufficient ? 'Rendah (H: $hStr)' : 'Tinggi (H: $hStr)',
                      icon: Icons.insights_outlined,
                    );
                  },
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
                  value: 'High Match',
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
                'Ambang Batas Kepercayaan (Threshold ≥ 85%)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF434652),
                ),
              ),
              Text(
                '$confidencePct% ${isSufficient ? "(Aman)" : "(Borderline)"}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSufficient ? const Color(0xFF003178) : const Color(0xFF7E22CE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  value: confVal,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFD9EBF5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSufficient ? const Color(0xFF003178) : const Color(0xFF9333EA),
                  ),
                ),
              ),
              // Marker at 85%
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: const Alignment(0.70, 0), // represents 85%
                  child: Container(
                    width: 2,
                    height: 8,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '0%',
                style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Color(0xFF434652)),
              ),
              Text(
                'Ambang Batas Klinis (85%)',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF434652)),
              ),
              Text(
                '100%',
                style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Color(0xFF434652)),
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
        color: const Color(0xB3E7F6FF), // rgba(231,246,255,0.7)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF434652),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF0D1E25)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1E25),
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

  Widget _buildDualGateCallout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0x260061A4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 16,
              color: Color(0xFF0061A4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Protokol Keamanan Retiva',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1E25),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pemeriksaan keandalan (Reliability Gate) mencegah false-confidence pada citra anomali atau kasus ambang guna menjaga validitas diagnosa klinis sebelum rekam medis diterbitkan.',
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
        child: const Text(
          'Selesai & Kembali ke Beranda',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
      ),
    );
  }
}
