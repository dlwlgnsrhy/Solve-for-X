import 'package:flutter/material.dart';

/// Card template enum for SFX Imjong Care
enum CardTemplate { neon, sunset, ocean, aurora }

extension CardTemplateExtension on CardTemplate {
  String get name {
    switch (this) {
      case CardTemplate.neon:
        return 'NEON / 네온';
      case CardTemplate.sunset:
        return 'SUNSET / 석양';
      case CardTemplate.ocean:
        return 'OCEAN / 바다';
      case CardTemplate.aurora:
        return 'AURORA / 오로라';
    }
  }

  IconData get icon {
    switch (this) {
      case CardTemplate.neon:
        return Icons.auto_awesome;
      case CardTemplate.sunset:
        return Icons.wb_sunny_outlined;
      case CardTemplate.ocean:
        return Icons.water_drop_outlined;
      case CardTemplate.aurora:
        return Icons.auto_awesome_motion;
    }
  }

  Color get accentColor {
    switch (this) {
      case CardTemplate.neon:
        return const Color(0xFF00FF88);
      case CardTemplate.sunset:
        return const Color(0xFFFF00AA);
      case CardTemplate.ocean:
        return const Color(0xFF00DDFF);
      case CardTemplate.aurora:
        return const Color(0xFFAA00FF);
    }
  }

  Color get borderColor {
    switch (this) {
      case CardTemplate.neon:
        return const Color(0x5000FF88);
      case CardTemplate.sunset:
        return const Color(0x50FF00AA);
      case CardTemplate.ocean:
        return const Color(0x5000DDFF);
      case CardTemplate.aurora:
        return const Color(0x50AA00FF);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case CardTemplate.neon:
        return const [Color(0xFF161625), Color(0xFF0B0B14)];
      case CardTemplate.sunset:
        return const [Color(0xFF2A1620), Color(0xFF1A0A14)];
      case CardTemplate.ocean:
        return const [Color(0xFF0A1628), Color(0xFF060E1A)];
      case CardTemplate.aurora:
        return const [Color(0xFF0A2818), Color(0xFF061A10)];
    }
  }

  List<Color> get shadowColors {
    switch (this) {
      case CardTemplate.neon:
        return const [Color(0x3C00FF88), Color(0x28FF00AA)];
      case CardTemplate.sunset:
        return const [Color(0x3CFF00AA), Color(0x28FF6600)];
      case CardTemplate.ocean:
        return const [Color(0x3C00DDFF), Color(0x2800FF88)];
      case CardTemplate.aurora:
        return const [Color(0x3CAA00FF), Color(0x2800FF88)];
    }
  }
}
