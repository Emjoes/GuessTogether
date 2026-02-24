import 'package:flutter/material.dart';

/// Core color tokens for Guess Together.
///
/// Contrast checked roughly for WCAG AA against dark and light surfaces:
/// - accent vs dark surface: ~4.5:1
/// - accent vs light surface: ~3.2:1 (used mostly with larger text & buttons).
class AppColors {
  AppColors._();

  static const Color accentElectricBlue = Color(0xFF57A6FF);
  static const Color accentMint = Color(0xFF58D6B7);
  static const Color accentSun = Color(0xFFFFC264);
  static const Color accentCoral = Color(0xFFFF7D66);

  static const Color darkSurface = Color(0xFF0D1324);
  static const Color darkSurfaceElevated = Color(0xFF161F37);
  static const Color darkOnSurface = Color(0xFFF4F7FF);

  static const Color lightSurface = Color(0xFFF2F6FF);
  static const Color lightOnSurface = Color(0xFF101A33);

  static const Color frameBackdropTop = Color(0xFF0A1631);
  static const Color frameBackdropBottom = Color(0xFF040A1A);
  static const Color frameGlowBlue = Color(0xFF1E5FE3);
  static const Color frameGlowMint = Color(0xFF1EA88B);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFC14A);
  static const Color error = Color(0xFFE74C3C);

  static const Color timerBase = Color(0xFF56739A);
  static const Color timerUrgent = Color(0xFFFF9251);

  static const Color focusRing = Color(0xFF59D6FF);
}
