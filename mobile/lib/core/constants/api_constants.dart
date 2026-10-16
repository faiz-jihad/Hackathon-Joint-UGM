import 'package:flutter/foundation.dart' show kIsWeb;

/// Mode Environment Backend Retiva
enum BackendEnvironment {
  /// Subdomain Resmi HTTPS (https://hackathon.mataceria.my.id)
  onlineDomain,

  /// Server IP VPS Langsung (http://43.173.35.200)
  onlineVpsIp,

  /// Server Lokal Laptop via Wi-Fi (http://192.168.1.13:3000)
  offlineLaptop,

  /// Server Lokal via Android Emulator (10.0.2.2:3000)
  offlineEmulator,

  /// Server Lokal Desktop / Web (localhost:3000)
  offlineLocalhost,
}

class ApiConstants {
  // ===========================================================================
  // ⚙️ PENGATURAN MODE SERVER (Ganti di sini untuk beralih Online / Offline)
  // ===========================================================================

  /// Ganti pilihan environment aktif:
  /// Default: `BackendEnvironment.onlineDomain` -> Menggunakan https://hackathon.mataceria.my.id
  static BackendEnvironment currentEnvironment = BackendEnvironment.offlineLocalhost;

  // Daftar Endpoint URL
  static const String domainUrl = 'https://hackathon.mataceria.my.id';
  static const String vpsUrl = 'http://43.173.35.200';
  static const String laptopWifiUrl = 'http://192.168.1.25:3000';
  static const String emulatorUrl = 'http://10.0.2.2:3000';
  static const String localhostUrl = 'http://localhost:3000';

  /// Daftar kandidat Base URL untuk multi-path fallback di perangkat mobile (USB ADB reverse, Wi-Fi LAN, dan online)
  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (customBaseUrl.isNotEmpty) list.add(customBaseUrl);
    list.add(baseUrl);
    list.add(defaultBaseUrl);
    if (!kIsWeb) {
      list.add('http://localhost:3000'); // Port reverse via USB ADB
      list.add(laptopWifiUrl); // IP LAN Wi-Fi Laptop (192.168.1.25:3000)
      list.add(domainUrl); // Subdomain HTTPS Resmi
      list.add(emulatorUrl); // Emulator loopback
    } else {
      list.add(localhostUrl);
    }
    return list.toSet().toList();
  }

  /// Toggle cepat menggunakan boolean:
  /// ApiConstants.isOnline = true  -> Pindah ke Subdomain Resmi HTTPS
  /// ApiConstants.isOnline = false -> Pindah ke Laptop Wi-Fi
  static bool get isOnline =>
      currentEnvironment == BackendEnvironment.onlineDomain ||
      currentEnvironment == BackendEnvironment.onlineVpsIp;
  static set isOnline(bool value) {
    currentEnvironment = value ? BackendEnvironment.onlineDomain : BackendEnvironment.offlineLaptop;
  }

  /// Helper untuk beralih mode secara instan
  static void useDomain() => currentEnvironment = BackendEnvironment.onlineDomain;
  static void useVps() => currentEnvironment = BackendEnvironment.onlineDomain;
  static void useVpsIp() => currentEnvironment = BackendEnvironment.onlineVpsIp;
  static void useLaptopWifi() => currentEnvironment = BackendEnvironment.offlineLaptop;
  static void useEmulator() => currentEnvironment = BackendEnvironment.offlineEmulator;

  /// Resolusi Base URL aktif berdasarkan environment terpilih
  static String get defaultBaseUrl {
    // Pada Flutter Web (Chrome), otomatis prioritaskan server lokal port 3000 agar tersambung ke database lokal
    if (kIsWeb) {
      return localhostUrl;
    }

    switch (currentEnvironment) {
      case BackendEnvironment.onlineDomain:
        return domainUrl;
      case BackendEnvironment.onlineVpsIp:
        return vpsUrl;
      case BackendEnvironment.offlineLaptop:
        return laptopWifiUrl;
      case BackendEnvironment.offlineEmulator:
        return emulatorUrl;
      case BackendEnvironment.offlineLocalhost:
        return localhostUrl;
    }
  }

  static String customBaseUrl = '';

  static String get baseUrl =>
      customBaseUrl.isNotEmpty ? customBaseUrl : defaultBaseUrl;

  // Authentication & Users
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get register => '$baseUrl/api/v1/auth/register';
  static String get me => '$baseUrl/api/v1/auth/me';
  static String get users => '$baseUrl/api/v1/users';
  static String get doctors => '$baseUrl/api/v1/doctors';
  static String getDoctors({String? category, String? query}) {
    final params = <String>[];
    if (category != null && category != 'Semua') params.add('category=$category');
    if (query != null && query.isNotEmpty) params.add('query=${Uri.encodeComponent(query)}');
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    return '$baseUrl/api/v1/doctors$qs';
  }

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
  static String reviewStatus(String screeningId) =>
      '$baseUrl/api/v1/reviews/status?screeningId=$screeningId';
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
  static String dailyAgenda(String patientId, {String? date}) =>
      '$baseUrl/api/v1/care-companion/agenda?patientId=$patientId${date != null ? '&date=$date' : ''}';
  static String get toggleAgenda =>
      '$baseUrl/api/v1/care-companion/agenda/toggle';
  static String get dailyCheckIn =>
      '$baseUrl/api/v1/care-companion/check-in';
  static String smartMeal(String patientId, {String? category}) =>
      '$baseUrl/api/v1/care-companion/smart-meal?patientId=$patientId${category != null ? '&category=$category' : ''}';
  static String get smartMealPersonalize =>
      '$baseUrl/api/v1/care-companion/smart-meal';
  static String get smartMealEaten =>
      '$baseUrl/api/v1/care-companion/smart-meal/eaten';
  static String get smartMealSwap =>
      '$baseUrl/api/v1/care-companion/smart-meal/swap';


  // Master Data Endpoints
  static String get masterMeals => '$baseUrl/api/v1/master/meals';
  static String get masterQuestions => '$baseUrl/api/v1/master/questions';

  // Retiva SOS Emergency Endpoints
  static String get sosActivate => '$baseUrl/api/v1/sos/activate';
  static String get sosIncidents => '$baseUrl/api/v1/sos/incidents';
  static String sosIncidentDetail(String id) => '$baseUrl/api/v1/sos/incidents/$id';
  static String sosContacts(String patientId) => '$baseUrl/api/v1/sos/contacts?patientId=$patientId';
}
