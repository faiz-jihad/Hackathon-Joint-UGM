import 'package:flutter/material.dart';

class AppColors {
  // Primary Clinical Palette (Teal & Emerald)
  static const Color primaryDark = Color(0xFF0F766E);     // Dark Teal
  static const Color primary = Color(0xFF0D9488);         // Clinical Teal
  static const Color primaryLight = Color(0xFF14B8A6);    // Vibrant Aqua
  static const Color primarySurface = Color(0xFFF0FDFA);  // Pale Mint Background

  // Secondary Accents
  static const Color secondary = Color(0xFF0284C7);       // Sky Blue (BPJS / Info)
  static const Color secondarySurface = Color(0xFFF0F9FF);

  // Neutral & Slate Tones (Calm Medical Readability)
  static const Color background = Color(0xFFF8FAFC);      // Off-white canvas
  static const Color surface = Color(0xFFFFFFFF);         // Pure Card White
  static const Color textPrimary = Color(0xFF0F172A);     // Slate 900
  static const Color textSecondary = Color(0xFF475569);   // Slate 600
  static const Color textMuted = Color(0xFF94A3B8);       // Slate 400
  static const Color border = Color(0xFFE2E8F0);          // Slate 200
  static const Color divider = Color(0xFFF1F5F9);         // Slate 100

  // Medical Triage & Reliability Severity Colors (ICDR Standards)
  static const Color statusGreen = Color(0xFF10B981);     // No DR / Pass (Emerald)
  static const Color statusGreenSurface = Color(0xFFECFDF5);

  static const Color statusYellow = Color(0xFFF59E0B);    // Mild / Moderate (Amber)
  static const Color statusYellowSurface = Color(0xFFFFFBEB);

  static const Color statusOrange = Color(0xFFEA580C);    // Severe NPDR (Orange)
  static const Color statusOrangeSurface = Color(0xFFFFF7ED);

  static const Color statusRed = Color(0xFFDC2626);       // PDR / Quality Fail (Rose/Red)
  static const Color statusRedSurface = Color(0xFFFEF2F2);

  static const Color statusPurple = Color(0xFF7C3AED);    // Human Review / Specialist
  static const Color statusPurpleSurface = Color(0xFFF5F3FF);

  // Eye Position Badges
  static const Color eyeOD = Color(0xFF0284C7);           // Oculus Dexter (Right)
  static const Color eyeOS = Color(0xFF0D9488);           // Oculus Sinister (Left)

  // Camera Viewfinder & Reticle
  static const Color cameraViewportBg = Color(0xFF0F172A);
  static const Color reticleBorder = Color(0xFF38BDF8);
}
