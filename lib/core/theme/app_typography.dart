import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.sora(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.06,
      letterSpacing: -0.6,
    ),
    displayMedium: GoogleFonts.sora(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.4,
    ),
    titleLarge: GoogleFonts.sora(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.18,
    ),
    titleMedium: GoogleFonts.sora(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.22,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.36,
      letterSpacing: 0.1,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.34,
      letterSpacing: 0.1,
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.1,
    ),
    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: 0.2,
    ),
    labelMedium: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: 0.2,
    ),
  );
}
