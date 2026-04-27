import 'package:flutter/material.dart';
import 'neon_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeonColors.background,
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        surface: NeonColors.surface,
        primary: NeonColors.neonGreen,
        secondary: NeonColors.neonPink,
        tertiary: NeonColors.neonCyan,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.white54,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: NeonColors.neonGreen,
        inactiveTrackColor: NeonColors.darkGrey,
        thumbColor: NeonColors.neonGreen,
        overlayColor: NeonColors.neonGreen.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: const WidgetStatePropertyAll(Colors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeonColors.neonGreen;
          }
          return NeonColors.darkGrey;
        }),
        side: const BorderSide(color: NeonColors.neonGreen, width: 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonColors.neonGreen,
          foregroundColor: NeonColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: NeonColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
    );
  }
}
