import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE8F0FE);

  // Secondary Colors
  static const Color secondary = Color(0xFF34A853);
  static const Color secondaryDark = Color(0xFF0B5E2E);
  static const Color secondaryLight = Color(0xFFE6F4EA);

  // Accent Colors
  static const Color accent = Color(0xFFFBBC04);
  static const Color warning = Color(0xFFEA4335);

  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
  static const Color textDisabled = Color(0xFFBDC1C6);

  // Border Colors
  static const Color border = Color(0xFFDADCE0);
  static const Color divider = Color(0xFFE8EAED);

  // Status Colors
  static const Color success = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF1A73E8);

  // Overlay Colors
  static const Color overlayLight = Color(0xFFFFFFFF);
  static const Color overlayDark = Color(0xFF202124);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, secondaryDark],
  );
}
