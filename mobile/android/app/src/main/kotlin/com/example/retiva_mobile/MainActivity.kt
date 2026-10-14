package com.example.retiva_mobile

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.retiva/widget"
    private var pendingRoute: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
        pendingRoute?.let { route ->
            methodChannel?.invokeMethod("onNavigateRoute", route)
        }
    }

    private fun handleWidgetIntent(intent: Intent?) {
        if (intent == null) return
        val route = intent.getStringExtra("route")
        if (route != null) {
            pendingRoute = route
        } else if (intent.action == RetivaCompactWidgetProvider.ACTION_OPEN_AGENDA ||
            intent.action == RetivaLargeWidgetProvider.ACTION_OPEN_AGENDA
        ) {
            pendingRoute = "daily_care_agenda"
        } else if (intent.action == RetivaLargeWidgetProvider.ACTION_OPEN_CHECKIN) {
            pendingRoute = "daily_health_checkin"
        } else if (intent.action == RetivaLargeWidgetProvider.ACTION_OPEN_MEAL) {
            pendingRoute = "smart_meal_detail"
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidgets" -> {
                        updateAllWidgets()
                        result.success(true)
                    }
                    "getInitialRoute" -> {
                        val route = pendingRoute
                        pendingRoute = null
                        result.success(route)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun updateAllWidgets() {
        val appWidgetManager = AppWidgetManager.getInstance(this)

        // Update Compact Widget
        val compactComponent = ComponentName(this, RetivaCompactWidgetProvider::class.java)
        val compactIds = appWidgetManager.getAppWidgetIds(compactComponent)
        for (id in compactIds) {
            RetivaCompactWidgetProvider.updateAppWidget(this, appWidgetManager, id)
        }

        // Update Large Widget
        val largeComponent = ComponentName(this, RetivaLargeWidgetProvider::class.java)
        val largeIds = appWidgetManager.getAppWidgetIds(largeComponent)
        for (id in largeIds) {
            RetivaLargeWidgetProvider.updateAppWidget(this, appWidgetManager, id)
        }
    }
}
