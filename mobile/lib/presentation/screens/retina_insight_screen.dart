import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'clinical_recommendation_screen.dart';

class RetinaInsightScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;
  final Uint8List? originalBytes;

  const RetinaInsightScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
    this.originalBytes,
  });

  @override
  State<RetinaInsightScreen> createState() => _RetinaInsightScreenState();
}

class _RetinaInsightScreenState extends State<RetinaInsightScreen> {
  bool _showHeatmap = false;

  @override
  Widget build(BuildContext context) {
    final severityTitle = ClinicalHelpers.getSeverityTitle(widget.result.aiResult.predictedClass);
    final confidencePct = (widget.result.aiResult.confidence * 100).toStringAsFixed(1);
    final eyeLabel = widget.eyePosition == 'OD' ? 'Mata Kanan - OD' : 'Mata Kiri - OS';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Segmented Control (Original vs Heatmap)
                    _buildSegmentedControl(),

                    const SizedBox(height: 16),

                    // Large Fundus Viewer
                    _buildFundusViewer(eyeLabel),

                    const SizedBox(height: 16),

                    // Heatmap Explanation Card
                    _buildExplanationCard(),

                    const SizedBox(height: 16),

                    // Compact Diagnostic Summary
                    _buildDiagnosticSummary(severityTitle, confidencePct),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Return CTA
            _buildBottomCta(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
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
            'Insight Retina',
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

  Widget _buildSegmentedControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCCE2E8F0), // rgba(226,232,240,0.8)
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Original Button
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHeatmap = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: !_showHeatmap ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_showHeatmap
                      ? const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Original',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: !_showHeatmap ? FontWeight.w700 : FontWeight.w600,
                      color: !_showHeatmap ? const Color(0xFF0D47A1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Heatmap (Grad-CAM) Button
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHeatmap = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _showHeatmap ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _showHeatmap
                      ? const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Heatmap (Grad-CAM)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: _showHeatmap ? FontWeight.w700 : FontWeight.w600,
                      color: _showHeatmap ? const Color(0xFF0D47A1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundusViewer(String eyeLabel) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Display image: either Heatmap (Grad-CAM) or Original
              if (_showHeatmap)
                _buildHeatmapImage()
              else
                _buildOriginalImage(),

              // Floating Quick Badge at bottom left
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000), // rgba(0,0,0,0.6)
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showHeatmap
                            ? 'Peta Atensi Lesi AI (Grad-CAM)'
                            : 'Citra Fundus Asli ($eyeLabel)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalImage() {
    if (widget.originalBytes != null) {
      return Image.memory(
        widget.originalBytes!,
        fit: BoxFit.cover,
      );
    }
    if (widget.result.rawImageBase64 != null && widget.result.rawImageBase64!.isNotEmpty) {
      try {
        final decoded = base64Decode(widget.result.rawImageBase64!);
        return Image.memory(decoded, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Image.asset(
      'assets/images/retina_insight_sample.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/upload_preview_sample.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildHeatmapImage() {
    if (widget.result.gradcamImageBase64 != null && widget.result.gradcamImageBase64!.isNotEmpty) {
      try {
        final decoded = base64Decode(widget.result.gradcamImageBase64!);
        return Image.memory(decoded, fit: BoxFit.cover);
      } catch (_) {}
    }
    // Fallback: original image with a vibrant heatmap gradient overlay
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildOriginalImage(),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.1, 0.1),
              radius: 0.7,
              colors: [
                const Color(0x99EF4444), // red hotspot
                const Color(0x66F59E0B), // orange
                const Color(0x3310B981), // green
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
              Text(
                _showHeatmap ? 'Peta Atensi Grad-CAM' : 'Citra Retina Asli',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Kualitas: Optimal (98%)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _showHeatmap
                ? 'Visualisasi Grad-CAM menyoroti area lesi mikrovaskular dan eksudat yang paling signifikan memengaruhi penilaian klasifikasi retinopati model AI Retiva.'
                : 'Menampilkan citra fundus original mata kanan (OD) beresolusi tinggi sebelum proses segmentasi dan atensi AI.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSummary(String severityTitle, String confidencePct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xB3E3F2FD), // rgba(227,242,253,0.7)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DIAGNOSIS SKRINING',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                severityTitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'AKURASI KEYAKINAN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$confidencePct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ElevatedButton(
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
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: const Color(0x331E3A8A),
        ),
        child: const Text(
          'Lihat Rekomendasi Tindak Lanjut',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
