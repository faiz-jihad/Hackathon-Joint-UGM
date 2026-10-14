package com.example.retiva_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == ACTION_UPDATE_WIDGET
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RetivaLargeWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.retiva.ACTION_UPDATE_WIDGET"
        const val ACTION_OPEN_AGENDA = "com.example.retiva.ACTION_OPEN_AGENDA"
        const val ACTION_OPEN_CHECKIN = "com.example.retiva.ACTION_OPEN_CHECKIN"
        const val ACTION_OPEN_MEAL = "com.example.retiva.ACTION_OPEN_MEAL"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val progressText = prefs.getString("flutter.widget_progress_text", null)
                ?: prefs.getString("widget_progress_text", "2/5")

            val item0Time = prefs.getString("flutter.widget_item_0_time", null)
                ?: prefs.getString("widget_item_0_time", "07.15")
            val item0Title = prefs.getString("flutter.widget_item_0_title", null)
                ?: prefs.getString("widget_item_0_title", "Sarapan sehat")
            val item0Done = prefs.getBoolean("flutter.widget_item_0_done", true)

            val item1Time = prefs.getString("flutter.widget_item_1_time", null)
                ?: prefs.getString("widget_item_1_time", "08.00")
            val item1Title = prefs.getString("flutter.widget_item_1_title", null)
                ?: prefs.getString("widget_item_1_title", "Pengingat obat")
            val item1Done = prefs.getBoolean("flutter.widget_item_1_done", true)

            val item2Time = prefs.getString("flutter.widget_item_2_time", null)
                ?: prefs.getString("widget_item_2_time", "12.30")
            val item2Title = prefs.getString("flutter.widget_item_2_title", null)
                ?: prefs.getString("widget_item_2_title", "Makan siang")
            val item2Done = prefs.getBoolean("flutter.widget_item_2_done", false)

            // Smart Meal Data
            val mealTitle = prefs.getString("flutter.widget_next_meal_title", null)
                ?: prefs.getString("widget_next_meal_title", "Nasi Merah, Ikan Kembung & Buncis")
            val mealTime = prefs.getString("flutter.widget_next_meal_time", null)
                ?: prefs.getString("widget_next_meal_time", "12.30")
            val mealCalories = prefs.getInt("flutter.widget_next_meal_calories", 0).let { if (it > 0) it else 385 }
            val mealCost = prefs.getInt("flutter.widget_next_meal_cost", 0).let { if (it > 0) it else 13500 }
            val mealIsEaten = prefs.getBoolean("flutter.widget_next_meal_is_eaten", false)

            val views = RemoteViews(context.packageName, R.layout.widget_retiva_large)

            // Header progress
            views.setTextViewText(R.id.widget_large_progress_badge, "$progressText Selesai")
            views.setTextViewText(R.id.widget_large_progress_label, "Progres hari ini: $progressText")

            // Item 1
            views.setTextViewText(R.id.widget_large_item1_time, item0Time)
            views.setTextViewText(R.id.widget_large_item1_title, item0Title)
            views.setTextViewText(R.id.widget_large_item1_status, if (item0Done) "✓" else "○")

            // Item 2
            views.setTextViewText(R.id.widget_large_item2_time, item1Time)
            views.setTextViewText(R.id.widget_large_item2_title, item1Title)
            views.setTextViewText(R.id.widget_large_item2_status, if (item1Done) "✓" else "○")

            // Item 3
            views.setTextViewText(R.id.widget_large_item3_time, item2Time)
            views.setTextViewText(R.id.widget_large_item3_title, item2Title)
            views.setTextViewText(R.id.widget_large_item3_status, if (item2Done) "✓" else "○")

            // Smart Meal section
            views.setTextViewText(R.id.widget_large_meal_time, "· $mealTime")
            views.setTextViewText(R.id.widget_large_meal_title, mealTitle)
            val mealSubtitle = if (mealIsEaten) {
                "Sudah dikonsumsi ✓ · Rekomendasi Gizi Seimbang"
            } else {
                "$mealCalories kkal · Rendah IG · Est. Rp ${String.format("%,d", mealCost)}"
            }
            views.setTextViewText(R.id.widget_large_meal_subtitle, mealSubtitle)

            // Action: Smart Meal button & Card click -> ACTION_OPEN_MEAL
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
            views.setOnClickPendingIntent(R.id.widget_large_btn_meal, pendingMeal)
            views.setOnClickPendingIntent(R.id.widget_large_meal_card, pendingMeal)

            // Action: Check-in button
            val checkInIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_CHECKIN
                putExtra("route", "daily_health_checkin")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingCheckIn = PendingIntent.getActivity(
                context,
                201,
                checkInIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_large_btn_checkin, pendingCheckIn)

            // Action: Agenda button & Root click
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
            views.setOnClickPendingIntent(R.id.widget_large_root, pendingAgenda)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
