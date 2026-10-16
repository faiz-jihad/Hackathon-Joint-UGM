import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/clinical_helpers.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'human_review_result_screen.dart';
import '../widgets/notification_bell_widget.dart';

class StatusHumanReviewScreen extends StatefulWidget {
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
  final bool isDoctorReviewed;
  final String? adjudicationAction;
  final String? finalGrade;

  const StatusHumanReviewScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    this.patient,
    this.imageBytes,
    this.imageFile,
    this.doctorName = 'dr. Yunani Setyandriana, Sp.M',
    this.doctorRole = 'Spesialis Vitreoretina & Oftalmologi',
    this.doctorSip,
    this.doctorNotes,
    this.reviewedAt,
    this.isDoctorReviewed = false,
    this.adjudicationAction,
    this.finalGrade,
  });

  @override
  State<StatusHumanReviewScreen> createState() => _StatusHumanReviewScreenState();
}

class _StatusHumanReviewScreenState extends State<StatusHumanReviewScreen> {
  late bool _isDoctorReviewed;
  late String _currentDoctorName;
  late String _currentDoctorRole;
  late String _currentDoctorSip;
  String? _currentDoctorNotes;
  String? _adjudicationAction;
  String? _finalGrade;
  final DateTime _receivedAt = DateTime.now();
  DateTime _reviewedAt = DateTime.now();
  Timer? _reviewPollingTimer;

  @override
  void initState() {
    super.initState();
    _isDoctorReviewed = widget.isDoctorReviewed;
    _currentDoctorName = widget.doctorName;
    _currentDoctorRole = widget.doctorRole;
    _currentDoctorSip = widget.doctorSip ?? 'SIP: 446.1/1982/SIP-D/2024 (RTV-0003)';
    _currentDoctorNotes = widget.doctorNotes;
    _adjudicationAction = widget.adjudicationAction;
    _finalGrade = widget.finalGrade;
    if (widget.reviewedAt != null) {
      _reviewedAt = widget.reviewedAt!;
    }
    _registerCaseToServer();
    _fetchInitialReviewStatus();
    _startReviewPolling();
  }

  void _registerCaseToServer() {
    final rawId = widget.result.screeningId;
    final displayId = rawId.startsWith('#')
        ? rawId
        : ClinicalHelpers.generateScreeningDisplayId(rawId);

    ApiClient().submitForHumanReview(
      screeningId: displayId,
      patientName: widget.patient?.fullName ?? (ApiClient().currentUser?.fullName ?? 'Bapak Sutrisno'),
      patientNik: widget.patient?.nik ?? '3404015508750001',
      eyePosition: widget.eyePosition,
      drGrade: widget.result.aiResult.predictedClass,
      confidence: widget.result.aiResult.confidence * 100,
      doctorName: _currentDoctorName,
      doctorRole: _currentDoctorRole,
      doctorSip: _currentDoctorSip,
    );
  }

  Future<void> _fetchInitialReviewStatus() async {
    final rawId = widget.result.screeningId;
    final displayId = rawId.startsWith('#')
        ? rawId
        : ClinicalHelpers.generateScreeningDisplayId(rawId);

    try {
      var res = await ApiClient().checkReviewStatus(displayId);
      if (res['doctorName'] == null && res['isReviewed'] != true) {
        final altRes = await ApiClient().checkReviewStatus(rawId);
        if (altRes['doctorName'] != null || altRes['isReviewed'] == true) {
          res = altRes;
        }
      }
      if (mounted) {
        final docName = res['doctorName']?.toString();
        final docRole = res['doctorRole']?.toString();
        final docSip = res['doctorSip']?.toString();
        final docNotes = res['notes']?.toString();
        final adjAction = res['adjudicationAction']?.toString();
        final fGrade = (res['finalGrade'] ?? res['confirmedGrade'])?.toString();
        DateTime reviewTime = _reviewedAt;
        if (res['adjudicatedAt'] != null) {
          final parsed = DateTime.tryParse(res['adjudicatedAt'].toString());
          if (parsed != null) reviewTime = parsed;
        }

        setState(() {
          if (docName != null && docName.isNotEmpty) {
            _currentDoctorName = docName;
          }
          if (docRole != null && docRole.isNotEmpty) {
            _currentDoctorRole = docRole;
          }
          if (docSip != null && docSip.isNotEmpty) {
            _currentDoctorSip = docSip;
          }
          if (res['isReviewed'] == true) {
            _isDoctorReviewed = true;
            if (docNotes != null && docNotes.trim().isNotEmpty) {
              _currentDoctorNotes = docNotes;
            }
            if (adjAction != null && adjAction.isNotEmpty) {
              _adjudicationAction = adjAction;
            }
            if (fGrade != null && fGrade.isNotEmpty) {
              _finalGrade = fGrade;
            }
            _reviewedAt = reviewTime;
          }
        });

        if (res['isReviewed'] == true) {
          ApiClient().updateLocalScreeningReview(
            screeningId: displayId,
            doctorName: _currentDoctorName,
            doctorRole: _currentDoctorRole,
            doctorSip: _currentDoctorSip,
            doctorNotes: _currentDoctorNotes,
            adjudicationAction: _adjudicationAction,
            finalGrade: _finalGrade,
            isReviewed: true,
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reviewPollingTimer?.cancel();
    super.dispose();
  }

  void _startReviewPolling() {
    _reviewPollingTimer?.cancel();
    _reviewPollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isDoctorReviewed && _currentDoctorNotes != null && _currentDoctorNotes!.trim().isNotEmpty) {
        timer.cancel();
        return;
      }
      try {
        final rawId = widget.result.screeningId;
        final displayId = rawId.startsWith('#')
            ? rawId
            : ClinicalHelpers.generateScreeningDisplayId(rawId);

        var res = await ApiClient().checkReviewStatus(displayId);
        if (res['doctorName'] == null && res['isReviewed'] != true) {
          final altRes = await ApiClient().checkReviewStatus(rawId);
          if (altRes['doctorName'] != null || altRes['isReviewed'] == true) {
            res = altRes;
          }
        }
        if (mounted) {
          final docName = res['doctorName']?.toString();
          final docRole = res['doctorRole']?.toString();
          final docSip = res['doctorSip']?.toString();
          final docNotes = res['notes']?.toString();
          final adjAction = res['adjudicationAction']?.toString();
          final fGrade = (res['finalGrade'] ?? res['confirmedGrade'])?.toString();
          DateTime reviewTime = _reviewedAt;
          if (res['adjudicatedAt'] != null) {
            final parsed = DateTime.tryParse(res['adjudicatedAt'].toString());
            if (parsed != null) reviewTime = parsed;
          }

          if (docName != null && docName.isNotEmpty && docName != _currentDoctorName) {
            setState(() {
              _currentDoctorName = docName;
              if (docRole != null && docRole.isNotEmpty) _currentDoctorRole = docRole;
              if (docSip != null && docSip.isNotEmpty) _currentDoctorSip = docSip;
            });
          }

          if (res['isReviewed'] == true) {
            final activeName = docName ?? _currentDoctorName;
            if (!_isDoctorReviewed) {
              NotificationBellWidget.incrementUnread(doctorName: activeName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 5),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Telaah Spesialis Selesai! $activeName telah menandatangani rekomendasi klinis.',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            setState(() {
              _isDoctorReviewed = true;
              _currentDoctorName = activeName;
              if (docRole != null && docRole.isNotEmpty) _currentDoctorRole = docRole;
              if (docSip != null && docSip.isNotEmpty) _currentDoctorSip = docSip;
              if (docNotes != null && docNotes.trim().isNotEmpty) {
                _currentDoctorNotes = docNotes;
              }
              if (adjAction != null && adjAction.isNotEmpty) {
                _adjudicationAction = adjAction;
              }
              if (fGrade != null && fGrade.isNotEmpty) {
                _finalGrade = fGrade;
              }
              _reviewedAt = reviewTime;
            });

            ApiClient().updateLocalScreeningReview(
              screeningId: displayId,
              doctorName: activeName,
              doctorRole: _currentDoctorRole,
              doctorSip: _currentDoctorSip,
              doctorNotes: _currentDoctorNotes,
              adjudicationAction: _adjudicationAction,
              finalGrade: _finalGrade,
              isReviewed: true,
            );
            timer.cancel();
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate readable screening display ID (#RTV-YYYYMMDD-XX format)
    final rawId = widget.result.screeningId;
    final displayId = rawId.startsWith('#')
        ? rawId
        : ClinicalHelpers.generateScreeningDisplayId(rawId);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isDoctorReviewed);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar matching Figma Node 85:1083
              _buildTopAppBar(context),

              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 1: ID Skrining & Tanggal
                      _buildScreeningIdCard(displayId),

                      const SizedBox(height: 14),

                      // Card 2: Status Review (Menunggu atau Selesai)
                      _buildReviewStatusCard(),

                      const SizedBox(height: 16),

                      // Card 3: Fundus Image Preview with Verifikator Medis Overlay
                      _buildFundusWithVerifierOverlay(),

                      const SizedBox(height: 16),

                      // Card 4: Kronologi Pemeriksaan
                      _buildChronologyCard(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              _buildBottomCta(context),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context, _isDoctorReviewed),
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
          const Expanded(
            child: Text(
              'Status Human Review',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF246BFD),
              ),
            ),
          ),
          const NotificationBellWidget(),
        ],
      ),
    );
  }

  Widget _buildScreeningIdCard(String displayId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ID SKRINING',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayId,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                ClinicalHelpers.formatIndonesianDateTime(_receivedAt),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatusCard() {
    if (!_isDoctorReviewed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 20,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menunggu Telaah Spesialis',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Foto retina Anda dalam antrean telaah oleh $_currentDoctorName. Hasil akan diperbarui otomatis.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF92400E),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF1FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Color(0xFF246BFD),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Selesai',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dokter spesialis mata telah selesai meninjau foto retina Anda.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundusWithVerifierOverlay() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fundus Retina Image (Displays the real uploaded fundus image)
            if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty)
              Image.memory(
                widget.imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/fundus_borderline_sample.jpg',
                  fit: BoxFit.cover,
                ),
              )
            else if (widget.imageFile != null)
              Image.file(
                widget.imageFile!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/fundus_borderline_sample.jpg',
                  fit: BoxFit.cover,
                ),
              )
            else
              Image.asset(
                'assets/images/fundus_borderline_sample.jpg',
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
                    Color(0x33000000),
                    Colors.transparent,
                    Color(0x99000000),
                  ],
                ),
              ),
            ),

            // Floating Verifikator Medis Badge Card (Figma Node: Matches Image 4 & 5)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8E3FB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 20,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Verifikator Medis',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentDoctorName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  Widget _buildChronologyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kronologi Pemeriksaan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Timeline Step 1: Foto Diterima
          _buildTimelineNode(
            title: 'Foto Diterima',
            subtitle: ClinicalHelpers.formatIndonesianDateTime(_receivedAt),
            isDone: true,
            isLast: false,
          ),

          // Timeline Step 2: Verifikasi Sistem
          _buildTimelineNode(
            title: 'Verifikasi Sistem',
            subtitle: 'Kualitas citra layak evaluasi (Grade A)',
            isDone: true,
            isLast: false,
          ),

          // Timeline Step 3: Ditinjau Tenaga Kesehatan
          _buildTimelineNode(
            title: 'Ditinjau Tenaga Kesehatan',
            subtitle: _isDoctorReviewed
                ? 'Selesai pada ${ClinicalHelpers.formatIndonesianDateTime(_reviewedAt)}'
                : 'Menunggu telaah klinis oleh $_currentDoctorName',
            isDone: _isDoctorReviewed,
            isPending: !_isDoctorReviewed,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isLast,
    bool isPending = false,
  }) {
    Color circleColor = const Color(0xFF246BFD);
    Color iconColor = Colors.white;
    IconData icon = Icons.check;

    if (isPending) {
      circleColor = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.hourglass_top_rounded;
    } else if (!isDone) {
      circleColor = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
      icon = Icons.circle_outlined;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: isPending ? Border.all(color: const Color(0xFFF59E0B), width: 1.5) : null,
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: iconColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? const Color(0xFF246BFD) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDone || isPending ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Menunggu',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: isPending ? FontWeight.w600 : FontWeight.w500,
                      color: isPending ? const Color(0xFFB45309) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          onPressed: _isDoctorReviewed
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HumanReviewResultScreen(
                        result: widget.result,
                        eyePosition: widget.eyePosition,
                        patient: widget.patient,
                        imageBytes: widget.imageBytes,
                        imageFile: widget.imageFile,
                        doctorName: _currentDoctorName,
                        doctorRole: _currentDoctorRole,
                        doctorSip: _currentDoctorSip,
                        doctorNotes: _currentDoctorNotes,
                        reviewedAt: _reviewedAt,
                        adjudicationAction: _adjudicationAction,
                        finalGrade: _finalGrade,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF246BFD),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF1F5F9),
            disabledForegroundColor: const Color(0xFF64748B),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            _isDoctorReviewed ? 'Lihat Hasil Human Review' : 'Menunggu Selesai Ditelaah Dokter Sp.M',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

