import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guesstogether/core/theme/app_colors.dart';
import 'package:guesstogether/core/theme/app_typography.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

ThemeData buildLightTheme() => _buildTheme(brightness: Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(brightness: Brightness.dark);

ThemeData _buildTheme({required Brightness brightness}) {
  final bool isDark = brightness == Brightness.dark;
  final ColorScheme scheme = isDark ? _darkScheme : _lightScheme;
  final TextTheme textTheme = AppTypography.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  const Radius mediumRadius = Radius.circular(18);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      titleSpacing: 4,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: scheme.onSurface,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color:
          scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.62 : 0.8),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.42 : 0.2),
        ),
      ),
    ),
    dividerColor: scheme.outline.withValues(alpha: 0.3),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(88, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 52),
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 52),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest
          .withValues(alpha: isDark ? 0.48 : 0.72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle:
          textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.84),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(mediumRadius),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(mediumRadius),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.34)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(mediumRadius),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(mediumRadius),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(mediumRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.32)),
      selectedColor: scheme.primaryContainer.withValues(alpha: 0.92),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.74),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primary.withValues(alpha: 0.18),
      circularTrackColor: scheme.primary.withValues(alpha: 0.18),
    ),
    focusColor: AppColors.focusRing.withValues(alpha: 0.24),
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

const ColorScheme _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.accentElectricBlue,
  onPrimary: Color(0xFF07132D),
  secondary: AppColors.accentMint,
  onSecondary: Color(0xFF06211D),
  tertiary: AppColors.accentSun,
  onTertiary: Color(0xFF302006),
  error: AppColors.error,
  onError: Color(0xFFFFFFFF),
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkOnSurface,
  onSurfaceVariant: Color(0xFFAFBFDF),
  outline: Color(0xFF445374),
  outlineVariant: Color(0xFF2A3553),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE3EBFF),
  onInverseSurface: Color(0xFF151E37),
  inversePrimary: Color(0xFF2A5FA4),
  surfaceContainerHighest: AppColors.darkSurfaceElevated,
);

const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF225FB6),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF0B8368),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFF9C5E01),
  onTertiary: Color(0xFFFFFFFF),
  error: AppColors.error,
  onError: Color(0xFFFFFFFF),
  surface: AppColors.lightSurface,
  onSurface: AppColors.lightOnSurface,
  onSurfaceVariant: Color(0xFF4B5A7D),
  outline: Color(0xFF7B8AAE),
  outlineVariant: Color(0xFFC9D5F4),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1A2744),
  onInverseSurface: Color(0xFFEFF4FF),
  inversePrimary: Color(0xFF7AB4FF),
  surfaceContainerHighest: Color(0xFFE4ECFF),
);
