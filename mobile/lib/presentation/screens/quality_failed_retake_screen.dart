import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../widgets/notification_bell_widget.dart';

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

  String get _eyeLabel {
    final pos = eyePosition.toUpperCase().trim();
    if (pos == 'OD') return 'Mata Kanan (OD)';
    if (pos == 'OS') return 'Mata Kiri (OS)';
    return 'Mata $eyePosition';
  }

  String get _statusHeaderTitle {
    final isDark = qualityResult.illuminationScore < 0.60;
    final isBlur = qualityResult.blurScore < 0.60;
    if (isDark && isBlur) {
      return 'Foto Kurang Jelas & Terlalu Gelap';
    } else if (isDark) {
      return 'Pencahayaan Foto Kurang Terang';
    } else if (isBlur) {
      return 'Foto Mengalami Buram / Tidak Fokus';
    }
    return 'Kualitas Foto Belum Memadai';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Standard Professional Retiva Top Bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 34,
                      height: 34,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evaluasi Kualitas Foto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Pemeriksaan standar medis retina',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const NotificationBellWidget(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Status Soft
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 5),
                          Text(
                            'PENGAMBILAN ULANG DIPERLUKAN',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _statusHeaderTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Untuk menjamin akurasi evaluasi retina dan mencegah kesalahan diagnosis medis, foto retina perlu diambil ulang dengan pencahayaan dan fokus yang optimal.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Foto Preview Card (if available)
                    if (imageBytes != null) ...[
                      Container(
                        width: double.infinity,
                        height: 190,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Dark gradient overlay at bottom
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xB3000000)],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC000000),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.remove_red_eye_rounded, size: 13, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      _eyeLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Foto saat ini belum memenuhi kriteria ketajaman/cahaya',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Parameter Kualitas Citra (Gauges Card)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Color(0xFF246BFD),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pemeriksaan Parameter Mutu',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Standar minimal setiap parameter adalah 60%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // Parameter 1: Ketajaman & Fokus
                          _buildQualityProgressRow(
                            title: 'Fokus & Ketajaman Foto',
                            score: qualityResult.blurScore,
                            threshold: 0.60,
                            icon: Icons.filter_center_focus_rounded,
                            failureLabel: 'Kurang Fokus / Buram',
                            passLabel: 'Fokus Optimal',
                          ),

                          const SizedBox(height: 14),

                          // Parameter 2: Pencahayaan
                          _buildQualityProgressRow(
                            title: 'Tingkat Pencahayaan',
                            score: qualityResult.illuminationScore,
                            threshold: 0.60,
                            icon: Icons.light_mode_rounded,
                            failureLabel: 'Terlalu Gelap',
                            passLabel: 'Pencahayaan Pas',
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),

                          // Info Mata yang Diperiksa
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.remove_red_eye_outlined, size: 15, color: Color(0xFF64748B)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mata yang Diperiksa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: Text(
                                  _eyeLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Doctor Guidance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Panduan Pengambilan Ulang',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Tips dokter agar foto langsung berhasil',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildTipItem(
                            icon: Icons.camera_alt_outlined,
                            title: 'Jarak & Posisi Kamera Stabil',
                            desc: 'Jaga jarak moncong lensa kamera sekitar 1.5 - 2 cm tegak lurus di depan mata pasien.',
                          ),
                          _buildTipItem(
                            icon: Icons.visibility_outlined,
                            title: 'Fiksasi Pandangan Pasien',
                            desc: 'Minta pasien melihat lurus ke titik target lampu pemandu dan tahan kedipan selama beberapa detik.',
                          ),
                          _buildTipItem(
                            icon: Icons.wb_sunny_outlined,
                            title: 'Pencahayaan Ruangan Seimbang',
                            desc: 'Pastikan ruangan dalam kondisi cukup redup agar pupil melebar alami tanpa pantulan kilau.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Primary Action Button (Retake)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Kembali untuk memotret ulang
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text(
                          'Ambil Ulang Foto Sekarang',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Secondary Action Button (Cancel / Back)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batal & Kembali',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityProgressRow({
    required String title,
    required double score,
    required double threshold,
    required IconData icon,
    required String failureLabel,
    required String passLabel,
  }) {
    final isFail = score < threshold;
    final percent = (score * 100).toInt().clamp(0, 100);
    final color = isFail ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgColor = isFail ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final borderColor = isFail ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                isFail ? failureLabel : passLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: score.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF246BFD)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
