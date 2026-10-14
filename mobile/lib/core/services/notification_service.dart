import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _keyNotificationsEnabled = 'pref_notifications_enabled';
  static const String _keyDiscreetMode = 'pref_discreet_mode';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  static Future<bool> isDiscreetMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDiscreetMode) ?? true;
  }

  static Future<void> setDiscreetMode(bool discreet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDiscreetMode, discreet);
  }

  /// Formats notification message protecting medical privacy
  static String formatDiscreetMessage(String activityTitle, String timeStr) {
    return 'Pengingat Retiva ($timeStr): Saatnya melakukan jadwal perawatan harian Anda 💙';
  }
}
