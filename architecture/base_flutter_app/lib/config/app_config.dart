import 'package:flutter/material.dart';

/// Dynamic App Configuration
/// This file is auto-generated and overwritten by the App Factory Engine.
class AppConfig {
  static const String appName = 'Cloud Native Base App';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://api.example.com';
  
  // Theme Colors (HEX)
  static const String primaryColorHex = '#8A2BE2'; // Vibrant Purple
  static const String secondaryColorHex = '#FF007F'; // Vibrant Pink
  static const String backgroundColorHex = '#0A0A0C'; // Premium Dark
  static const String cardColorHex = '#16161A'; // Deep Grey Card
  
  // Custom Dynamic Features
  static const bool enableChat = true;
  static const bool enableProfile = true;
  static const bool enableSettings = true;
  
  // Home dynamic content
  static const String heroTitle = 'Discover the Future of Apps';
  static const String heroSubtitle = 'Forger pipeline has generated this dynamic portal perfectly.';
  
  // Dynamic Page Configurations
  static const List<Map<String, String>> dynamicItems = [
    {
      'title': 'AI Engine Integration',
      'description': 'Real-time execution endpoints and pipelines.',
      'icon': 'bolt',
    },
    {
      'title': 'Multi-Tenant Sandbox',
      'description': 'Zero-cost microservice structure running efficiently.',
      'icon': 'layers',
    },
    {
      'title': 'Elastic Orchestration',
      'description': 'Decoupled Control and Data planes running seamlessly.',
      'icon': 'grain',
    },
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
