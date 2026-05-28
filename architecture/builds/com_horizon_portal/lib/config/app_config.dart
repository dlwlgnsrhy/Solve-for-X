import 'package:flutter/material.dart';

/// Dynamic App Configuration
/// This file is auto-generated and overwritten by the App Factory Engine.
class AppConfig {
  static const String appName = 'Horizon Portal';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://api.horizon-platform.io';
  
  // Theme Colors (HEX)
  static const String primaryColorHex = '#3b82f6';
  static const String secondaryColorHex = '#ec4899';
  static const String backgroundColorHex = '#090514';
  static const String cardColorHex = '#120b24';
  
  // Custom Dynamic Features
  static const bool enableChat = true;
  static const bool enableProfile = true;
  static const bool enableSettings = true;
  
  // Home dynamic content
  static const String heroTitle = 'Dynamic Workspace Active';
  static const String heroSubtitle = 'Seamless multi-tenant edge client generated completely in real-time.';
  
  // Dynamic Page Configurations
  static const List<Map<String, String>> dynamicItems = [
    {
      'title': 'Edge Compute Core',
      'description': 'High-throughput model execution pipeline.',
      'icon': 'bolt',
    },
    {
      'title': 'Distributed Fabric',
      'description': 'Zero latency micro-services synchronized globally.',
      'icon': 'layers',
    },
    {
      'title': 'Elastic Registry',
      'description': 'Multi-tenant directory with autonomous registration.',
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
