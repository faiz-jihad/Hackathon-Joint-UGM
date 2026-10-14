import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/screening_result_model.dart';
import '../../data/models/patient_model.dart';
import 'screening_result_screen.dart';
import 'human_review_pending_screen.dart';

class AiAnalyzingScreen extends StatefulWidget {
  final CompleteScreeningResult result;
  final String eyePosition;
  final String demoBranch;
  final PatientModel? patient;
  final Uint8List? imageBytes;

  const AiAnalyzingScreen({
    super.key,
    required this.result,
    required this.eyePosition,
    required this.demoBranch,
    this.patient,
    this.imageBytes,
  });

  @override
  State<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends State<AiAnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  int _stepPhase = 1; // 0 = validating, 1 = segmenting (58% active), 2 = classifying, 3 = complete

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _progressAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        final val = _progressAnimation.value;
        if (mounted) {
          setState(() {
            if (val < 0.35) {
              _stepPhase = 0;
            } else if (val < 0.80) {
              _stepPhase = 1; // 58% frame matches this state
            } else if (val < 0.98) {
              _stepPhase = 2;
            } else {
              _stepPhase = 3;
            }
          });
        }
      });

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    _startWorkflow();
  }

  Future<void> _startWorkflow() async {
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 3600));

    if (!mounted) return;

    if (widget.result.reliability.requiresHumanReview ||
        widget.demoBranch == 'HUMAN_REVIEW') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HumanReviewPendingScreen(
            result: widget.result,
            eyePosition: widget.eyePosition,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScreeningResultScreen(
            result: widget.result,
            eyePosition: widget.eyePosition,
            patient: widget.patient,
            originalBytes: widget.imageBytes,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressVal = _progressAnimation.value;
    final displayPercent = (progressVal * 100).clamp(0, 100).toInt();

    String stageHeading;
    if (_stepPhase == 0) {
      stageHeading = 'Memvalidasi Kualitas Citra';
    } else if (_stepPhase == 1) {
      stageHeading = 'Mengidentifikasi Pola Mikrovaskular';
    } else if (_stepPhase == 2) {
      stageHeading = 'Klasifikasi Derajat Retinopati';
    } else {
      stageHeading = 'Pemeriksaan Selesai';
    }

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Stepper Breadcrumb (Langkah 3 dari 4)
                    _buildStepperBreadcrumb(),

                    const SizedBox(height: 16),

                    // Heading 3
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Menganalisis Retina...',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF246BFD),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Radial Progress Ring Animation & Center Scan
                    _buildRadialProgressRing(progressVal),

                    const SizedBox(height: 20),

                    // Percentage and Primary Stage
                    _buildPercentageSection(displayPercent, stageHeading),

                    const SizedBox(height: 24),

                    // Sequential Processing Steps (3 Cards)
                    _buildProcessingSteps(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Note Footer (Fixed Bottom)
            _buildNoteFooter(),
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
                color: Color(0xFF246BFD),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Analisis Retina',
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
              _buildStepIndicator(isActive: false, isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isActive: false, isCurrent: false),
              const SizedBox(width: 6),
              _buildStepIndicator(isActive: true, isCurrent: true),
              const SizedBox(width: 6),
              _buildStepIndicator(isActive: false, isCurrent: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({required bool isActive, required bool isCurrent}) {
    return Container(
      width: isCurrent ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF246BFD) : const Color(0xFFD8E3FB),
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }

  Widget _buildRadialProgressRing(double progress) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress ring
          SizedBox(
            width: 192,
            height: 192,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFD8E3FB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF246BFD)),
            ),
          ),

          // Central circular fundus scan thumbnail with radar sweep
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  spreadRadius: 4,
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Actual fundus image
                  if (widget.imageBytes != null)
                    Image.memory(
                      widget.imageBytes!,
                      fit: BoxFit.cover,
                    )
                  else
                    Image.asset(
                      'assets/images/analisis_fundus_sample.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/retina_hero.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                  // Blue Overlay
                  Container(
                    color: const Color(0x1A3B82F6), // rgba(59,130,246,0.1)
                  ),

                  // Laser scanner bar sweep
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(0, (_laserAnimation.value * 2.0) - 1.0),
                        child: Container(
                          height: 5,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2196F3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageSection(int displayPercent, String stageHeading) {
    return Column(
      children: [
        Text(
          '$displayPercent%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF246BFD),
            letterSpacing: -0.75,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stageHeading,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: const Text(
            'Sedang memeriksa karakteristik citra retina untuk indikasi retinopati diabetik...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingSteps() {
    final isStep1Done = _stepPhase >= 1;
    final isStep2Active = _stepPhase == 1;
    final isStep2Done = _stepPhase >= 2;
    final isStep3Active = _stepPhase == 2;
    final isStep3Done = _stepPhase >= 3;

    return Column(
      children: [
        // Step 1: Validasi Kualitas Citra
        _buildStepCard(
          title: 'Validasi Kualitas Citra',
          status: isStep1Done
              ? _StepStatus.completed
              : _StepStatus.active,
        ),
        const SizedBox(height: 10),

        // Step 2: Segmentasi Area Retina
        _buildStepCard(
          title: 'Segmentasi Area Retina',
          status: isStep2Done
              ? _StepStatus.completed
              : (isStep2Active ? _StepStatus.active : _StepStatus.pending),
        ),
        const SizedBox(height: 10),

        // Step 3: Klasifikasi Derajat DR
        _buildStepCard(
          title: 'Klasifikasi Derajat DR',
          status: isStep3Done
              ? _StepStatus.completed
              : (isStep3Active ? _StepStatus.active : _StepStatus.pending),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String title,
    required _StepStatus status,
  }) {
    switch (status) {
      case _StepStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
        );

      case _StepStatus.active:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xCCE3F2FD), // rgba(227,242,253,0.8)
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x662196F3)), // rgba(33,150,243,0.4)
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF246BFD),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
              ),
            ],
          ),
        );

      case _StepStatus.pending:
        return Opacity(
          opacity: 0.6,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x99FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                  child: Text(
                    'Menunggu',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildNoteFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(width: 6),
          Text(
            'Pemrosesan data aman & terenkripsi klinis',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus {
  completed,
  active,
  pending,
}
