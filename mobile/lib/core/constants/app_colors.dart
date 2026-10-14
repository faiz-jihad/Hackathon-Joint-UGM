import 'package:flutter/material.dart';

/// AppColors — Medica Design System Theme
/// Diadaptasi sesuai tema & gaya desain modern "Medica Healthcare UI Kit":
/// - Electric Royal Blue (#246BFD) sebagai warna utama yang cerah & ramah
/// - Soft pastel surfaces (#F0F5FF, #E8F8F0, #FFF8E1, #FEECEE)
/// - Modern neutral grays (#1A1D26, #4B5563, #9E9E9E, #F8FAFC)
class AppColors {
  // Brand Primary & Medical Electric Blue (Medica Style)
  static const Color primary = Color(0xFF246BFD);             // #246bfd - Medica Electric Royal Blue
  static const Color primaryDark = Color(0xFF1A56DB);         // #1a56db - Deep Blue Accent
  static const Color primaryLight = Color(0xFF5089FD);        // #5089fd - Bright Sky Blue
  static const Color primarySurface = Color(0xFFF0F5FF);      // #f0f5ff - Soft Pastel Blue Canvas

  // Legacy Figma Blue compatibility tokens (mapped to Medica Electric Blue)
  static const Color figmaBlue = Color(0xFF246BFD);           // Medica Electric Blue
  static const Color figmaBlueDark = Color(0xFF1A56DB);       // Deep Accent Blue
  static const Color figmaBlueLink = Color(0xFF246BFD);       // Link Accent
  static const Color figmaBlueSurface = Color(0xFFF0F5FF);    // Soft Blue Surface
  static const Color figmaBlueChip = Color(0xFFEEF4FF);       // Chip Pill Background
  static const Color figmaAnalyzeBg = Color(0xFFEEF4FF);      // Analyze Card Icon Surface
  static const Color figmaHumanReviewBg = Color(0xFFF5F3FF);  // Human Review Card Icon Surface

  // Retake / Alert Clinical Palette
  static const Color figmaRetakeRed = Color(0xFFF75555);      // #f75555 - Medica Coral Red
  static const Color figmaRetakeSurface = Color(0xFFFEECEE);  // #feecee - Soft Coral Red Surface
  static const Color figmaRetakeDark = Color(0xFFD32F2F);     // #d32f2f - Dark Red Text

  // Typography Color Tokens
  static const Color figmaTextHeading = Color(0xFF1A1D26);    // #1a1d26 - Modern Dark Charcoal Heading
  static const Color figmaTextBody = Color(0xFF4B5563);       // #4b5563 - Clean Body Text
  static const Color figmaTextMuted = Color(0xFF9E9E9E);      // #9e9e9e - Soft Slate / Muted
  static const Color figmaIndicatorBar = Color(0xFFE2E8F0);   // #e2e8f0 - Home Indicator / Divider

  // Secondary Accents
  static const Color secondary = Color(0xFF3B82F6);           // Secondary Sky Blue
  static const Color secondarySurface = Color(0xFFEFF6FF);

  // Neutral & Slate Tones
  static const Color background = Color(0xFFF8FAFC);          // #f8fafc - Medica Clean Canvas
  static const Color surface = Color(0xFFFFFFFF);             // Pure Card White
  static const Color textPrimary = Color(0xFF1A1D26);         // #1a1d26
  static const Color textSecondary = Color(0xFF4B5563);       // #4b5563
  static const Color textMuted = Color(0xFF9E9E9E);           // #9e9e9e
  static const Color border = Color(0xFFF1F5F9);              // Slate 100
  static const Color borderCard = Color(0xFFE2E8F0);          // Slate 200
  static const Color divider = Color(0xFFF1F5F9);             // Slate 100

  // Medical Triage & Reliability Severity Colors (Medica Bright Tones)
  static const Color statusGreen = Color(0xFF00C566);         // #00c566 - Medica Mint / Emerald
  static const Color statusGreenSurface = Color(0xFFE8F8F0);  // Soft Emerald Tint
  static const Color statusGreenDark = Color(0xFF008A44);     // Deep Green Text
  static const Color statusGreenSuccess = Color(0xFF008A44);

  static const Color statusYellow = Color(0xFFFF9800);        // #ff9800 - Medica Warm Amber
  static const Color statusYellowSurface = Color(0xFFFFF8E1); // Soft Amber Tint

  static const Color statusOrange = Color(0xFFFF7A00);        // Severe NPDR Orange
  static const Color statusOrangeSurface = Color(0xFFFFF4EC);

  static const Color statusRed = Color(0xFFF75555);           // #f75555 - Medica Coral Red
  static const Color statusRedSurface = Color(0xFFFEECEE);    // Soft Red Tint

  static const Color statusPurple = Color(0xFF8B5CF6);        // Medica Purple Accent
  static const Color statusPurpleSurface = Color(0xFFF5F3FF); // Soft Violet Tint

  // Eye Position Badges
  static const Color eyeOD = Color(0xFF246BFD);               // Oculus Dexter (Right)
  static const Color eyeOS = Color(0xFF00C566);               // Oculus Sinister (Left)

  // Camera Viewfinder & Reticle
  static const Color cameraViewportBg = Color(0xFF0F172A);
  static const Color reticleBorder = Color(0xFF5089FD);

  // Medica Card & Button Shadows
  static const List<BoxShadow> primaryButtonShadow = [
    BoxShadow(
      color: Color(0x40246BFD),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0A246BFD),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}
