import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================
  // Backgrounds
  // ==========================

  static const Color background = Color(0xFF090B18);
  static const Color backgroundDark = Color(0xFF05070F);
  static const Color surface = Color(0xFF121629);
  static const Color card = Color(0xFF1A2035);

  // ==========================
  // Glass
  // ==========================

  static final Color glass = Colors.white.withValues(alpha: .08);

  static final Color glassLight = Colors.white.withValues(alpha: .12);

  static final Color glassBorder = Colors.white.withValues(alpha: .12);

  // ==========================
  // Brand
  // ==========================

  static const Color primary = Color(0xFF7B5CFF);

  static const Color secondary = Color(0xFF35D8FF);

  static const Color accent = Color(0xFFFF4FA3);

  // ==========================
  // Gradients
  // ==========================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B5CFF), Color(0xFF9E6CFF), Color(0xFFFF4FA3)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF7B5CFF), Color(0xFF6F8BFF)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF090B18), Color(0xFF10142A), Color(0xFF1A1F37)],
  );

  // ==========================
  // Text
  // ==========================

  static const Color textPrimary = Colors.white;

  static const Color textSecondary = Color(0xFFAEB4D0);

  static const Color hint = Color(0xFF7E86A8);

  // ==========================
  // Status
  // ==========================

  static const Color success = Color(0xFF36E4A7);

  static const Color warning = Color(0xFFFFC857);

  static const Color danger = Color(0xFFFF5E7E);

  // ==========================
  // Borders
  // ==========================

  static final Color border = Colors.white.withValues(alpha: .10);

  static final Color divider = Colors.white.withValues(alpha: .08);

  // ==========================
  // Shadows
  // ==========================

  static final Color shadow = Colors.black.withValues(alpha: .35);

  static final Color purpleGlow = primary.withValues(alpha: .22);

  static final Color pinkGlow = accent.withValues(alpha: .18);

  // ==========================
  // Button
  // ==========================

  static const Color buttonText = Colors.white;

  static const Color buttonBackground = Color(0xFF7B5CFF);

  static final Color buttonHover = Colors.white.withValues(alpha: .10);

  // ==========================
  // Input
  // ==========================

  static final Color inputBackground = Colors.white.withValues(alpha: .05);

  static final Color inputFocused = primary.withValues(alpha: .15);

  // ==========================
  // Misc
  // ==========================

  static final Color overlay = Colors.black.withValues(alpha: .45);
}
