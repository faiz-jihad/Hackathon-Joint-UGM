import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import '../../core/constants/app_colors.dart';
import 'clinical_recommendation_screen.dart';
import '../widgets/notification_bell_widget.dart';

/// HumanReviewResultScreen — Layar Hasil Human Review Resmi Dokter Spesialis Mata (Sp.M)
/// Desain persis sesuai spesifikasi UI/UX Retiva:
/// - Verifikasi Tenaga Kesehatan Pill
/// - Profil Dokter Penelaah & Catatan Klinis
/// - Citra Fundus Interaktif dengan Overlay Makula & Mikrovaskular
/// - Hasil Klasifikasi Triage
/// - Rencana Lanjutan Dokter
/// - CTA Lihat Rekomendasi Tindak Lanjut
/// HumanReviewResultScreen — Layar Hasil Human Review Resmi Dokter Spesialis Mata (Sp.M)
/// Desain persis sesuai spesifikasi UI/UX Retiva:
/// - Verifikasi Tenaga Kesehatan Pill
/// - 2 Kondisi Keputusan Ajudikasi Dokter (Konfirmasi AI vs Koreksi/Override)
/// - Profil Dokter Penelaah & Catatan Klinis
/// - Citra Fundus Interaktif dengan Overlay Makula & Mikrovaskular
/// - Hasil Klasifikasi Triage Dinamis Berdasarkan Keputusan Akhir Dokter
/// - Rencana Lanjutan Dokter Adaptif
/// - CTA Lihat Rekomendasi Tindak Lanjut (terintegrasi dengan grading akhir)
class HumanReviewResultScreen extends StatelessWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final PatientModel? patient;
  final Uint8List? imageBytes;
  final File? imageFile;
  final String doctorName;
  final String doctorRole;
  final String? doctorSip;
  final String? doctorNotes;
  final DateTime? reviewedAt;
  final String? adjudicationAction;
  final String? finalGrade;

  const HumanReviewResultScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
    this.imageBytes,
    this.imageFile,
    this.doctorName = 'dr. Yunani Setyandriana, Sp.M',
    this.doctorRole = 'Spesialis Vitreoretina & Oftalmologi',
    this.doctorSip = 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)',
    this.doctorNotes,
    this.reviewedAt,
    this.adjudicationAction,
    this.finalGrade,
  });

  String get _eyeCode => eyePosition.toUpperCase() == 'OS' ? 'OS' : 'OD';
  String get _eyeName => _eyeCode == 'OS' ? 'Mata Kiri' : 'Mata Kanan';

  String _formatTimestamp() {
    if (reviewedAt == null) {
      return 'Hari ini,\n09:42';
    }
    final hour = reviewedAt!.hour.toString().padLeft(2, '0');
    final minute = reviewedAt!.minute.toString().padLeft(2, '0');
    return 'Hari ini,\n$hour:$minute';
  }

  int _parseGradeToLevel(String rawGrade) {
    final raw = rawGrade.toUpperCase();
    if (raw.contains('NO_DR') || raw.contains('NORMAL')) return 0;
    if (raw.contains('MILD')) return 1;
    if (raw.contains('MODERATE')) return 2;
    if (raw.contains('SEVERE')) return 3;
    if (raw.contains('PROLIFERATIVE') || raw.contains('PDR')) return 4;
    return 1;
  }

  int get _aiOriginalLevel => _parseGradeToLevel(result.aiResult.predictedClass);

  int get _severityLevel {
    if (finalGrade != null && finalGrade!.trim().isNotEmpty) {
      return _parseGradeToLevel(finalGrade!);
    }
    return _aiOriginalLevel;
  }

  bool get _isOverride {
    if (adjudicationAction == 'OVERRIDE') return true;
    if (finalGrade != null && finalGrade!.trim().isNotEmpty && _severityLevel != _aiOriginalLevel) {
      return true;
    }
    return false;
  }

  String _getLevelTitle(int lvl) {
    switch (lvl) {
      case 0:
        return 'No DR (Normal)';
      case 1:
        return 'Mild (Ringan)';
      case 2:
        return 'Moderate (Sedang)';
      case 3:
        return 'Severe (Berat)';
      case 4:
        return 'PDR (Proliferatif)';
      default:
        return 'Mild (Ringan)';
    }
  }

  String _getLevelSubtitle(int lvl) {
    switch (lvl) {
      case 0:
        return 'Tidak Ada Retinopati';
      case 1:
        return 'NPDR Stadium Awal';
      case 2:
        return 'NPDR Stadium Lanjut';
      case 3:
        return 'NPDR Stadium Berat';
      case 4:
        return 'Stadium Proliferatif';
      default:
        return 'NPDR Stadium Awal';
    }
  }

  String _getLevelDescription(int lvl) {
    switch (lvl) {
      case 0:
        return 'Tidak ditemukan tanda retinopati diabetik pada fundus. Kondisi retina sehat dan disarankan pemeriksaan rutin berkala.';
      case 1:
        return 'Terdapat perubahan vaskular ringan di area retina perifer. Kondisi ini stabil dan memerlukan pemantauan berkala guna mencegah progresi lanjutan.';
      case 2:
        return 'Dijumpai mikroaneurisma multipel, perdarahan intraretina, dan/atau hard exudate. Memerlukan penanganan klinis lebih intensif.';
      case 3:
        return 'Perubahan mikrovaskular berat dengan risiko tinggi progresi ke neovaskularisasi. Rujukan oftalmologi segera diperlukan.';
      case 4:
        return 'Neovaskularisasi aktif atau perdarahan preretina/vitreus terdeteksi. Tindakan rujukan segera (urgent) diperlukan.';
      default:
        return 'Terdapat perubahan vaskular ringan di area retina perifer. Kondisi ini stabil dan memerlukan pemantauan berkala guna mencegah progresi lanjutan.';
    }
  }

  String get _severityTitle => _getLevelTitle(_severityLevel);
  String get _severitySubtitle => _getLevelSubtitle(_severityLevel);
  String get _severityDescription => _getLevelDescription(_severityLevel);

  String _getClassStringFromLevel(int lvl) {
    switch (lvl) {
      case 0:
        return 'NO_DR';
      case 1:
        return 'MILD_DR';
      case 2:
        return 'MODERATE_DR';
      case 3:
        return 'SEVERE_DR';
      case 4:
        return 'PROLIFERATIVE_DR';
      default:
        return 'MODERATE_DR';
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes = imageBytes;
    if (bytes == null && imageFile != null) {
      try {
        bytes = imageFile!.readAsBytesSync();
      } catch (_) {}
    }

    final notesText = (doctorNotes != null && doctorNotes!.trim().isNotEmpty)
        ? doctorNotes!
        : '“Berdasarkan telaah klinis pada foto fundus $_eyeCode, gambaran mikrovaskular konsisten dengan derajat ringan (Mild NPDR). Tidak dijumpai tanda edema makula klinis signifikan saat ini.”';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
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
                  const SizedBox(width: 14),
                  const Text(
                    'Hasil Human Review',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  const NotificationBellWidget(),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Badge Pill (Dihasilkan setelah review tenaga kesehatan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: Color(0xFF246BFD),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Dihasilkan setelah review tenaga kesehatan',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card Keputusan Ajudikasi Dokter: 2 Kondisi (Konfirmasi AI vs Koreksi/Override)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isOverride ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isOverride ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _isOverride ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isOverride ? Icons.published_with_changes_rounded : Icons.check_circle_rounded,
                              size: 20,
                              color: _isOverride ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _isOverride
                                            ? 'Koreksi Klinis Dokter (Override)'
                                            : 'Konfirmasi Temuan AI',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: _isOverride ? const Color(0xFF92400E) : const Color(0xFF166534),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isOverride ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _isOverride ? 'Koreksi Tingkat' : 'Sesuai AI',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _isOverride ? const Color(0xFF78350F) : const Color(0xFF14532D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isOverride
                                      ? 'Berdasarkan telaah klinis lesi retina, dokter mengoreksi klasifikasi dari AI (${_getLevelTitle(_aiOriginalLevel)}) menjadi $_severityTitle.'
                                      : 'Dokter spesialis mata menyetujui analisis model AI ($_severityTitle) dan menerbitkan rekomendasi rujukan.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: _isOverride ? const Color(0xFF78350F) : const Color(0xFF166534),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 1: Doctor Profile & Catatan Dokter Penelaah
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Profile Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDBEAFE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.medical_services_rounded,
                                      color: Color(0xFF246BFD),
                                      size: 22,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF246BFD),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctorName,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      doctorRole,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      doctorSip ?? 'SIP: 449/SIP-M/2023',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatTimestamp(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Inner Note Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Catatan Dokter Penelaah:',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notesText,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card 2: Citra Fundus Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.remove_red_eye_rounded,
                              size: 18,
                              color: Color(0xFF246BFD),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Citra Fundus $_eyeCode',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '($_eyeName)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Terverifikasi AI dan Dokter',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Interactive Fundus Image Container
                    Container(
                      width: double.infinity,
                      height: 230,
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
                            child: bytes != null
                                ? Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/analisis_fundus_sample.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/retina_hero.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),

                          // Top-Left Floating Badge: Mikrovaskular Perifer
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 8, color: Color(0xFF246BFD)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mikrovaskular Perifer',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Center Lesion Highlight Marker
                          Center(
                            child: Transform.translate(
                              offset: const Offset(-25, 30),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0x40246BFD),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF246BFD), width: 1.5),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF246BFD),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom Floating Pill: Fokus Makula & Resolusi Optimum
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.96),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        size: 15,
                                        color: Color(0xFF246BFD),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fokus Makula: Intak & Stabil',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Resolusi Optimum',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card 3: Hasil Klasifikasi Triage
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'HASIL KLASIFIKASI TRIAGE',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _isOverride ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Tingkat $_severityLevel${_isOverride ? ' • Override' : ''}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _isOverride ? const Color(0xFFB45309) : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _severityTitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _severitySubtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _severityDescription,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Card 4: Rencana Lanjutan Dokter
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in_rounded,
                                size: 18,
                                color: Color(0xFF246BFD),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Rencana Lanjutan Dokter',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Dynamic Action Items Based on Final Severity Level
                          if (_severityLevel == 0) ...[
                            _buildPlanItem(
                              icon: Icons.calendar_month_rounded,
                              title: 'Skrining Rutin Tahunan di FKTP',
                              desc: 'Pemeriksaan foto fundus ulang terjadwal setiap 12 bulan di Puskesmas atau faskes pertama.',
                            ),
                            const SizedBox(height: 10),
                            _buildPlanItem(
                              icon: Icons.monitor_heart_outlined,
                              title: 'Pemeliharaan Pola Hidup Sehat',
                              desc: 'Pertahankan kadar gula darah normal dan lakukan kontrol rutin kesehatan metabolik.',
                            ),
                          ] else if (_severityLevel == 1) ...[
                            _buildPlanItem(
                              icon: Icons.calendar_month_rounded,
                              title: 'Evaluasi Berkala 6–12 Bulan di FKTP',
                              desc: 'Jadwalkan pemeriksaan funduskopi berkala dalam 6–12 bulan guna observasi perbandingan lesi mikroaneurisma.',
                            ),
                            const SizedBox(height: 10),
                            _buildPlanItem(
                              icon: Icons.show_chart_rounded,
                              title: 'Kontrol Glikemik & Vaskular Intensif',
                              desc: 'Jaga kestabilan glikemik (HbA1c < 7.0%) dan tekanan darah harian (< 130/80 mmHg) secara teratur.',
                            ),
                          ] else if (_severityLevel == 2) ...[
                            _buildPlanItem(
                              icon: Icons.local_hospital_outlined,
                              title: 'Rujukan Dokter Spesialis Mata (Sp.M)',
                              desc: 'Konsultasi rujukan poli mata dalam 1–3 bulan untuk evaluasi funduskopi mendalam dan pemetaan ketebalan makula dengan OCT.',
                            ),
                            const SizedBox(height: 10),
                            _buildPlanItem(
                              icon: Icons.visibility_outlined,
                              title: 'Monitoring Lesi & Faktor Risiko',
                              desc: 'Evaluasi ketat perdarahan mikro intraretina dan eksudat guna mencegah edema makula signifikan.',
                            ),
                          ] else if (_severityLevel == 3) ...[
                            _buildPlanItem(
                              icon: Icons.emergency_outlined,
                              title: 'Rujukan Cepat Vitreoretina (2–4 Minggu)',
                              desc: 'Rujukan cepat ke faskes sekunder/tersier dengan fasilitas Vitreoretina untuk evaluasi profilaksis laser fotokoagulasi (PRP).',
                            ),
                            const SizedBox(height: 10),
                            _buildPlanItem(
                              icon: Icons.security_rounded,
                              title: 'Proteksi Ketat Penglihatan',
                              desc: 'Waspadai penurunan visus mendadak atau floaters dan lakukan kontrol metabolik ketat.',
                            ),
                          ] else ...[
                            _buildPlanItem(
                              icon: Icons.medical_services_rounded,
                              title: 'Rujukan Cito Darurat Vitreoretina (< 7 Hari)',
                              desc: 'Tindakan segera laser panretinal (PRP) dan terapi anti-VEGF intraokular untuk mencegah kebutaan.',
                            ),
                            const SizedBox(height: 10),
                            _buildPlanItem(
                              icon: Icons.warning_amber_rounded,
                              title: 'Tindakan Preventif Kebutaan',
                              desc: 'Hindari aktivitas berat/trauma mata dan segera ke IGD spesialis mata terdekat.',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Disclaimer Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hasil telaah ini melengkapi proses penapisan dan bukan pengganti tindakan operasi atau intervensi medis invasif darurat.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Action Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final effectiveClass = _getClassStringFromLevel(_severityLevel);
                    final updatedResult = CompleteScreeningResult(
                      screeningId: result.screeningId,
                      status: 'HUMAN_REVIEWED',
                      qualityOD: result.qualityOD,
                      qualityOS: result.qualityOS,
                      aiResult: AIInferenceResult(
                        predictedClass: effectiveClass,
                        confidence: result.aiResult.confidence,
                        rawProbabilities: result.aiResult.rawProbabilities,
                        isHighRisk: _severityLevel >= 2,
                      ),
                      reliability: result.reliability,
                      recommendation: RecommendationResult(
                        summary: _severityDescription,
                        recommendedAction: _severityLevel >= 2
                            ? 'SPECIALIST_OPHTHALMOLOGY_REFERRAL'
                            : 'PRIMARY_CARE_MONITORING',
                        urgencyLevel: _severityLevel >= 3
                            ? 'HIGH'
                            : (_severityLevel == 2 ? 'MEDIUM' : 'LOW'),
                        referralIndicated: _severityLevel >= 2,
                        clinicalGuideline: 'Pedoman Konsensus Perdami & ADA 2024',
                      ),
                      gradcamImageBase64: result.gradcamImageBase64,
                      rawImageBase64: result.rawImageBase64,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClinicalRecommendationScreen(
                          result: updatedResult,
                          eyePosition: eyePosition,
                          patient: patient,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Lihat Rekomendasi Tindak Lanjut',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
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
                    fontFamily: 'Inter',
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

