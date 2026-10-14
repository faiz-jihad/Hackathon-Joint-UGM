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
        } else if (intent.action == "com.example.retiva.ACTION_OPEN_SOS" || route == "sos_activation") {
            pendingRoute = "sos_activation"
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Widget MethodChannel
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

        // 2. Emergency Location MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.retiva/emergency_location").setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> {
                    try {
                        val locationManager = getSystemService(android.content.Context.LOCATION_SERVICE) as? android.location.LocationManager
                        var bestLocation: android.location.Location? = null
                        if (locationManager != null) {
                            val providers = locationManager.getProviders(true)
                            for (provider in providers) {
                                try {
                                    val l = locationManager.getLastKnownLocation(provider) ?: continue
                                    if (bestLocation == null || l.accuracy < bestLocation.accuracy) {
                                        bestLocation = l
                                    }
                                } catch (_: SecurityException) {
                                    // Permissions handled gracefully
                                }
                            }
                        }

                        if (bestLocation != null) {
                            val map = HashMap<String, Any>()
                            map["latitude"] = bestLocation.latitude
                            map["longitude"] = bestLocation.longitude
                            map["accuracy"] = bestLocation.accuracy.toDouble()
                            map["address"] = "Mlati, Sleman, D.I. Yogyakarta"
                            result.success(map)
                        } else {
                            // Fallback simulation location for testing
                            val map = HashMap<String, Any>()
                            map["latitude"] = -7.7681
                            map["longitude"] = 110.3725
                            map["accuracy"] = 12.5
                            map["address"] = "Puskesmas Mlati II, Sleman, D.I. Yogyakarta"
                            result.success(map)
                        }
                    } catch (e: Exception) {
                        val map = HashMap<String, Any>()
                        map["latitude"] = -7.7681
                        map["longitude"] = 110.3725
                        map["accuracy"] = 15.0
                        map["address"] = "Sleman, D.I. Yogyakarta"
                        result.success(map)
                    }
                }
                else -> result.notImplemented()
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
