import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:retiva_mobile/core/constants/api_constants.dart';
import 'package:retiva_mobile/core/utils/clinical_helpers.dart';
import 'package:retiva_mobile/core/network/api_client.dart';
import 'package:retiva_mobile/data/models/patient_model.dart';

void main() {
  group('RETIVA Clinical Rules & Data Layer Tests', () {
    test('1. ClinicalHelpers ICDR 5-Class Severity Mapping', () {
      expect(ClinicalHelpers.getSeverityTitle('NO_DR'), contains('Derajat 0'));
      expect(ClinicalHelpers.getSeverityTitle('MILD_DR'), contains('Derajat 1'));
      expect(ClinicalHelpers.getSeverityTitle('MODERATE_DR'), contains('Derajat 2'));
      expect(ClinicalHelpers.getSeverityTitle('SEVERE_DR'), contains('Derajat 3'));
      expect(ClinicalHelpers.getSeverityTitle('PROLIFERATIVE_DR'), contains('Derajat 4'));
    });

    test('2. Perdami & ADA 2024 Deterministic Interval Rules', () {
      expect(ClinicalHelpers.getPerdamiInterval('NO_DR'), contains('12 Bulan'));
      expect(ClinicalHelpers.getPerdamiInterval('MILD_DR'), contains('6–12 Bulan'));
      expect(ClinicalHelpers.getPerdamiInterval('MODERATE_DR'), contains('3–6 Bulan'));
      expect(ClinicalHelpers.getPerdamiInterval('SEVERE_DR'), contains('2–4 Minggu'));
      expect(ClinicalHelpers.getPerdamiInterval('PROLIFERATIVE_DR'), contains('< 1–2 Minggu'));
    });

    test('3. PatientModel Demographics & Diabetes Profile Parsing', () {
      final json = {
        'id': 'pat-100',
        'nik': '3404015508750001',
        'fullName': 'Bapak Sutrisno',
        'birthDate': '1970-08-15',
        'gender': 'MALE',
        'age': 56,
        'diabetesProfile': {
          'diabetesType': 'TYPE_2',
          'yearOfDiagnosis': 2018,
          'currentTreatment': 'ORAL_MEDICATION',
          'lastHbA1c': 8.4,
          'glycaemicControlStatus': 'SUBOPTIMAL',
        }
      };

      final patient = PatientModel.fromJson(json);
      expect(patient.nik, equals('3404015508750001'));
      expect(patient.fullName, equals('Bapak Sutrisno'));
      expect(patient.age, equals(56));
      expect(patient.diabetesProfile, isNotNull);
      expect(patient.diabetesProfile?.lastHbA1c, equals(8.4));
      expect(patient.diabetesProfile?.glycaemicControlStatus, equals('SUBOPTIMAL'));
    });

    test('4. ApiConstants URLs & Dynamic Resolution', () {
      expect(ApiConstants.directScreen, contains('/api/v1/screenings/direct-screen'));
      expect(ApiConstants.login, contains('/api/v1/auth/login'));
      expect(ApiConstants.patients, contains('/api/v1/patients'));
      expect(ApiConstants.screenings, contains('/api/v1/screenings'));
      expect(ApiConstants.nearestFacilities(-7.77, 110.37), contains('lat=-7.77'));
    });
  });

  group('RETIVA 3 Figma State Machine Clinical Branches', () {
    final client = ApiClient();

    test('Branch 1: Normal Flow (Quality Pass & High Reliability Inference)', () async {
      final result = await client.executeScreening(
        imageFile: File('dummy.jpg'),
        eyePosition: 'OD',
        simulateRetake: false,
        simulateHumanReview: false,
      );

      expect(result.status, equals('AI_ANALYZED'));
      expect(result.qualityOD.passed, isTrue);
      expect(result.qualityOD.blurScore, greaterThanOrEqualTo(0.40));
      expect(result.reliability.status, equals('ANALYZE'));
      expect(result.reliability.requiresHumanReview, isFalse);
      expect(result.aiResult.predictedClass, equals('MODERATE_DR'));
      expect(result.aiResult.confidence, greaterThanOrEqualTo(0.85));
      expect(result.recommendation.recommendedAction, contains('REFERRAL'));
    });

    test('Branch 2: Retake Flow (Blurry Image / Quality Gate Failure)', () async {
      final result = await client.executeScreening(
        imageFile: File('dummy.jpg'),
        eyePosition: 'OD',
        simulateRetake: true,
      );

      expect(result.status, equals('RETAKE_REQUIRED'));
      expect(result.qualityOD.passed, isFalse);
      expect(result.qualityOD.blurScore, lessThan(0.40)); // Below Laplacian threshold
      expect(result.qualityOD.retakeReason, contains('BLURRY'));
      expect(result.qualityOD.retakeInstructions, isNotNull);
      expect(result.recommendation.recommendedAction, equals('IMAGE_RETAKE'));
    });

    test('Branch 3: Human Review Flow (Borderline Confidence / Specialist Routing)', () async {
      final result = await client.executeScreening(
        imageFile: File('dummy.jpg'),
        eyePosition: 'OS',
        simulateHumanReview: true,
      );

      expect(result.status, equals('HUMAN_REVIEW'));
      expect(result.qualityOD.passed, isTrue);
      expect(result.reliability.status, equals('HUMAN_REVIEW'));
      expect(result.reliability.requiresHumanReview, isTrue);
      expect(result.aiResult.confidence, lessThan(0.85)); // Marginal confidence
      expect(result.recommendation.recommendedAction, contains('REVIEW'));
    });

    test('Nearest Facilities & Geodesic Matching', () async {
      final facilities = await client.getNearestFacilities();
      expect(facilities, isNotEmpty);
      expect(facilities.first['name'], contains('RS Mata Dr. Yap'));
      expect(facilities.first['bpjsStatus'], equals('ACCEPTED'));
      expect(facilities.first['distanceKm'], isA<num>());
    });
  });
}
