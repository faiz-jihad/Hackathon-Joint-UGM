import 'package:flutter/material.dart';

class AppColors {
  // Authoritative Figma Brand Palette (Royal Medical Blue & Clinical Tones)
  static const Color figmaBlue = Color(0xFF0D47A1);          // #0d47a1 - Primary Brand Blue
  static const Color figmaBlueDark = Color(0xFF003178);      // #003178 - Dark Blue
  static const Color figmaBlueLink = Color(0xFF0061A4);      // #0061a4 - Link & Accent Blue
  static const Color figmaBlueSurface = Color(0xFFE3F2FD);   // #e3f2fd - Light Blue Surface
  static const Color figmaBlueChip = Color(0xFFE7F6FF);      // #e7f6ff - Chip & Card Pill Background
  static const Color figmaAnalyzeBg = Color(0xFFD9EBF5);     // #d9ebf5 - Analyze Card Icon Surface
  static const Color figmaHumanReviewBg = Color(0xFFD1E4FF); // #d1e4ff - Human Review Card Icon Surface

  // Figma Retake Clinical Palette
  static const Color figmaRetakeRed = Color(0xFFBA1A1A);     // #ba1a1a - Retake Title Red
  static const Color figmaRetakeSurface = Color(0xFFFFDAD6); // #ffdad6 - Retake Chip Background
  static const Color figmaRetakeDark = Color(0xFF93000A);    // #93000a - Retake Chip Text

  // Figma Typography Color Tokens
  static const Color figmaTextHeading = Color(0xFF0D1E25);   // #0d1e25 - Section Headings
  static const Color figmaTextBody = Color(0xFF434652);      // #434652 - Description & Card Body Text
  static const Color figmaTextMuted = Color(0xFF64748B);     // #64748b - Slate 500 Metadata
  static const Color figmaIndicatorBar = Color(0xFFCBD5E1);  // #cbd5e1 - Home Indicator

  // Primary Clinical Palette
  static const Color primaryDark = Color(0xFF003178);        // Deep Royal Blue
  static const Color primary = Color(0xFF0D47A1);            // Clinical Royal Blue (Figma 1:1)
  static const Color primaryLight = Color(0xFF1E88E5);       // Sky Accent
  static const Color primarySurface = Color(0xFFE3F2FD);     // Pale Blue Canvas

  // Secondary Accents
  static const Color secondary = Color(0xFF0061A4);          // Sky Blue (BPJS / Info)
  static const Color secondarySurface = Color(0xFFE7F6FF);

  // Neutral & Slate Tones
  static const Color background = Color(0xFFF8FAFC);         // #f8fafc - Off-white canvas
  static const Color surface = Color(0xFFFFFFFF);            // Pure Card White
  static const Color textPrimary = Color(0xFF0F172A);        // Slate 900
  static const Color textSecondary = Color(0xFF475569);      // Slate 600
  static const Color textMuted = Color(0xFF64748B);          // Slate 500
  static const Color border = Color(0xFFF1F5F9);             // Slate 100
  static const Color borderCard = Color(0xFFE2E8F0);         // Slate 200
  static const Color divider = Color(0xFFF1F5F9);            // Slate 100

  // Medical Triage & Reliability Severity Colors (ICDR Standards)
  static const Color statusGreen = Color(0xFF10B981);        // No DR / Pass (Emerald)
  static const Color statusGreenSurface = Color(0xFFECFDF5);
  static const Color statusGreenDark = Color(0xFF00564D);     // Figma Chip Text: #00564d
  static const Color statusGreenSuccess = Color(0xFF003D36);  // Figma Normal Result: #003d36

  static const Color statusYellow = Color(0xFFF59E0B);       // Mild / Moderate (Amber)
  static const Color statusYellowSurface = Color(0xFFFFFBEB);

  static const Color statusOrange = Color(0xFFEA580C);       // Severe NPDR (Orange)
  static const Color statusOrangeSurface = Color(0xFFFFF7ED);

  static const Color statusRed = Color(0xFFDC2626);          // PDR / Quality Fail (Rose/Red)
  static const Color statusRedSurface = Color(0xFFFEF2F2);

  static const Color statusPurple = Color(0xFF7C3AED);       // Human Review / Specialist
  static const Color statusPurpleSurface = Color(0xFFF5F3FF);

  // Eye Position Badges
  static const Color eyeOD = Color(0xFF0284C7);              // Oculus Dexter (Right)
  static const Color eyeOS = Color(0xFF0D9488);              // Oculus Sinister (Left)

  // Camera Viewfinder & Reticle
  static const Color cameraViewportBg = Color(0xFF0F172A);
  static const Color reticleBorder = Color(0xFF38BDF8);
}
