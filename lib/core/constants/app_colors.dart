import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dynamic Brand & Accents (Driven by Windows System Accent Color)
  static Color primary = const Color(0xFF00D2C4);
  static Color primaryGlow = const Color(0x3300D2C4);
  static const Color secondary = Color(0xFF6366F1);
  static const Color accent = Color(0xFF38BDF8);

  // Dynamic Background & Surfaces (Driven by Windows Dark/Light mode)
  static Color background = const Color(0xFF0B0F19);
  static Color surface = const Color(0xFF131C2E);
  static Color surfaceLight = const Color(0xFF1E293B);
  static Color surfaceBorder = const Color(0xFF2E3D56);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Dynamic Text colors
  static Color textPrimary = const Color(0xFFF8FAFC);
  static Color textSecondary = const Color(0xFF94A3B8);
  static Color textMuted = const Color(0xFF64748B);

  /// Updates all color palettes dynamically when Windows theme or accent color changes
  static void updateTheme(bool isDark, Color systemAccent) {
    primary = systemAccent;
    primaryGlow = systemAccent.withValues(alpha: 0.25);

    if (isDark) {
      background = const Color(0xFF0B0F19);
      surface = const Color(0xFF131C2E);
      surfaceLight = const Color(0xFF1E293B);
      surfaceBorder = const Color(0xFF2E3D56);

      textPrimary = const Color(0xFFF8FAFC);
      textSecondary = const Color(0xFF94A3B8);
      textMuted = const Color(0xFF64748B);
    } else {
      background = const Color(0xFFF1F5F9);
      surface = const Color(0xFFFFFFFF);
      surfaceLight = const Color(0xFFF8FAFC);
      surfaceBorder = const Color(0xFFCBD5E1);

      textPrimary = const Color(0xFF0F172A);
      textSecondary = const Color(0xFF334155);
      textMuted = const Color(0xFF64748B);
    }
  }
}
