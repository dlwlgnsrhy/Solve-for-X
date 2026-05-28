import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'SafeSpace';
  static const String appVersion = '1.3.0';
  static const String apiBaseUrl = 'https://api.safespace-privacy.io';
  
  static const String primaryColorHex = '#a78bfa';
  static const String secondaryColorHex = '#f472b6';
  static const String backgroundColorHex = '#f9fafb';
  static const String cardColorHex = '#ffffff';
  
  static const bool enableChat = true;
  static const bool enableProfile = true;
  static const bool enableSettings = true;
  
  static const String heroTitle = 'Your Safe Haven';
  static const String heroSubtitle = 'A beautifully soft, highly secure environment protecting your private thoughts and secure data.';
  
  static const List<Map<String, String>> dynamicItems = [
    {'title': 'Encrypted Vault', 'description': 'Zero-knowledge hardware lockbox protecting your passwords and credentials.', 'icon': 'security'},
    {'title': 'Mindful Journal', 'description': 'A private safe diary to log your daily emotional highlights with zero cloud leakage.', 'icon': 'favorite'},
    {'title': 'Sentinel Guard', 'description': 'Real-time biometric threat logs capturing lock attempts.', 'icon': 'shield'}
  ];

  static Color get primaryColor => _parseColor(primaryColorHex);
  static Color get secondaryColor => _parseColor(secondaryColorHex);
  static Color get backgroundColor => _parseColor(backgroundColorHex);
  static Color get cardColor => _parseColor(cardColorHex);

  static Color _parseColor(String hexStr) {
    final cleanHex = hexStr.replaceAll('#', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return Colors.purple;
  }
}
