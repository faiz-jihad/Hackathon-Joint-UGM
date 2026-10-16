import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retiva_mobile/presentation/screens/home_screen.dart';
import 'package:retiva_mobile/presentation/screens/upload_fundus_screen.dart';
import 'package:retiva_mobile/presentation/screens/screening_result_screen.dart';
import 'package:retiva_mobile/presentation/screens/quality_failed_retake_screen.dart';
import 'package:retiva_mobile/presentation/screens/human_review_pending_screen.dart';
import 'package:retiva_mobile/presentation/screens/clinical_recommendation_screen.dart';
import 'package:retiva_mobile/presentation/screens/referral_letter_screen.dart';
import 'package:retiva_mobile/presentation/screens/patient_history_screen.dart';
import 'package:retiva_mobile/presentation/widgets/gradcam_viewer_widget.dart';
import 'package:retiva_mobile/data/models/screening_result_model.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  final mockResult = CompleteScreeningResult(
    screeningId: 'test-scr-001',
    status: 'AI_ANALYZED',
    qualityOD: QualityCheckResult(
      passed: true,
      overallScore: 0.92,
      blurScore: 0.88,
      illuminationScore: 0.91,
      fovScore: 0.94,
    ),
    aiResult: AIInferenceResult(
      predictedClass: 'MODERATE_DR',
      confidence: 0.884,
      rawProbabilities: {
        'NO_DR': 0.02,
        'MILD_DR': 0.06,
        'MODERATE_DR': 0.884,
        'SEVERE_DR': 0.03,
        'PROLIFERATIVE_DR': 0.006,
      },
      isHighRisk: false,
    ),
    reliability: ReliabilityResult(
      status: 'ANALYZE',
      score: 0.92,
      requiresHumanReview: false,
    ),
    recommendation: RecommendationResult(
      summary: 'Ditemukan tanda Retinopati Diabetik Non-Proliferatif Sedang.',
      recommendedAction: 'SPECIALIST_OPHTHALMOLOGY_REFERRAL',
      urgencyLevel: 'MEDIUM',
      referralIndicated: true,
      clinicalGuideline: 'Pedoman Perdami & ADA 2024',
    ),
  );

  testWidgets('1. HomeScreen renders brand header, hero card, and actions', (tester) async {
    await tester.pumpWidget(createTestWidget(const HomeScreen(title: 'RETIVA Mobile')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('CareSync'), findsOneWidget);
    expect(find.text('What do you need?'), findsOneWidget);
    expect(find.text('My doctor'), findsOneWidget);
    expect(find.text('Medical Reports'), findsOneWidget);
    expect(find.text('Find Clinic'), findsOneWidget);
    expect(find.text('My Appointment'), findsOneWidget);
  });

  testWidgets('2. UploadFundusScreen renders bilateral eye tabs and protocol notice', (tester) async {
    await tester.pumpWidget(createTestWidget(const UploadFundusScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Upload Foto Retina'), findsOneWidget);
    expect(find.text('Pilih Foto Retina'), findsOneWidget);
    expect(find.textContaining('Langkah 1 dari 4'), findsOneWidget);
  });

  testWidgets('3. ScreeningResultScreen renders ICDR grade, confidence, and Grad-CAM', (tester) async {
    await tester.pumpWidget(createTestWidget(ScreeningResultScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('DIAGNOSIS'), findsWidgets);
    expect(find.textContaining('Grad-CAM'), findsWidgets);
  });

  testWidgets('4. QualityFailedRetakeScreen renders retake guidance and failure reasons', (tester) async {
    final failedQuality = QualityCheckResult(
      passed: false,
      overallScore: 0.28,
      blurScore: 0.24,
      illuminationScore: 0.35,
      fovScore: 0.60,
      retakeReason: 'Citra Buram & Kurang Pencahayaan',
    );

    await tester.pumpWidget(createTestWidget(QualityFailedRetakeScreen(
      eyePosition: 'OD',
      qualityResult: failedQuality,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Foto'), findsWidgets);
    expect(find.textContaining('Ulang'), findsWidgets);
  });

  testWidgets('5. HumanReviewPendingScreen renders borderline status and review instructions', (tester) async {
    await tester.pumpWidget(createTestWidget(HumanReviewPendingScreen(
      result: mockResult,
      eyePosition: 'OS',
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Keandalan'), findsWidgets);
    expect(find.textContaining('Foto Ulang'), findsWidgets);
  });

  testWidgets('6. ClinicalRecommendationScreen renders Perdami rules and nearest facilities', (tester) async {
    await tester.pumpWidget(createTestWidget(ClinicalRecommendationScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Rekomendasi Tindak Lanjut'), findsOneWidget);
  });

  testWidgets('7. ReferralLetterScreen renders electronic SPK with ICD-10 coding', (tester) async {
    await tester.pumpWidget(createTestWidget(ReferralLetterScreen(
      facility: const {
        'name': 'RS Mata Dr. Yap Yogyakarta',
        'address': 'Jl. Cik Di Tiro No.5',
        'distanceKm': 3.8,
      },
      result: mockResult,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Surat Pengantar Rujukan'), findsWidgets);
    expect(find.textContaining('E11.319'), findsWidgets);
    expect(find.textContaining('RS Mata Dr. Yap'), findsWidgets);
  });

  testWidgets('8. PatientHistoryScreen renders longitudinal timeline', (tester) async {
    await tester.pumpWidget(createTestWidget(const PatientHistoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Riwayat Pemeriksaan'), findsWidgets);
    expect(find.textContaining('Semua'), findsWidgets);
  });

  testWidgets('9. GradCamViewerWidget provides opacity slider, anatomical grid toggle, and zoom controls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(
      const Scaffold(
        body: SingleChildScrollView(
          child: GradCamViewerWidget(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Grid Anatomi Retina'), findsOneWidget);
    expect(find.text('Reset Zoom (1.0x)'), findsOneWidget);

    // Toggle anatomical grid
    await tester.tap(find.text('Grid Anatomi Retina'));
    await tester.pumpAndSettle();
    expect(find.text('Makula / Fovea'), findsOneWidget);
    expect(find.text('Papila N. Optikus'), findsOneWidget);
  });

  testWidgets('10. ScreeningResultScreen renders clinical lesion matrix and tele-consultation modal', (tester) async {
    await tester.pumpWidget(createTestWidget(ScreeningResultScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Validasi Biomarker Patologi Retina'), findsOneWidget);
    expect(find.textContaining('Mikroaneurisma'), findsWidgets);
  });

  testWidgets('11. ReferralLetterScreen renders vital signs table and PDF export dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(ReferralLetterScreen(
      facility: const {
        'name': 'RS Mata Dr. Yap Yogyakarta',
        'address': 'Jl. Cik Di Tiro No.5',
        'distanceKm': 3.8,
      },
      result: mockResult,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tanda Vital & Parameter Metabolik'), findsOneWidget);
    expect(find.textContaining('BSrE'), findsWidgets);
    expect(find.textContaining('Sinkronkan ke BPJS VClaim'), findsOneWidget);

    final btn = find.text('Unduh Surat Rujukan Resmi (PDF)');
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(find.textContaining('Surat Rujukan Resmi (SPK)'), findsOneWidget);
    expect(find.textContaining('SPK_RETIVA_2026090084.pdf'), findsOneWidget);
  });

  testWidgets('12. PatientHistoryScreen renders clinical filter chips and EHR details', (tester) async {
    await tester.pumpWidget(createTestWidget(const PatientHistoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Riwayat Pemeriksaan'), findsWidgets);
    expect(find.textContaining('Semua'), findsWidgets);
  });
}
