import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set standard status bar style for clinical app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RetivaMobileApp());
}

class RetivaMobileApp extends StatelessWidget {
  const RetivaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(title: 'RETIVA Mobile'),
    );
  }
}
