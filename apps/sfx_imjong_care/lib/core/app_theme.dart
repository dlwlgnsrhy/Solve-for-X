import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cream & Sepia harmonious color palette
  static const Color creamBg = Color(0xFFFDFBF7);
  static const Color cardBg = Color(0xFFF9F5EE);
  static const Color espressoText = Color(0xFF2C1A14);
  static const Color espressoTextLight = Color(0xFF5C473E);
  static const Color terracottaAccent = Color(0xFF8C624B);
  static const Color heartStampRed = Color(0xFF9E2A2B);
  static const Color sepiaBorder = Color(0xFFE2DCD2);

  static ThemeData get creamTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        surface: creamBg,
        primary: terracottaAccent,
        secondary: espressoTextLight,
        onSurface: espressoText,
        onPrimary: creamBg,
      ),
      scaffoldBackgroundColor: creamBg,
      dividerTheme: const DividerThemeData(
        color: sepiaBorder,
        thickness: 1.0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: espressoText,
        ),
        titleLarge: GoogleFonts.notoSerifKr(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: espressoText,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.notoSerifKr(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: espressoText,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.notoSerifKr(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: espressoTextLight,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.notoSerifKr(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: terracottaAccent,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: terracottaAccent, width: 1.5),
        ),
        labelStyle: GoogleFonts.notoSerifKr(color: espressoTextLight),
        hintStyle: GoogleFonts.notoSerifKr(color: espressoTextLight.withValues(alpha: 0.5)),
      ),
    );
  }
}
