import 'package:flutter/material.dart';

/// Dynamic App Configuration
/// This file is auto-generated and overwritten by the App Factory Engine.
class AppConfig {
  static const String appName = 'Antigravity SaaS Portal';
  static const String appVersion = '1.2.0';
  static const String apiBaseUrl = 'https://api.antigravity.cloud-native.net';
  
  // Theme Colors (HEX)
  static const String primaryColorHex = '#4F46E5';
  static const String secondaryColorHex = '#EC4899';
  static const String backgroundColorHex = '#090514';
  static const String cardColorHex = '#120B24';
  
  // Custom Dynamic Features
  static const bool enableChat = true;
  static const bool enableProfile = true;
  static const bool enableSettings = true;
  
  // Home dynamic content
  static const String heroTitle = 'Forged in Real-Time';
  static const String heroSubtitle = 'This production build has been fully compiled and validated with zero errors.';
  
  // Dynamic Page Configurations
  static const List<Map<String, String>> dynamicItems = [
    {
      'title': 'Quantum Compute Engine',
      'description': 'High-throughput asynchronous model swapping pipeline.',
      'icon': 'bolt',
    },
    {
      'title': 'Decoupled Data Plane',
      'description': 'Zero latency micro-services operating on edge servers.',
      'icon': 'layers',
    },
    {
      'title': 'Self-Repairing Mesh',
      'description': 'Automated healing loops correcting system deviations.',
      'icon': 'grain',
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
