import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: AppColor.neonGreen,
          secondary: AppColor.neonBlue,
          surface: AppColor.cardBg,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColor.divider, width: 1),
          ),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColor.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColor.textPrimary),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColor.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColor.textSecondary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColor.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColor.textDim,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColor.divider,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColor.neonGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColor.neonGreen,
          foregroundColor: AppColor.bgPrimary,
        ),
      );
}

class AppColor {
  static const neonGreen = Color(0xFF00FF66);
  static const neonGreenDim = Color(0xFF00CC52);
  static const neonBlue = Color(0xFF00D4FF);
  static const bgPrimary = Color(0xFF0A0A0F);
  static const bgSecondary = Color(0xFF12121A);
  static const bgTertiary = Color(0xFF1A1A25);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const textDim = Color(0xFF666666);
  static const cardBg = Color(0xFF1E1E2A);
  static const divider = Color(0xFF2A2A3A);
}
