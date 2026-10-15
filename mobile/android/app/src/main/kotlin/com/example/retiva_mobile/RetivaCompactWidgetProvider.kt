package com.example.retiva_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.Toast

class RetivaCompactWidgetProvider : AppWidgetProvider() {

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
        RetivaLargeWidgetProvider.refreshAllWidgets(context)
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
                RetivaLargeWidgetProvider.refreshAllWidgets(context)
            }
            ACTION_TOGGLE_TASK -> {
                val taskIndex = intent.getIntExtra(EXTRA_TASK_INDEX, 0)
                handleToggleTask(context, taskIndex)
            }
        }
    }

    private fun handleToggleTask(context: Context, taskIndex: Int) {
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val key = "widget_item_${taskIndex}_done"
            val currentDone = getSafeBoolean(prefs, key, false)
            val newDone = !currentDone
            val taskTitle = getSafeString(prefs, "widget_item_${taskIndex}_title", "Tugas")

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

            RetivaLargeWidgetProvider.refreshAllWidgets(context)
        } catch (e: Exception) {
            android.util.Log.e("RetivaCompactWidget", "Error toggling compact task", e)
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.retiva.ACTION_UPDATE_WIDGET"
        const val ACTION_TOGGLE_TASK = "com.example.retiva.ACTION_TOGGLE_TASK"
        const val ACTION_OPEN_AGENDA = "com.example.retiva.ACTION_OPEN_AGENDA"
        const val EXTRA_TASK_INDEX = "task_index"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                val nextTime = getSafeString(prefs, "widget_next_activity_time", "07.15")
                val nextTitle = getSafeString(prefs, "widget_next_activity_title", "Sarapan sehat")
                val progressText = getSafeString(prefs, "widget_progress_text", "2/5")
                val mascotMsg = getSafeString(prefs, "widget_mascot_message", "Halo! Semangat hari ini 💙")
                val nextCategory = getSafeString(prefs, "widget_next_activity_category", "MEAL")
                val nextDone = getSafeBoolean(prefs, "widget_item_0_done", false)

                val isMeal = nextCategory.equals("MEAL", ignoreCase = true)
                val labelText = if (isMeal) "Menu Sehat · $nextTime" else "Berikutnya · $nextTime"

                val views = RemoteViews(context.packageName, R.layout.widget_retiva_compact)

                views.setTextViewText(R.id.widget_compact_greeting, mascotMsg)
                views.setTextViewText(R.id.widget_compact_next_label, labelText)
                views.setTextViewText(R.id.widget_compact_next_title, nextTitle)
                views.setTextColor(R.id.widget_compact_next_title, Color.parseColor(if (nextDone) "#64748B" else "#0F172A"))
                views.setTextViewText(R.id.widget_compact_progress, progressText)
                views.setTextViewText(R.id.widget_compact_progress_sub, "Agenda selesai: $progressText")

                // Button: In-place Task Toggle without entering the app!
                views.setTextViewText(R.id.widget_compact_btn_agenda, if (nextDone) "Selesai ✓" else "Selesaikan ✓")

                val toggleIntent0 = Intent(context, RetivaCompactWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_INDEX, 0)
                }
                val pendingToggle0 = PendingIntent.getBroadcast(
                    context,
                    3001,
                    toggleIntent0,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_compact_btn_agenda, pendingToggle0)
                views.setOnClickPendingIntent(R.id.widget_compact_next_title, pendingToggle0)

                // Background Root click: Opens Agenda in full app
                val agendaIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_AGENDA
                    putExtra("route", "daily_care_agenda")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingAgenda = PendingIntent.getActivity(
                    context,
                    101,
                    agendaIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_compact_root, pendingAgenda)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("RetivaCompactWidget", "Error updating compact widget $appWidgetId", e)
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
