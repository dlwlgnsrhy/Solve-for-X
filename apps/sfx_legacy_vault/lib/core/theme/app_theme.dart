import 'package:flutter/material.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';

/// Neon dark theme for SFX Legacy Vault.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: AppColors.neonGreen,
          secondary: AppColors.neonPink,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            color: AppColors.neonGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: TextStyle(
            color: AppColors.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: AppColors.surfaceVariant, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: const BorderSide(color: AppColors.surfaceVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: const BorderSide(color: AppColors.surfaceVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: const BorderSide(color: AppColors.neonGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonGreen,
            foregroundColor: AppColors.background,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonCyan,
            side: const BorderSide(color: AppColors.neonCyan),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.neonPink,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.surfaceVariant,
          thickness: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.neonGreen,
        ),
      );
}
