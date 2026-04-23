import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single entry point for the WorldScribe app theme.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.ink,
      secondary: AppColors.arcane,
      onSecondary: AppColors.parchment,
      error: AppColors.emberRed,
      onError: AppColors.parchment,
      surface: AppColors.surface,
      onSurface: AppColors.parchment,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineSoft,
    );

    final baseText = ThemeData(brightness: Brightness.dark).textTheme.apply(
          bodyColor: AppColors.parchment,
          displayColor: AppColors.parchment,
        );

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: baseText.bodyMedium?.copyWith(
        height: 1.4,
        color: AppColors.parchmentDim,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      canvasColor: AppColors.ink,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.parchment,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.parchment,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outlineSoft),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.parchmentDim),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.midnight,
        hintStyle: const TextStyle(color: AppColors.parchmentFaint),
        labelStyle: const TextStyle(color: AppColors.parchmentDim),
        border: _inputBorder(AppColors.outlineSoft),
        enabledBorder: _inputBorder(AppColors.outlineSoft),
        focusedBorder: _inputBorder(AppColors.gold, width: 1.5),
        errorBorder: _inputBorder(AppColors.emberRed),
        focusedErrorBorder: _inputBorder(AppColors.emberRed, width: 1.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.ink,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.goldDeep),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.parchmentDim,
        textColor: AppColors.parchment,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.parchment),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
