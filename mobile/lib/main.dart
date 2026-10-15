import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/daily_care_agenda_screen.dart';
import 'presentation/screens/daily_health_checkin_screen.dart';
import 'presentation/screens/smart_meal_detail_screen.dart';
import 'presentation/screens/sos_activation_screen.dart';

import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/top_doctors_screen.dart';
import 'presentation/screens/care_companion_hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set modern translucent status bar style matching Medica aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RetivaMobileApp());
}

class RetivaMobileApp extends StatefulWidget {
  const RetivaMobileApp({super.key});

  @override
  State<RetivaMobileApp> createState() => _RetivaMobileAppState();
}

class _RetivaMobileAppState extends State<RetivaMobileApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const MethodChannel _channel = MethodChannel('com.example.retiva/widget');

  @override
  void initState() {
    super.initState();
    _initWidgetNavigation();
  }

  void _initWidgetNavigation() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNavigateRoute') {
        final route = call.arguments?.toString();
        _navigateToWidgetRoute(route);
      }
    });

    // Check for initial launch from widget
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Small pause to allow root navigator to mount on cold start
      await Future.delayed(const Duration(milliseconds: 250));
      try {
        final initialRoute = await _channel.invokeMethod<String>('getInitialRoute');
        if (initialRoute != null && initialRoute.isNotEmpty) {
          _navigateToWidgetRoute(initialRoute);
        }
      } catch (_) {}
    });
  }

  Future<void> _navigateToWidgetRoute(String? route) async {
    if (route == null || route.isEmpty) return;

    // Retry loop to ensure _navigatorKey.currentState is mounted
    for (int attempt = 0; attempt < 20; attempt++) {
      final navState = _navigatorKey.currentState;
      if (navState != null) {
        Widget destination;
        switch (route) {
          case 'daily_care_agenda':
            destination = const DailyCareAgendaScreen();
            break;
          case 'daily_health_checkin':
            destination = const DailyHealthCheckinScreen();
            break;
          case 'smart_meal_detail':
            destination = const SmartMealDetailScreen();
            break;
          case 'sos_activation':
            destination = const SosActivationScreen();
            break;
          case 'profile':
            destination = const ProfileScreen();
            break;
          case 'top_doctors':
            destination = const TopDoctorsScreen();
            break;
          case 'care_companion':
            destination = const CareCompanionHubScreen();
            break;
          default:
            return;
        }
        navState.push(MaterialPageRoute(builder: (_) => destination));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RETIVA — Skrining Retinopati Diabetik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.statusRed, width: 1.2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(title: 'RETIVA Mobile'),
    );
  }
}
