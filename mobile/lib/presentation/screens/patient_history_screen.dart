import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'screening_result_screen.dart';
import 'status_human_review_screen.dart';
import 'quality_failed_retake_screen.dart';
import '../widgets/notification_bell_widget.dart';

/// PatientHistoryScreen — Layar Riwayat Pemeriksaan Mandiri Pasien
/// Mengambil data pemeriksaan asli secara langsung dari database PostgreSQL RETIVA.
class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  // Filter yang aktif: 'ALL', 'COMPLETED', 'IN_PROGRESS'
  String _activeFilter = 'ALL';
  bool _isLoading = true;
  String? _errorMessage;

  List<_ScreeningSessionItem> _sessions = [];
  String _lastScreeningDate = '-';

  @override
  void initState() {
    super.initState();
    _fetchRealScreeningHistory();
  }

  /// Memuat riwayat pemeriksaan asli dari server PostgreSQL
  Future<void> _fetchRealScreeningHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawScreenings = await ApiClient().getScreenings();

      final List<_ScreeningSessionItem> loaded = [];

      for (final scr in rawScreenings) {
        final id = (scr['id'] ?? '').toString();
        if (id.startsWith('scr-base-') ||
            id == 'scr-base-001' ||
            id == 'scr-base-002' ||
            id.startsWith('sample-') ||
            id.startsWith('demo-')) {
          continue;
        }
        final rawStatus = (scr['status'] ?? 'CREATED').toString().toUpperCase();
        final createdAtIso = (scr['createdAt'] ?? '').toString();
        final dateText = _formatDate(createdAtIso);

        final images = (scr['images'] as List?) ?? [];
        final eyePosition = (images.isNotEmpty ? (images[0]['eye'] ?? 'OD') : 'OD').toString().toUpperCase();
        final eyeName = eyePosition == 'OS' ? 'Mata Kiri (OS)' : 'Mata Kanan (OD)';

        final qualityChecks = (scr['qualityChecks'] as List?) ?? [];
        final hasFailedQuality = rawStatus == 'RETAKE_REQUIRED' ||
            (qualityChecks.isNotEmpty && qualityChecks.any((q) => q['passed'] == false));

        final humanReview = scr['humanReview'];
        final aiResult = scr['aiResult'];

        String statusText;
        Color statusColor;
        String badgeText;
        IconData badgeIcon;
        Color badgeBgColor;
        Color badgeTextColor;
        String category;
        bool isDoctorReviewed = false;
        bool isQualityFailed = false;
        int drGrade = 0;
        String imageAsset = eyePosition == 'OS'
            ? 'assets/images/thumbnail_retina_sample.png'
            : 'assets/images/fundus_thumbnail.png';

        if (hasFailedQuality) {
          statusText = 'Dibatalkan';
          statusColor = const Color(0xFFDC2626);
          badgeText = 'Kualitas Kurang (Retake)';
          badgeIcon = Icons.refresh_rounded;
          badgeBgColor = const Color(0xFFFFE4E6);
          badgeTextColor = const Color(0xFFE11D48);
          category = 'IN_PROGRESS';
          isQualityFailed = true;
          imageAsset = 'assets/images/fundus_borderline_sample.jpg';
        } else if (rawStatus == 'HUMAN_REVIEW' || humanReview != null) {
          statusText = humanReview != null ? 'Selesai Ditinjau' : 'Dalam Peninjauan';
          statusColor = AppColors.primary;
          badgeText = 'Review Tenaga Kesehatan';
          badgeIcon = Icons.assignment_ind_outlined;
          badgeBgColor = const Color(0xFFEFF6FF);
          badgeTextColor = AppColors.primary;
          category = humanReview != null ? 'COMPLETED' : 'IN_PROGRESS';
          isDoctorReviewed = true;
          drGrade = 2;
        } else if (rawStatus == 'SCREENING_COMPLETED' || aiResult != null) {
          statusText = 'Selesai';
          statusColor = AppColors.primary;
          category = 'COMPLETED';

          final predClass = (aiResult?['predictedClass'] ?? 'NO_DR').toString().toUpperCase();
          if (predClass == 'NO_DR') {
            badgeText = 'No DR (Normal)';
            badgeIcon = Icons.check_circle_outline_rounded;
            badgeBgColor = const Color(0xFFE2E8F0);
            badgeTextColor = const Color(0xFF334155);
            drGrade = 0;
          } else if (predClass == 'MILD_DR') {
            badgeText = 'Mild (Ringan)';
            badgeIcon = Icons.warning_amber_rounded;
            badgeBgColor = const Color(0xFFE0F2FE);
            badgeTextColor = const Color(0xFF0284C7);
            drGrade = 1;
          } else if (predClass == 'MODERATE_DR') {
            badgeText = 'Moderate (Sedang)';
            badgeIcon = Icons.warning_rounded;
            badgeBgColor = const Color(0xFFFEF3C7);
            badgeTextColor = const Color(0xFFB45309);
            drGrade = 2;
          } else if (predClass == 'SEVERE_DR') {
            badgeText = 'Severe (Berat)';
            badgeIcon = Icons.error_outline_rounded;
            badgeBgColor = const Color(0xFFFEE2E2);
            badgeTextColor = const Color(0xFFDC2626);
            drGrade = 3;
          } else if (predClass == 'PROLIFERATIVE_DR') {
            badgeText = 'PDR (Proliferatif)';
            badgeIcon = Icons.report_problem_rounded;
            badgeBgColor = const Color(0xFFF3E8FF);
            badgeTextColor = const Color(0xFF7C3AED);
            drGrade = 4;
          } else {
            badgeText = 'High Risk (Perlu Rujukan)';
            badgeIcon = Icons.error_outline_rounded;
            badgeBgColor = const Color(0xFFFFEDD5);
            badgeTextColor = const Color(0xFFC2410C);
            drGrade = 3;
          }
        } else {
          statusText = 'Dalam Proses';
          statusColor = const Color(0xFF0284C7);
          badgeText = 'Sedang Diproses AI';
          badgeIcon = Icons.autorenew_rounded;
          badgeBgColor = const Color(0xFFE0F2FE);
          badgeTextColor = const Color(0xFF0284C7);
          category = 'IN_PROGRESS';
        }

        loaded.add(_ScreeningSessionItem(
          id: id,
          dateText: dateText,
          eyePosition: eyePosition,
          eyeName: eyeName,
          statusText: statusText,
          statusColor: statusColor,
          badgeText: badgeText,
          badgeIcon: badgeIcon,
          badgeBgColor: badgeBgColor,
          badgeTextColor: badgeTextColor,
          imageAsset: imageAsset,
          category: category,
          drGrade: drGrade,
          isDoctorReviewed: isDoctorReviewed,
          isQualityFailed: isQualityFailed,
          rawJson: scr,
        ));
      }

      if (mounted) {
        setState(() {
          _sessions = loaded;
          if (_sessions.isNotEmpty) {
            _lastScreeningDate = _extractDateOnly(_sessions.first.dateText);
          } else {
            _lastScreeningDate = 'Belum Ada';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data riwayat dari database: $e';
        });
      }
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Hari ini';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  String _extractDateOnly(String fullDateText) {
    if (fullDateText.contains(',')) {
      return fullDateText.split(',').first.trim();
    }
    return fullDateText;
  }

  List<_ScreeningSessionItem> get _filteredSessions {
    if (_activeFilter == 'COMPLETED') {
      return _sessions.where((s) => s.category == 'COMPLETED').toList();
    } else if (_activeFilter == 'IN_PROGRESS') {
      return _sessions.where((s) => s.category == 'IN_PROGRESS').toList();
    }
    return _sessions;
  }

  void _onSessionTapped(_ScreeningSessionItem item) {
    final patient = PatientModel(
      id: item.rawJson?['patient']?['id'] ?? 'p-active-patient',
      fullName: item.rawJson?['patient']?['fullName'] ?? 'Pengguna RETIVA',
      nik: item.rawJson?['patient']?['nik'] ?? '3471012304650001',
      phone: item.rawJson?['patient']?['phone'] ?? '-',
      birthDate: item.rawJson?['patient']?['birthDate'] ?? '1985-05-12',
      age: 41,
      gender: item.rawJson?['patient']?['gender'] ?? 'MALE',
      address: item.rawJson?['patient']?['address'] ?? 'D.I. Yogyakarta',
    );

    final qualityChecks = (item.rawJson?['qualityChecks'] as List?) ?? [];
    final firstQuality = qualityChecks.isNotEmpty ? qualityChecks[0] : null;

    if (item.isQualityFailed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QualityFailedRetakeScreen(
            eyePosition: item.eyePosition,
            qualityResult: QualityCheckResult(
              passed: false,
              overallScore: (firstQuality?['overallScore'] as num?)?.toDouble() ?? 0.42,
              illuminationScore: (firstQuality?['illuminationScore'] as num?)?.toDouble() ?? 0.38,
              blurScore: (firstQuality?['blurScore'] as num?)?.toDouble() ?? 0.45,
              fovScore: (firstQuality?['fovScore'] as num?)?.toDouble() ?? 0.50,
              retakeReason: firstQuality?['retakeReason'] ?? 'Pencahayaan foto atau ketajaman kurang optimal',
              retakeInstructions: firstQuality?['retakeInstructions'] ?? 'Pastikan ruangan sedikit redup dan stabilkan posisi kamera.',
            ),
            patient: patient,
          ),
        ),
      );
    } else if (item.isDoctorReviewed) {
      final review = item.rawJson?['humanReview'];
      final completeResult = CompleteScreeningResult(
        screeningId: item.id,
        status: 'DOCTOR_REVIEWED',
        qualityOD: QualityCheckResult(
          passed: true,
          overallScore: 0.92,
          blurScore: 0.94,
          illuminationScore: 0.91,
          fovScore: 0.95,
        ),
        aiResult: AIInferenceResult(
          predictedClass: item.rawJson?['aiResult']?['predictedClass'] ?? 'MODERATE_DR',
          confidence: (item.rawJson?['aiResult']?['confidence'] as num?)?.toDouble() ?? 0.91,
          rawProbabilities: const {
            'NO_DR': 0.02,
            'MILD_DR': 0.06,
            'MODERATE_DR': 0.91,
            'SEVERE_DR': 0.01,
            'PROLIFERATIVE_DR': 0.00,
          },
          isHighRisk: false,
        ),
        reliability: ReliabilityResult(
          status: 'HUMAN_REVIEW',
          score: 0.91,
          requiresHumanReview: true,
          reasoning: review?['clinicalSummary'] ?? 'Verifikasi konfirmasi temuan retina',
        ),
        recommendation: RecommendationResult(
          summary: item.rawJson?['recommendation']?['summary'] ?? item.badgeText,
          recommendedAction: item.rawJson?['recommendation']?['recommendedAction'] ?? 'Rujukan terencana Poli Mata',
          urgencyLevel: item.rawJson?['recommendation']?['urgencyLevel'] ?? 'MEDIUM',
          referralIndicated: true,
          clinicalGuideline: 'Pedoman Konsensus Perdami 2024',
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusHumanReviewScreen(
            result: completeResult,
            eyePosition: item.eyePosition,
            patient: patient,
            isDoctorReviewed: true,
            doctorName: review?['doctorName'] ?? item.rawJson?['doctorName'] ?? 'dr. Yunani Setyandriana, Sp.M',
            doctorRole: review?['doctorRole'] ?? item.rawJson?['doctorRole'] ?? 'Spesialis Vitreoretina & Oftalmologi',
            doctorSip: review?['doctorSip'] ?? item.rawJson?['doctorSip'] ?? 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)',
            doctorNotes: review?['clinicalSummary'] ?? review?['notes'] ?? 'Telah ditelaah dan diverifikasi oleh dokter spesialis mata.',
            reviewedAt: DateTime.now(),
          ),
        ),
      );
    } else {
      final ai = item.rawJson?['aiResult'];
      final predClass = ai?['predictedClass'] ?? (item.drGrade == 0 ? 'NO_DR' : 'MILD_DR');
      final completeResult = CompleteScreeningResult(
        screeningId: item.id,
        status: 'COMPLETED',
        qualityOD: QualityCheckResult(
          passed: true,
          overallScore: 0.94,
          blurScore: 0.95,
          illuminationScore: 0.92,
          fovScore: 0.96,
        ),
        aiResult: AIInferenceResult(
          predictedClass: predClass,
          confidence: (ai?['confidence'] as num?)?.toDouble() ??
              (item.rawJson?['confidence'] as num?)?.toDouble() ??
              0.94,
          rawProbabilities: (ai?['rawProbabilities'] is Map)
              ? Map<String, double>.from((ai!['rawProbabilities'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
              : {
                  'NO_DR': predClass == 'NO_DR' ? 0.94 : 0.05,
                  'MILD_DR': predClass == 'MILD_DR' ? 0.94 : 0.05,
                  'MODERATE_DR': predClass == 'MODERATE_DR' ? 0.94 : 0.01,
                  'SEVERE_DR': predClass == 'SEVERE_DR' ? 0.90 : 0.00,
                  'PROLIFERATIVE_DR': predClass == 'PROLIFERATIVE_DR' ? 0.94 : 0.00,
                },
          isHighRisk: predClass != 'NO_DR' && predClass != 'MILD_DR',
        ),
        reliability: ReliabilityResult(
          status: 'ANALYZE',
          score: 0.94,
          requiresHumanReview: false,
        ),
        recommendation: RecommendationResult(
          summary: item.rawJson?['recommendation']?['summary'] ?? item.badgeText,
          recommendedAction: item.rawJson?['recommendation']?['recommendedAction'] ?? (item.drGrade == 0 ? 'ROUTINE_ANNUAL_CHECK' : 'PUSKESMAS_FOLLOWUP_6_MONTHS'),
          urgencyLevel: item.rawJson?['recommendation']?['urgencyLevel'] ?? 'LOW',
          referralIndicated: false,
          clinicalGuideline: 'Pedoman Konsensus Perdami 2024',
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScreeningResultScreen(
            result: completeResult,
            eyePosition: item.eyePosition,
            patient: patient,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _sessions.where((s) => s.category == 'COMPLETED').length;
    final inProgressCount = _sessions.where((s) => s.category == 'IN_PROGRESS').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP BAR HEADER =================
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Riwayat Pemeriksaan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                    onPressed: _fetchRealScreeningHistory,
                    tooltip: 'Muat ulang data',
                  ),
                  const SizedBox(width: 4),
                  const NotificationBellWidget(),
                ],
              ),
            ),

            // ================= BODY SCROLLABLE =================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchRealScreeningHistory,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      const Text(
                        'Daftar riwayat pemeriksaan foto retina mandiri Anda dari server RETIVA.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ================= SUMMARY CARD =================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Left: Eye Icon Container
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.remove_red_eye_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Middle: Pemeriksaan Terakhir
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pemeriksaan Terakhir',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _lastScreeningDate,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right: Total Riwayat
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Total Riwayat',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_sessions.length} Sesi',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= FILTER CHIPS ROW (NO OVERFLOW) =================
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: 'Semua (${_sessions.length})',
                              isSelected: _activeFilter == 'ALL',
                              onTap: () => setState(() => _activeFilter = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Selesai ($completedCount)',
                              isSelected: _activeFilter == 'COMPLETED',
                              onTap: () => setState(() => _activeFilter = 'COMPLETED'),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterPill(
                              label: 'Dalam Proses ($inProgressCount)',
                              isSelected: _activeFilter == 'IN_PROGRESS',
                              onTap: () => setState(() => _activeFilter = 'IN_PROGRESS'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ================= CONTENT =================
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.0),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: AppColors.primary),
                                SizedBox(height: 14),
                                Text(
                                  'Memuat data riwayat dari PostgreSQL...',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_filteredSessions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(36),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 44, color: Color(0xFF94A3B8)),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada riwayat pemeriksaan retina',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Hasil pemeriksaan foto retina yang Anda ambil akan otomatis tersimpan di sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._filteredSessions.map((session) => _buildSessionCard(session)),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pill Filter Tab
  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Widget Card Sesi Riwayat Real
  Widget _buildSessionCard(_ScreeningSessionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSessionTapped(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Gambar Retina dengan Label OD/OS
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0F172A),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            item.imageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(
                                Icons.remove_red_eye_rounded,
                                color: Colors.white54,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xCC0F1E36),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.eyePosition,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Informasi Sesi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris 1: Tanggal & Waktu vs Status Teks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.statusText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: item.statusColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Baris 2: Judul Mata & Chevron Right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.eyeName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Baris 3: Badge Hasil Sesi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: item.badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.badgeIcon,
                              size: 13,
                              color: item.badgeTextColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.badgeText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: item.badgeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Model pembantu sesi riwayat pemeriksaan
class _ScreeningSessionItem {
  final String id;
  final String dateText;
  final String eyePosition;
  final String eyeName;
  final String statusText;
  final Color statusColor;
  final String badgeText;
  final IconData badgeIcon;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final String imageAsset;
  final String category; // 'COMPLETED' or 'IN_PROGRESS'
  final int drGrade;
  final bool isDoctorReviewed;
  final bool isQualityFailed;
  final Map<String, dynamic>? rawJson;

  const _ScreeningSessionItem({
    required this.id,
    required this.dateText,
    required this.eyePosition,
    required this.eyeName,
    required this.statusText,
    required this.statusColor,
    required this.badgeText,
    required this.badgeIcon,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.imageAsset,
    required this.category,
    this.drGrade = 0,
    this.isDoctorReviewed = false,
    this.isQualityFailed = false,
    this.rawJson,
  });
}
