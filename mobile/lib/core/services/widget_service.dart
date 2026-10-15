import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/daily_agenda_model.dart';
import '../../data/models/smart_meal_model.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.example.retiva/widget');

  /// Synchronizes daily agenda data with Android Native Widgets
  static Future<void> updateWidgetData(DailyAgendaSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Next Activity info
      await prefs.setString('widget_next_activity_time', summary.nextActivityTime);
      await prefs.setString('widget_next_activity_title', summary.nextActivityTitle);
      await prefs.setString('widget_next_activity_category', summary.nextActivityCategory);

      // 2. Progress info
      final progressText = '${summary.completedCount}/${summary.totalCount}';
      await prefs.setString('widget_progress_text', progressText);
      await prefs.setInt('widget_completed_count', summary.completedCount);
      await prefs.setInt('widget_total_count', summary.totalCount);
      await prefs.setInt('widget_progress_percent', summary.completionPercentage);

      // 3. Contextual Mascot Message
      await prefs.setString('widget_mascot_message', summary.contextualMascotMessage);

      // 4. Up to 3 preview items for larger widget
      final activeItems = summary.agenda;
      for (int i = 0; i < 3; i++) {
        if (i < activeItems.length) {
          final item = activeItems[i];
          await prefs.setString('widget_item_${i}_time', item.time);
          await prefs.setString('widget_item_${i}_title', item.title);
          await prefs.setBool('widget_item_${i}_done', item.isCompleted);
        } else {
          await prefs.remove('widget_item_${i}_time');
          await prefs.remove('widget_item_${i}_title');
          await prefs.remove('widget_item_${i}_done');
        }
      }

      // 5. Detect next meal item in agenda if available
      final mealItem = activeItems.cast<DailyAgendaItem?>().firstWhere(
        (it) => it != null && it.category == 'MEAL' && !it.isCompleted,
        orElse: () => activeItems.cast<DailyAgendaItem?>().firstWhere(
          (it) => it != null && it.category == 'MEAL',
          orElse: () => null,
        ),
      );

      if (mealItem != null) {
        await prefs.setString('widget_next_meal_title', mealItem.title);
        await prefs.setString('widget_next_meal_time', mealItem.time);
        await prefs.setBool('widget_next_meal_is_eaten', mealItem.isCompleted);
      }

      await prefs.setString('widget_last_updated', DateTime.now().toIso8601String());

      // 6. Notify Native Android AppWidgetManager to refresh RemoteViews
      try {
        await _channel.invokeMethod('updateWidgets');
      } catch (_) {
        // MethodChannel might be ignored on non-Android or during test
      }
    } catch (_) {
      // Gracefully handle storage errors
    }
  }

  /// Synchronizes detailed smart meal recommendation to widget
  static Future<void> updateNextMealData(SmartMealItem meal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_next_meal_id', meal.id);
      await prefs.setString('widget_next_meal_title', meal.name);
      await prefs.setString('widget_next_meal_main_dish', meal.mainDish);
      await prefs.setString('widget_next_meal_time', meal.timeRecommendation);
      await prefs.setString('widget_next_meal_category', meal.category);
      await prefs.setInt('widget_next_meal_calories', meal.nutrition.caloriesKcal.round());
      await prefs.setInt('widget_next_meal_cost', meal.estimatedCostIdr.round());
      await prefs.setString('widget_next_meal_gi', meal.nutrition.glycemicIndex);
      await prefs.setBool('widget_next_meal_is_eaten', meal.isEaten);

      try {
        await _channel.invokeMethod('updateWidgets');
      } catch (_) {}
    } catch (_) {}
  }

  /// Sets up default initial widget state if empty
  static Future<void> initializeDefaultWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('widget_next_activity_time') == null) {
      await prefs.setString('widget_next_activity_time', '07.15');
      await prefs.setString('widget_next_activity_title', 'Sarapan sehat');
      await prefs.setString('widget_next_activity_category', 'MEAL');
      await prefs.setString('widget_progress_text', '2/5');
      await prefs.setInt('widget_completed_count', 2);
      await prefs.setInt('widget_total_count', 5);
      await prefs.setInt('widget_progress_percent', 40);
      await prefs.setString('widget_mascot_message', 'Halo! Semangat hari ini 💙');

      await prefs.setString('widget_item_0_time', '07.15');
      await prefs.setString('widget_item_0_title', 'Sarapan sehat');
      await prefs.setBool('widget_item_0_done', true);

      await prefs.setString('widget_item_1_time', '08.00');
      await prefs.setString('widget_item_1_title', 'Pengingat obat');
      await prefs.setBool('widget_item_1_done', true);

      await prefs.setString('widget_item_2_time', '12.30');
      await prefs.setString('widget_item_2_title', 'Makan siang');
      await prefs.setBool('widget_item_2_done', false);
    }

    if (prefs.getString('widget_next_meal_title') == null) {
      await prefs.setString('widget_next_meal_id', 'meal-lu-01');
      await prefs.setString('widget_next_meal_title', 'Nasi Merah, Ikan Kembung & Tumis Buncis');
      await prefs.setString('widget_next_meal_main_dish', 'Ikan Kembung Kukus Bumbu Kuning');
      await prefs.setString('widget_next_meal_time', '12.30');
      await prefs.setString('widget_next_meal_category', 'MAKAN_SIANG');
      await prefs.setInt('widget_next_meal_calories', 385);
      await prefs.setInt('widget_next_meal_cost', 13500);
      await prefs.setString('widget_next_meal_gi', 'RENDAH');
    }
  }

  

  /// Read current widget state from preferences (reflects in-place home screen widget clicks)
  static Future<Map<String, dynamic>> getWidgetState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'completedCount': prefs.getInt('widget_completed_count') ?? 2,
      'totalCount': prefs.getInt('widget_total_count') ?? 5,
      'progressText': prefs.getString('widget_progress_text') ?? '2/5',
      'item0Done': prefs.getBool('widget_item_0_done') ?? true,
      'item1Done': prefs.getBool('widget_item_1_done') ?? true,
      'item2Done': prefs.getBool('widget_item_2_done') ?? false,
      'nextMealIsEaten': prefs.getBool('widget_next_meal_is_eaten') ?? false,
      'checkinDone': prefs.getBool('widget_checkin_done_today') ?? false,
    };
  }

  /// Request Android OS to pin the widget to the home screen (Android 8.0+)
  static Future<bool> pinWidgetToHomeScreen({String type = 'compact'}) async {
    try {
      final success = await _channel.invokeMethod<bool>('pinWidget', {'type': type});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
