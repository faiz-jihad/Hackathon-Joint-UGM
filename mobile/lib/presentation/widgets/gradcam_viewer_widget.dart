import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradCamViewerWidget extends StatefulWidget {
  final File? originalImage;
  final Uint8List? originalBytes;
  final String? originalBase64;
  final String? gradcamBase64;

  const GradCamViewerWidget({
    super.key,
    this.originalImage,
    this.originalBytes,
    this.originalBase64,
    this.gradcamBase64,
  });

  @override
  State<GradCamViewerWidget> createState() => _GradCamViewerWidgetState();
}

class _GradCamViewerWidgetState extends State<GradCamViewerWidget> {
  bool _showHeatmap = true;
  double _heatmapOpacity = 0.75;
  bool _showAnatomicalGrid = false;
  final TransformationController _transformationController = TransformationController();

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector (Original vs Heatmap)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showHeatmap = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showHeatmap ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_showHeatmap
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Citra Asli (Original)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: !_showHeatmap ? AppColors.primaryDark : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showHeatmap = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showHeatmap ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _showHeatmap
                          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: _showHeatmap ? AppColors.statusOrange : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Peta Grad-CAM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _showHeatmap ? AppColors.primaryDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Controls Bar: Zoom Reset & Anatomical Grid Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _showAnatomicalGrid = !_showAnatomicalGrid),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _showAnatomicalGrid ? AppColors.primarySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showAnatomicalGrid ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAnatomicalGrid ? Icons.grid_on : Icons.grid_off_outlined,
                      size: 14,
                      color: _showAnatomicalGrid ? AppColors.primaryDark : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Grid Anatomi Retina',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _showAnatomicalGrid ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: _resetZoom,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_out_map, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Reset Zoom (1.0x)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Main Fundus Viewing Canvas (Interactive Zoom & Pan)
        Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildBaseFundusImage(),
                    if (_showHeatmap)
                      Opacity(
                        opacity: _heatmapOpacity,
                        child: _buildHeatmapLayer(),
                      ),
                    if (_showAnatomicalGrid)
                      _buildAnatomicalGridOverlay(),
                  ],
                ),
              ),

              // Bottom Info Badge
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showHeatmap ? Icons.bubble_chart : Icons.visibility,
                        size: 12,
                        color: _showHeatmap ? AppColors.statusOrange : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showHeatmap ? 'Layer Grad-CAM Attention Heatmap' : 'Funduskopi Retina Makula 45°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinch Zoom Instruction Hint
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, size: 12, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        'Pinch to Zoom (Hingga 4.5x)',
                        style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Heatmap Opacity Slider (when Heatmap active)
        if (_showHeatmap) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.opacity, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Transparansi Heatmap: ${(_heatmapOpacity * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.primaryDark,
                    ),
                    child: Slider(
                      value: _heatmapOpacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (val) => setState(() => _heatmapOpacity = val),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Heatmap Intensity Scale Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skala Intensitas Atensi Model AI:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  Text(
                    'Grad-CAM Weight Activation',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A), // Dark blue base
                      Color(0xFF0284C7), // Cyan medium
                      Color(0xFFF59E0B), // Yellow warm
                      Color(0xFFDC2626), // Deep red peak
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Baseline / Normal (0.0)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  Text('Fokal Moderat (0.5)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  Text('Fokus Lesi Tinggi (1.0)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.statusRed)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Mandatory Clinical Safety Notice (PRD Section)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grad-CAM menunjukkan area atensi konvolusi model AI untuk verifikasi kontekstual nakes, bukan bukti patologis definitif mandiri.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBaseFundusImage() {
    // 1. If base64 raw available
    if (widget.originalBase64 != null && widget.originalBase64!.isNotEmpty) {
      try {
        final cleanBase64 = widget.originalBase64!.contains(',')
            ? widget.originalBase64!.split(',').last
            : widget.originalBase64!;
        return Image.memory(
          base64Decode(cleanBase64),
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    // 2. If raw bytes available (Web & Native compatible)
    if (widget.originalBytes != null && widget.originalBytes!.isNotEmpty) {
      return Image.memory(
        widget.originalBytes!,
        fit: BoxFit.cover,
      );
    }

    // 3. If file available (Native only)
    if (!kIsWeb && widget.originalImage != null) {
      try {
        if (widget.originalImage!.existsSync()) {
          return Image.file(
            widget.originalImage!,
            fit: BoxFit.cover,
          );
        }
      } catch (_) {}
    }

    // 4. Fallback: stylized clinical fundus
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.15, 0.05),
          radius: 0.95,
          colors: [
            Color(0xFFB91C1C), // Vivid Retina Red
            Color(0xFF7F1D1D),
            Color(0xFF450A0A),
            Color(0xFF1E0202),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_red_eye_outlined,
              size: 44,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 8),
            Text(
              'Fundus Retina Bilateral (45° Macular Field)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapLayer() {
    // 1. If Grad-CAM base64 available
    if (widget.gradcamBase64 != null && widget.gradcamBase64!.isNotEmpty) {
      try {
        final cleanBase64 = widget.gradcamBase64!.contains(',')
            ? widget.gradcamBase64!.split(',').last
            : widget.gradcamBase64!;
        return Image.memory(
          base64Decode(cleanBase64),
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    // 2. Simulated Heatmap Radial Gradient overlay
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.25, 0.15),
          radius: 0.75,
          colors: [
            const Color(0xFFDC2626).withOpacity(0.85), // Red Hotspot
            const Color(0xFFF59E0B).withOpacity(0.65), // Yellow Warm
            const Color(0xFF0284C7).withOpacity(0.40), // Cyan Cool
            Colors.transparent,                        // Edge transparent
          ],
          stops: const [0.0, 0.45, 0.75, 1.0],
        ),
      ),
    );
  }

  Widget _buildAnatomicalGridOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Center lines
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 1,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Optic Disc Marker (Nasal side)
          Positioned(
            left: 55,
            top: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellowAccent, width: 1),
                borderRadius: BorderRadius.circular(4),
                color: Colors.black45,
              ),
              child: const Text(
                'Papila N. Optikus',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Macula / Fovea Marker (Temporal side)
          Positioned(
            right: 80,
            top: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 1),
                borderRadius: BorderRadius.circular(4),
                color: Colors.black45,
              ),
              child: const Text(
                'Makula / Fovea',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Quadrant Labels
          Positioned(
            top: 8,
            left: 8,
            child: _quadrantLabel('Kuadran Nasal Superior'),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _quadrantLabel('Kuadran Temporal Superior'),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _quadrantLabel('Kuadran Nasal Inferior'),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: _quadrantLabel('Kuadran Temporal Inferior'),
          ),
        ],
      ),
    );
  }

  Widget _quadrantLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: Colors.black38,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 7, fontWeight: FontWeight.w600),
      ),
    );
  }
}
