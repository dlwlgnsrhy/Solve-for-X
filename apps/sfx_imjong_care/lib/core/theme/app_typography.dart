import 'package:flutter/material.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';

/// Centralized typography system for SFX Imjong Care.
/// Ensures consistent font sizes, weights, and spacing across the app.
class AppTypography {
  AppTypography._();

  // ========== ORBITRON (Display / Labels) ==========

  /// Main app title (e.g., "SFX 임종 케어" on input screen)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  /// Section labels (e.g., "MY VALUES / 내 가치")
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: NeonColors.neonCyan,
    letterSpacing: 2,
  );

  /// Card name on 3D card (e.g., user's name)
  static const TextStyle cardName = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 2,
  );

  /// Brand header on card (e.g., "SFX 임종 케어" badge)
  static const TextStyle brandHeader = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: NeonColors.neonPink,
    letterSpacing: 1.5,
  );

  /// Small label (e.g., input field labels like "VALUE 1")
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: NeonColors.neonCyan,
  );

  /// Card section label (e.g., "MY VALUES" on card)
  static const TextStyle cardSectionLabel = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0x99FFFFFF),
    letterSpacing: 2,
  );

  /// Button text (e.g., "CARD GENERATE / 카드 생성")
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );

  /// Badge text (e.g., pill-style labels)
  static const TextStyle badge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  /// Footer text on card
  static const TextStyle cardFooter = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Color(0x44FFFFFF),
    letterSpacing: 1.5,
  );

  // ========== INTER (Body / UI) ==========

  /// Body text (e.g., value items on card)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  /// Body text for will section (larger, italic)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.5,
    fontStyle: FontStyle.italic,
  );

  /// Body text for input fields
  static const TextStyle inputBody = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    color: Colors.white,
  );

  /// Hint text in input fields
  static const TextStyle inputHint = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: Color(0x66AAAAAA),
  );

  /// Small body text (e.g., EULA hint, SnackBar)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    color: Color(0xFFCCCCCC),
  );

  /// Caption text (e.g., footer, secondary info)
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    color: NeonColors.dimText,
  );

  /// Handle/username (e.g., @USERNAME)
  static const TextStyle handle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: NeonColors.neonCyan,
  );

  /// Share URL/footer
  static const TextStyle shareUrl = TextStyle(
    fontFamily: 'Inter',
    fontSize: 9,
    color: Color(0x44FFFFFF),
  );

  /// Share button label
  static const TextStyle shareButtonLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// EULA dialog body
  static const TextStyle eulaBody = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: Color(0xFFCCCCCC),
    height: 1.6,
  );

  /// EULA dialog title
  static const TextStyle eulaTitle = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: NeonColors.neonCyan,
    letterSpacing: 1.5,
  );
}
