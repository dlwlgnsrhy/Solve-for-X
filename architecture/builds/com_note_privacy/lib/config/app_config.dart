import 'package:flutter/material.dart';

/// Dynamic App Configuration
/// This file is auto-generated and overwritten by the App Factory Engine.
class AppConfig {
  static const String appName = 'note';
  static const String appVersion = '1.3.0';
  static const String apiBaseUrl = '';
  
  // Theme Colors (HEX)
  static const String primaryColorHex = '#a78bfa';
  static const String secondaryColorHex = '#f472b6';
  static const String backgroundColorHex = '#f9fafb';
  static const String cardColorHex = '#ffffff';
  
  // Custom Dynamic Features
  static const bool enableChat = true;
  static const bool enableProfile = true;
  static const bool enableSettings = true;
  
  // Home dynamic content
  static const String heroTitle = 'Your Safe Haven';
  static const String heroSubtitle = 'A beautifully soft, highly secure environment protecting your private thoughts and secure data.';
  
  // Dynamic Page Configurations
  static const List<Map<String, String>> dynamicItems = [
    {
      'title': 'Encrypted Vault',
      'description': 'Zero-knowledge hardware lockbox protecting your passwords and credentials.',
      'icon': 'security',
    },
    {
      'title': 'Mindful Journal',
      'description': 'A private safe diary to log your daily emotional highlights with zero cloud leakage.',
      'icon': 'favorite',
    },
    {
      'title': 'Sentinel Guard',
      'description': 'Real-time biometric threat logs capturing lock attempts.',
      'icon': 'shield',
    }
  ];

  // Helper getters to parse colors safely
  static Color get primaryColor => _parseColor(primaryColorHex);
  static Color get secondaryColor => _parseColor(secondaryColorHex);
  static Color get backgroundColor => _parseColor(backgroundColorHex);
  static Color get cardColor => _parseColor(cardColorHex);

  static Color _parseColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return Colors.purple; // Fallback
  }
}
