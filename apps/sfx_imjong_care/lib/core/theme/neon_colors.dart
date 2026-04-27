import 'package:flutter/material.dart';

class NeonColors {
  NeonColors._();

  // Background colors
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceLight = Color(0xFF1A1A25);

  // Neon accent colors
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonPink = Color(0xFFFF00AA);
  static const Color neonCyan = Color(0xFF00DDFF);
  static const Color neonPurple = Color(0xFFAA00FF);
  static const Color neonOrange = Color(0xFFFF6600);

  // Gradient presets for card templates
  static const LinearGradient templateNeon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161625), Color(0xFF0B0B14)],
  );

  static const LinearGradient templateSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1620), Color(0xFF1A0A14)],
  );

  static const LinearGradient templateOcean = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF060E1A)],
  );

  static const LinearGradient templateAurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A2818), Color(0xFF061A10)],
  );

  // Card border colors per template
  static const Color borderNeon = Color(0x5000FF88);
  static const Color borderSunset = Color(0x50FF00AA);
  static const Color borderOcean = Color(0x5000DDFF);
  static const Color borderAurora = Color(0x50AA00FF);

  // Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF888888);
  static const Color dimText = Color(0xFF666666);
}
