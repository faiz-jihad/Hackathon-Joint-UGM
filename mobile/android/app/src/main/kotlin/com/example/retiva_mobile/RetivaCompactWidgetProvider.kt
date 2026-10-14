package com.example.retiva_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == ACTION_UPDATE_WIDGET
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, RetivaCompactWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.example.retiva.ACTION_UPDATE_WIDGET"
        const val ACTION_OPEN_AGENDA = "com.example.retiva.ACTION_OPEN_AGENDA"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // Read preferences safely with Flutter prefix fallback
            val nextTime = prefs.getString("flutter.widget_next_activity_time", null)
                ?: prefs.getString("widget_next_activity_time", "07.15")
            val nextTitle = prefs.getString("flutter.widget_next_activity_title", null)
                ?: prefs.getString("widget_next_activity_title", "Sarapan sehat")
            val progressText = prefs.getString("flutter.widget_progress_text", null)
                ?: prefs.getString("widget_progress_text", "2/5")
            val mascotMsg = prefs.getString("flutter.widget_mascot_message", null)
                ?: prefs.getString("widget_mascot_message", "Halo! Semangat hari ini 💙")

            val views = RemoteViews(context.packageName, R.layout.widget_retiva_compact)

            views.setTextViewText(R.id.widget_compact_greeting, mascotMsg)
            views.setTextViewText(R.id.widget_compact_next_label, "Berikutnya · $nextTime")
            views.setTextViewText(R.id.widget_compact_next_title, nextTitle)
            views.setTextViewText(R.id.widget_compact_progress, progressText)
            views.setTextViewText(R.id.widget_compact_progress_sub, "Agenda selesai: $progressText")

            // Intent to open Agenda screen
            val agendaIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_OPEN_AGENDA
                putExtra("route", "daily_care_agenda")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                101,
                agendaIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_compact_btn_agenda, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_compact_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
