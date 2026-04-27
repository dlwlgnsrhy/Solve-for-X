import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';

/// App-wide storage utility for onboarding, review prompts, and card history.
class AppStorage {
  AppStorage._();

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _cardGenerationCountKey = 'card_generation_count';
  static const String _reviewPromptedKey = 'review_prompted';
  static const String _cardHistoryKey = 'card_history';
  static const int maxHistoryItems = 10;

  /// Check if onboarding has been completed.
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed.
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Get the number of times the user has generated a card.
  static Future<int> getCardGenerationCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cardGenerationCountKey) ?? 0;
  }

  /// Increment card generation count and return the new count.
  static Future<int> incrementCardGenerationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_cardGenerationCountKey) ?? 0;
    await prefs.setInt(_cardGenerationCountKey, current + 1);
    return current + 1;
  }

  /// Check if review has already been prompted.
  static Future<bool> isReviewPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewPromptedKey) ?? false;
  }

  /// Mark review as prompted (so we don't prompt again).
  static Future<void> setReviewPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPromptedKey, true);
  }

  /// Save a card to history (up to [maxHistoryItems] most recent).
  static Future<void> addToCardHistory(
    WillCard card,
    CardTemplate template,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_cardHistoryKey);
    List<Map<String, dynamic>> history = [];

    if (historyJson != null) {
      try {
        history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      } catch (_) {
        history = [];
      }
    }

    final entry = {
      'name': card.name,
      'values': card.values,
      'will': card.will,
      'template': template.name.split('/')[0].trim(), // store enum name
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add to beginning of list
    history.insert(0, entry);

    // Keep only the most recent items
    if (history.length > maxHistoryItems) {
      history = history.sublist(0, maxHistoryItems);
    }

    await prefs.setString(_cardHistoryKey, jsonEncode(history));
  }

  /// Load card history.
  static Future<List<Map<String, dynamic>>> getCardHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_cardHistoryKey);

    if (historyJson == null) return [];

    try {
      return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    } catch (_) {
      return [];
    }
  }

  /// Clear card history.
  static Future<void> clearCardHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardHistoryKey);
  }
}
