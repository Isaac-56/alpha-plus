import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(Brightness.light);

  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color canvas = isDark ? AppColors.darkCanvas : AppColors.canvas;
    final Color surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final Color ink = isDark ? Colors.white : AppColors.ink;
    final Color muted = isDark ? const Color(0xFFADB5AD) : AppColors.muted;
    final Color border = isDark ? AppColors.darkBorder : AppColors.border;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.ink,
      surface: surface,
      onSurface: ink,
      error: AppColors.danger,
    );

    final TextTheme base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.copyWith(
        displaySmall: base.displaySmall?.copyWith(
          color: ink,
          fontSize: 38,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          color: ink,
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: ink,
          fontSize: 26,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: ink,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          color: ink,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: muted,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: base.labelLarge?.copyWith(
          color: AppColors.ink,
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSoftSurface : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 58),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: isDark
              ? AppColors.darkSoftSurface
              : const Color(0xFFE9EDE9),
          disabledForegroundColor: muted,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.white : AppColors.ink,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.ink : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
