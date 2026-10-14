import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Dynamically resolve emulator vs desktop host
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    try {
      if (Platform.isAndroid) {
        // Android Emulator loopback alias to host machine
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static String customBaseUrl = '';

  static String get baseUrl =>
      customBaseUrl.isNotEmpty ? customBaseUrl : defaultBaseUrl;

  // Authentication
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get me => '$baseUrl/api/v1/auth/me';

  // Patients & Diabetes Profile
  static String get patients => '$baseUrl/api/v1/patients';
  static String patientDetail(String id) => '$baseUrl/api/v1/patients/$id';
  static String diabetesProfile(String id) =>
      '$baseUrl/api/v1/patients/$id/diabetes-profile';

  // Screenings & AI Gate Pipeline
  static String get screenings => '$baseUrl/api/v1/screenings';
  static String screeningDetail(String id) => '$baseUrl/api/v1/screenings/$id';
  static String uploadImage(String screeningId) =>
      '$baseUrl/api/v1/screenings/$screeningId/images';
  static String qualityCheck(String screeningId) =>
      '$baseUrl/api/v1/screenings/$screeningId/quality-check';
  static String analyzeScreening(String screeningId) =>
      '$baseUrl/api/v1/screenings/$screeningId/analyze';
  static String get directScreen => '$baseUrl/api/v1/screenings/direct-screen';
  static String completeScreening(String screeningId) =>
      '$baseUrl/api/v1/screenings/$screeningId/complete';

  // Recommendations & Referrals
  static String recommendations(String screeningId) =>
      '$baseUrl/api/v1/recommendations/$screeningId';
  static String get facilitiesMatch => '$baseUrl/api/v1/facilities/match';
  static String nearestFacilities(double lat, double lng) =>
      '$baseUrl/api/v1/facilities/nearest?lat=$lat&lng=$lng';
  static String get referrals => '$baseUrl/api/v1/referrals';
  static String referralDetail(String id) => '$baseUrl/api/v1/referrals/$id';

  // Longitudinal History
  static String patientHistory(String patientId) =>
      '$baseUrl/api/v1/history/patient/$patientId';

  // AI Care Companion
  static String careCompanionState(String patientId) =>
      '$baseUrl/api/v1/care-companion/state?patientId=$patientId';
  static String get urgentCheck => '$baseUrl/api/v1/care-companion/urgent-check';
  static String get consultationSummary =>
      '$baseUrl/api/v1/care-companion/consultation-summary';
  static String confirmConsultation(String id) =>
      '$baseUrl/api/v1/care-companion/consultation-summary/$id/confirm';
  static String get generateMealPlan =>
      '$baseUrl/api/v1/care-companion/meal-plan/generate';
  static String get replaceMeal =>
      '$baseUrl/api/v1/care-companion/meal-plan/replace-meal';
  static String get careReminders => '$baseUrl/api/v1/care-companion/reminders';
  static String reminderDetail(String id) =>
      '$baseUrl/api/v1/care-companion/reminders/$id';
  static String get careProgress => '$baseUrl/api/v1/care-companion/progress';
  static String get orchestrator =>
      '$baseUrl/api/v1/care-companion/orchestrator';

  // Master Data Endpoints
  static String get masterMeals => '$baseUrl/api/v1/master/meals';
  static String get masterQuestions => '$baseUrl/api/v1/master/questions';
}
