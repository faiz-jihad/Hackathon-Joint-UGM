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
    expect(find.text('Widget Layar Utama HP'), findsOneWidget);
    expect(find.text('Skrining Mata Mandiri'), findsOneWidget);
  });

  testWidgets('2. UploadFundusScreen renders bilateral eye tabs and protocol notice', (tester) async {
    await tester.pumpWidget(createTestWidget(const UploadFundusScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('MATA KANAN (OD)'), findsOneWidget);
    expect(find.text('MATA KIRI (OS)'), findsOneWidget);
    expect(find.textContaining('Pasien'), findsWidgets);
    expect(find.text('Uji Kendali Mutu Citra (Quality Gate)'), findsOneWidget);
  });

  testWidgets('3. ScreeningResultScreen renders ICDR grade, confidence, and Grad-CAM', (tester) async {
    await tester.pumpWidget(createTestWidget(ScreeningResultScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pumpAndSettle();

    expect(find.text('11. HASIL SKRINING — KEANDALAN TINGGI'), findsOneWidget);
    expect(find.textContaining('NPDR Sedang'), findsOneWidget);
    expect(find.textContaining('88.4% Keyakinan'), findsOneWidget);
    expect(find.text('Peta Grad-CAM'), findsOneWidget);
    expect(find.text('Lihat Rekomendasi & Faskes Rujukan'), findsOneWidget);
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

    expect(find.text('05. KUALITAS BURAM — FOTO ULANG DIPERLUKAN'), findsOneWidget);
    expect(find.text('Citra Buram & Kurang Pencahayaan'), findsOneWidget);
    expect(find.text('Ambil Ulang Foto Sekarang (Retake)'), findsOneWidget);
  });

  testWidgets('5. HumanReviewPendingScreen renders borderline status and review instructions', (tester) async {
    await tester.pumpWidget(createTestWidget(HumanReviewPendingScreen(
      result: mockResult,
      eyePosition: 'OS',
    )));
    await tester.pumpAndSettle();

    expect(find.text('11. STATUS HUMAN REVIEW — RELIABILITAS BORDERLINE'), findsOneWidget);
    expect(find.text('Dialihkan ke Telaah Dokter Spesialis Mata'), findsOneWidget);
    expect(find.text('Kembali ke Beranda Skrining'), findsOneWidget);
  });

  testWidgets('6. ClinicalRecommendationScreen renders Perdami rules and nearest facilities', (tester) async {
    await tester.pumpWidget(createTestWidget(ClinicalRecommendationScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('14. TINDAKAN LANJUTAN & RUJUKAN FASKES'), findsOneWidget);
    expect(find.text('Pedoman Klinis Perdami & ADA 2024'), findsOneWidget);
    expect(find.text('Terbitkan Surat Pengantar Rujukan (SPK)'), findsOneWidget);
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

    expect(find.text('15. PENERBITAN SPK & DOKUMEN REKAM MEDIS'), findsOneWidget);
    expect(find.textContaining('E11.319'), findsOneWidget);
    expect(find.textContaining('RS Mata Dr. Yap'), findsWidgets);
    expect(find.text('Unduh / Cetak Surat Rujukan (PDF)'), findsOneWidget);
  });

  testWidgets('8. PatientHistoryScreen renders longitudinal timeline', (tester) async {
    await tester.pumpWidget(createTestWidget(const PatientHistoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('17. RIWAYAT PASIEN & TIMELINE LONGITUDINAL'), findsOneWidget);
    expect(find.text('Timeline Progresivitas Retina Pasien'), findsOneWidget);
    expect(find.textContaining('Tahun 2024'), findsOneWidget);
    expect(find.textContaining('Tahun 2025'), findsOneWidget);
    expect(find.textContaining('Tahun 2026'), findsOneWidget);
  });

  testWidgets('9. GradCamViewerWidget provides opacity slider, anatomical grid toggle, and zoom controls', (tester) async {
    await tester.pumpWidget(createTestWidget(ScreeningResultScreen(
      result: mockResult,
      eyePosition: 'OD',
    )));
    await tester.pumpAndSettle();

    expect(find.text('Grid Anatomi Retina'), findsOneWidget);
    expect(find.text('Reset Zoom (1.0x)'), findsOneWidget);
    expect(find.textContaining('Transparansi Heatmap'), findsOneWidget);
    expect(find.text('Skala Intensitas Atensi Model AI:'), findsOneWidget);

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

    expect(find.text('Analisis Biomarker & Temuan Lesi Mikrovaskular'), findsOneWidget);
    expect(find.textContaining('Mikroaneurisma Fokal'), findsOneWidget);
    expect(find.textContaining('Kesesuaian RME Permenkes'), findsOneWidget);
    expect(find.text('Konsultasi Tele-Oftalmologi (Sp.M Mitra)'), findsOneWidget);

    // Scroll until visible and tap
    await tester.ensureVisible(find.text('Konsultasi Tele-Oftalmologi (Sp.M Mitra)'));
    await tester.tap(find.text('Konsultasi Tele-Oftalmologi (Sp.M Mitra)'));
    await tester.pumpAndSettle();
    expect(find.text('Konsultasi Tele-Oftalmologi Sp.M'), findsOneWidget);
    expect(find.textContaining('dr. Bambang Hermanto, Sp.M(K)'), findsOneWidget);
  });

  testWidgets('11. ReferralLetterScreen renders vital signs table and PDF export dialog', (tester) async {
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
    expect(find.text('TTE Tersertifikasi BSrE/BSSN'), findsOneWidget);
    expect(find.text('Sinkronkan ke BPJS VClaim / SATUSEHAT'), findsOneWidget);

    // Scroll until visible and tap
    await tester.ensureVisible(find.text('Unduh / Cetak Surat Rujukan (PDF)'));
    await tester.tap(find.text('Unduh / Cetak Surat Rujukan (PDF)'));
    await tester.pumpAndSettle();
    expect(find.text('Dokumen SPK Terbit'), findsOneWidget);
    expect(find.textContaining('SPK_RETIVA_2026090084.pdf'), findsOneWidget);
  });

  testWidgets('12. PatientHistoryScreen renders clinical filter chips and EHR details', (tester) async {
    await tester.pumpWidget(createTestWidget(const PatientHistoryScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Semua ('), findsOneWidget);
    expect(find.text('HbA1c >= 8.0% (Prioritas)'), findsOneWidget);
    expect(find.text('DM Tipe 2'), findsOneWidget);
    expect(find.text('DM Tipe 1'), findsOneWidget);
    expect(find.text('+ Pasien Baru'), findsOneWidget);
  });
}
