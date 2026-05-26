import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Imjong Care App의 고품격 브랜드 아이덴티티를 나타내는 테마 시스템입니다.
/// HTML의 HSL 변수를 정교하게 매핑하고, Cormorant Garamond와 Noto Serif KR 폰트를 매끄럽게 결합합니다.
class AppTheme {
  AppTheme._();

  // CSS HSL 색상 변수를 Flutter Color 객체로 완벽히 정적 매핑
  static const Color background = Color(0xFFF9F6F1); // --bg: hsl(38, 40%, 96%)
  static const Color surface = Color(0xFFFFFFFF);    // --surface: hsl(0, 0%, 100%)
  static const Color accent = Color(0xFF705E43);     // --accent: hsl(24, 25%, 35%)
  static const Color textPrimary = Color(0xFF382A14); // --text-primary: hsl(24, 20%, 15%)
  static const Color textSecondary = Color(0xFF847662); // --text-secondary: hsl(24, 15%, 45%)
  static const Color border = Color(0x4C705E43);     // --border: hsla(24, 25%, 35%, 0.3)

  // 프리미엄 카드 연출을 위한 투명한 표면 효과
  static const Color surfaceGlass = Color(0xD9FFFFFF); // 투명도 85%의 유리 재질 느낌

  /// 임종 케어 고유의 경건하고 세련된 라이트 테마를 제공합니다.
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        surface: surface,
        primary: accent,
        secondary: textSecondary,
        onSurface: textPrimary,
        onPrimary: background,
      ),
      dividerColor: border,
      // Noto Serif KR을 기본 한글 세리프로, Cormorant Garamond를 영문 서브셋/타이틀로 조합한 텍스트 테마 설계
      textTheme: GoogleFonts.notoSerifKrTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32.0,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 0.05,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 28.0,
          fontWeight: FontWeight.w500,
          color: accent,
          letterSpacing: 0.05,
        ),
        titleLarge: GoogleFonts.notoSerifKr(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.6,
        ),
        bodyLarge: GoogleFonts.notoSerifKr(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.8,
        ),
        bodyMedium: GoogleFonts.notoSerifKr(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.6,
        ),
        labelLarge: GoogleFonts.cormorantGaramond(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 0.1,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: accent,
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
        centerTitle: true,
      ),
    );
  }
}
