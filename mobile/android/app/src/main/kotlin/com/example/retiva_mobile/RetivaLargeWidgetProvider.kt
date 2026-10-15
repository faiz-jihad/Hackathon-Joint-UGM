package com.example.retiva_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.Toast

class RetivaLargeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        refreshAllWidgets(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return

        when (action) {
            ACTION_UPDATE_WIDGET, AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                refreshAllWidgets(context)
            }
            ACTION_TOGGLE_TASK -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, 0)
                handleToggleTask(context, taskIndex)
            }
            ACTION_TOGGLE_MEAL -> {
                handleToggleMeal(context)
            }
            ACTION_QUICK_CHECKIN -> {
                handleQuickCheckin(context)
            }
        }
    }

    private fun handleToggleTask(context: Context, taskIndex: Int) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val key = "widget_item_${taskIndex}_done"
            val currentDone = getSafeBoolean(prefs, key, false)
            val newDone = !currentDone
            val taskTitle = getSafeString(prefs, "widget_item_${taskIndex}_title", "Tugas ${taskIndex + 1}")

            var completedCount = getSafeInt(prefs, "widget_completed_count", 2)
            val totalCount = getSafeInt(prefs, "widget_total_count", 5)

            if (newDone) {
                completedCount = (completedCount + 1).coerceAtMost(totalCount)
            } else {
                completedCount = (completedCount - 1).coerceAtLeast(0)
            }
            val progressText = "$completedCount/$totalCount"
            val progressPercent = if (totalCount > 0) (completedCount * 100 / totalCount) else 0

            prefs.edit().apply {
                putBoolean("flutter.$key", newDone)
                putBoolean(key, newDone)

                putInt("flutter.widget_completed_count", completedCount)
                putInt("widget_completed_count", completedCount)

                putString("flutter.widget_progress_text", progressText)
                putString("widget_progress_text", progressText)

                putInt("flutter.widget_progress_percent", progressPercent)
                putInt("widget_progress_percent", progressPercent)
                apply()
            }

            val toastMsg = if (newDone) {
                "✅ Selesai: $taskTitle ($progressText)"
            } else {
                "↩️ Batal: $taskTitle ($progressText)"
            }
            Toast.makeText(context, toastMsg, Toast.LENGTH_SHORT).show()

            refreshAllWidgets(context)
        } catch (e: Exception) {
            android.util.Log.e("RetivaLargeWidget", "Error toggling task $taskIndex", e)
        }
    }

    private fun handleToggleMeal(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val currentEaten = getSafeBoolean(prefs, "widget_next_meal_is_eaten", false)
            val newEaten = !currentEaten
            val mealTitle = getSafeString(prefs, "widget_next_meal_title", "Menu Sehat")

            prefs.edit().apply {
                putBoolean("flutter.widget_next_meal_is_eaten", newEaten)
                putBoolean("widget_next_meal_is_eaten", newEaten)
                apply()
            }

            val toastMsg = if (newEaten) {
                "🍲 Dicatat: $mealTitle sudah dikonsumsi ✓"
            } else {
                "↩️ Status makan dibatalkan: $mealTitle"
            }
            Toast.makeText(context, toastMsg, Toast.LENGTH_SHORT).show()

            refreshAllWidgets(context)
        } catch (e: Exception) {
            android.util.Log.e("RetivaLargeWidget", "Error toggling meal", e)
        }
    }

    private fun handleQuickCheckin(context: Context) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val currentCheckin = getSafeBoolean(prefs, "widget_checkin_done_today", false)
            val newCheckin = !currentCheckin

            var completedCount = getSafeInt(prefs, "widget_completed_count", 2)
            val totalCount = getSafeInt(prefs, "widget_total_count", 5)
            if (newCheckin) {
                completedCount = (completedCount + 1).coerceAtMost(totalCount)
            } else {
                completedCount = (completedCount - 1).coerceAtLeast(0)
            }
            val progressText = "$completedCount/$totalCount"

            prefs.edit().apply {
                putBoolean("flutter.widget_checkin_done_today", newCheckin)
                putBoolean("widget_checkin_done_today", newCheckin)

                putInt("flutter.widget_completed_count", completedCount)
                putInt("widget_completed_count", completedCount)

                putString("flutter.widget_progress_text", progressText)
                putString("widget_progress_text", progressText)
                apply()
            }

            val toastMsg = if (newCheckin) {
                "❤️ Check-in harian tercatat: Kondisi stabil & mata baik ✓ ($progressText)"
            } else {
                "↩️ Check-in harian dibatalkan ($progressText)"
            }
            Toast.makeText(context, toastMsg, Toast.LENGTH_SHORT).show()

            refreshAllWidgets(context)
        } catch (e: Exception) {
            android.util.Log.e("RetivaLargeWidget", "Error in quick checkin", e)
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.retiva.ACTION_UPDATE_WIDGET"
        const val ACTION_TOGGLE_TASK = "com.example.retiva.ACTION_TOGGLE_TASK"
        const val ACTION_TOGGLE_MEAL = "com.example.retiva.ACTION_TOGGLE_MEAL"
        const val ACTION_QUICK_CHECKIN = "com.example.retiva.ACTION_QUICK_CHECKIN"
        const val ACTION_OPEN_AGENDA = "com.example.retiva.ACTION_OPEN_AGENDA"
        const val ACTION_OPEN_CHECKIN = "com.example.retiva.ACTION_OPEN_CHECKIN"
        const val ACTION_OPEN_MEAL = "com.example.retiva.ACTION_OPEN_MEAL"
        const val EXTRA_TASK_INDEX = "task_index"

        fun refreshAllWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)

                val largeWidget = ComponentName(context, RetivaLargeWidgetProvider::class.java)
                val largeIds = appWidgetManager.getAppWidgetIds(largeWidget)
                if (largeIds != null && largeIds.isNotEmpty()) {
                    for (id in largeIds) {
                        updateAppWidget(context, appWidgetManager, id)
                    }
                }

                val compactWidget = ComponentName(context, RetivaCompactWidgetProvider::class.java)
                val compactIds = appWidgetManager.getAppWidgetIds(compactWidget)
                if (compactIds != null && compactIds.isNotEmpty()) {
                    for (id in compactIds) {
                        RetivaCompactWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("RetivaLargeWidget", "Error refreshing widgets", e)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val progressText = getSafeString(prefs, "widget_progress_text", "2/5")

                val item0Time = getSafeString(prefs, "widget_item_0_time", "07.15")
                val item0Title = getSafeString(prefs, "widget_item_0_title", "Sarapan sehat")
                val item0Done = getSafeBoolean(prefs, "widget_item_0_done", true)

                val item1Time = getSafeString(prefs, "widget_item_1_time", "08.00")
                val item1Title = getSafeString(prefs, "widget_item_1_title", "Pengingat obat")
                val item1Done = getSafeBoolean(prefs, "widget_item_1_done", true)

                val item2Time = getSafeString(prefs, "widget_item_2_time", "12.30")
                val item2Title = getSafeString(prefs, "widget_item_2_title", "Makan siang")
                val item2Done = getSafeBoolean(prefs, "widget_item_2_done", false)

                // Smart Meal Data
                val mealTitle = getSafeString(prefs, "widget_next_meal_title", "Nasi Merah, Ikan Kembung & Buncis")
                val mealTime = getSafeString(prefs, "widget_next_meal_time", "12.30")
                val mealCalories = getSafeInt(prefs, "widget_next_meal_calories", 385).let { if (it > 0) it else 385 }
                val mealCost = getSafeInt(prefs, "widget_next_meal_cost", 13500).let { if (it > 0) it else 13500 }
                val mealIsEaten = getSafeBoolean(prefs, "widget_next_meal_is_eaten", false)
                val isCheckinDone = getSafeBoolean(prefs, "widget_checkin_done_today", false)

                val views = RemoteViews(context.packageName, R.layout.widget_retiva_large)

                // Header progress
                views.setTextViewText(R.id.widget_large_progress_badge, "$progressText Selesai")
                views.setTextViewText(R.id.widget_large_progress_label, "Progres hari ini: $progressText")

                // Item 1 (Interactive In-Place Click without entering app)
                views.setTextViewText(R.id.widget_large_item1_time, item0Time)
                views.setTextViewText(R.id.widget_large_item1_title, item0Title)
                views.setTextViewText(R.id.widget_large_item1_status, if (item0Done) "✓ Selesai" else "○ Tandai")
                views.setTextColor(R.id.widget_large_item1_status, Color.parseColor(if (item0Done) "#00C566" else "#246BFD"))
                views.setTextColor(R.id.widget_large_item1_title, Color.parseColor(if (item0Done) "#64748B" else "#0F172A"))

                val toggleIntent0 = Intent(context, RetivaLargeWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_INDEX, 0)
                }
                val pendingToggle0 = PendingIntent.getBroadcast(
                    context,
                    1001,
                    toggleIntent0,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_item1_row, pendingToggle0)
                views.setOnClickPendingIntent(R.id.widget_large_item1_status, pendingToggle0)

                // Item 2 (Interactive In-Place Click without entering app)
                views.setTextViewText(R.id.widget_large_item2_time, item1Time)
                views.setTextViewText(R.id.widget_large_item2_title, item1Title)
                views.setTextViewText(R.id.widget_large_item2_status, if (item1Done) "✓ Selesai" else "○ Tandai")
                views.setTextColor(R.id.widget_large_item2_status, Color.parseColor(if (item1Done) "#00C566" else "#246BFD"))
                views.setTextColor(R.id.widget_large_item2_title, Color.parseColor(if (item1Done) "#64748B" else "#0F172A"))

                val toggleIntent1 = Intent(context, RetivaLargeWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_INDEX, 1)
                }
                val pendingToggle1 = PendingIntent.getBroadcast(
                    context,
                    1002,
                    toggleIntent1,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_item2_row, pendingToggle1)
                views.setOnClickPendingIntent(R.id.widget_large_item2_status, pendingToggle1)

                // Item 3 (Interactive In-Place Click without entering app)
                views.setTextViewText(R.id.widget_large_item3_time, item2Time)
                views.setTextViewText(R.id.widget_large_item3_title, item2Title)
                views.setTextViewText(R.id.widget_large_item3_status, if (item2Done) "✓ Selesai" else "○ Tandai")
                views.setTextColor(R.id.widget_large_item3_status, Color.parseColor(if (item2Done) "#00C566" else "#246BFD"))
                views.setTextColor(R.id.widget_large_item3_title, Color.parseColor(if (item2Done) "#64748B" else "#0F172A"))

                val toggleIntent2 = Intent(context, RetivaLargeWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_INDEX, 2)
                }
                val pendingToggle2 = PendingIntent.getBroadcast(
                    context,
                    1003,
                    toggleIntent2,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_item3_row, pendingToggle2)
                views.setOnClickPendingIntent(R.id.widget_large_item3_status, pendingToggle2)

                // Smart Meal section (Interactive In-Place Click without entering app)
                views.setTextViewText(R.id.widget_large_meal_time, "· $mealTime")
                views.setTextViewText(R.id.widget_large_meal_title, mealTitle)
                val mealSubtitle = if (mealIsEaten) {
                    "Sudah dikonsumsi ✓ · Rekomendasi Gizi Seimbang"
                } else {
                    "$mealCalories kkal · Rendah IG · Est. Rp ${String.format("%,d", mealCost)}"
                }
                views.setTextViewText(R.id.widget_large_meal_subtitle, mealSubtitle)
                views.setTextViewText(R.id.widget_large_btn_meal, if (mealIsEaten) "Sudah ✓" else "Catat Makan")
                views.setTextColor(R.id.widget_large_btn_meal, Color.parseColor(if (mealIsEaten) "#00C566" else "#246BFD"))

                val toggleMealIntent = Intent(context, RetivaLargeWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_MEAL
                }
                val pendingToggleMeal = PendingIntent.getBroadcast(
                    context,
                    1004,
                    toggleMealIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_btn_meal, pendingToggleMeal)

                // Quick Check-in button (Interactive In-Place Click without entering app)
                views.setTextViewText(R.id.widget_large_btn_checkin, if (isCheckinDone) "Check-in ✓" else "Check-in Cepat")
                views.setTextColor(R.id.widget_large_btn_checkin, Color.parseColor(if (isCheckinDone) "#00C566" else "#246BFD"))
                val quickCheckInIntent = Intent(context, RetivaLargeWidgetProvider::class.java).apply {
                    action = ACTION_QUICK_CHECKIN
                }
                val pendingQuickCheckIn = PendingIntent.getBroadcast(
                    context,
                    1005,
                    quickCheckInIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_btn_checkin, pendingQuickCheckIn)

                // Navigation: Open Agenda screen in App when tapping "Buka agenda" or Header badge
                val agendaIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_AGENDA
                    putExtra("route", "daily_care_agenda")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingAgenda = PendingIntent.getActivity(
                    context,
                    202,
                    agendaIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_btn_agenda, pendingAgenda)
                views.setOnClickPendingIntent(R.id.widget_large_progress_badge, pendingAgenda)

                // Meal card body tap -> opens smart_meal_detail in app
                val mealIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_MEAL
                    putExtra("route", "smart_meal_detail")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingMeal = PendingIntent.getActivity(
                    context,
                    203,
                    mealIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_large_meal_card, pendingMeal)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("RetivaLargeWidget", "Error updating large widget $appWidgetId", e)
            }
        }

        private fun getSafeString(prefs: SharedPreferences, key: String, default: String): String {
            return try {
                val all = prefs.all
                val v = all["flutter.$key"] ?: all[key]
                v?.toString() ?: default
            } catch (_: Exception) {
                default
            }
        }

        private fun getSafeBoolean(prefs: SharedPreferences, key: String, default: Boolean): Boolean {
            return try {
                val all = prefs.all
                val v = all["flutter.$key"] ?: all[key]
                when (v) {
                    is Boolean -> v
                    is String -> v.toBooleanStrictOrNull() ?: default
                    is Number -> v.toInt() != 0
                    else -> default
                }
            } catch (_: Exception) {
                default
            }
        }

        private fun getSafeInt(prefs: SharedPreferences, key: String, default: Int): Int {
            return try {
                val all = prefs.all
                val v = all["flutter.$key"] ?: all[key]
                when (v) {
                    is Number -> v.toInt()
                    is String -> v.toIntOrNull() ?: default
                    else -> default
                }
            } catch (_: Exception) {
                default
            }
        }
    }
}
