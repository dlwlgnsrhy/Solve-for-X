import 'dart:convert';
import 'package:flutter/foundation.dart';

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
  static const String _eulaAcceptedKey = 'eula_accepted';
  static const String _seedInitializedKey = 'seed_initialized';
  static const int maxHistoryItems = 10;

  /// Initialize seed data if not done already.
  static Future<void> initSeedDataIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final initialized = prefs.getBool(_seedInitializedKey) ?? false;
      if (!initialized) {
        final historyJson = prefs.getString(_cardHistoryKey);
        if (historyJson == null || historyJson.isEmpty || historyJson == '[]') {
          final List<Map<String, dynamic>> seedData = [
            {
              'name': '임종케어',
              'values': ['소중한 시간', '따뜻한 기억', '가족'],
              'will': '우리가 함께한 소중한 시간들을\n따뜻한 기억으로 간직해주렴.',
              'template': 'neon',
              'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
            },
            {
              'name': '임종케어',
              'values': ['사랑', '감사', '응원'],
              'will': '부족한 나를 늘 응원해주고\n사랑해줘서 정말 고마웠어.',
              'template': 'sunset',
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            },
            {
              'name': '임종케어',
              'values': ['웃음', '기쁨', '우정'],
              'will': '슬퍼하기보다는 우리가 나눈\n웃음들을 떠올려주길 바란다.',
              'template': 'ocean',
              'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            },
            {
              'name': '임종케어',
              'values': ['평온', '햇살', '행복'],
              'will': '너희의 앞날에 늘 햇살 같은\n평온함이 가득하기를 빌게.',
              'template': 'aurora',
              'timestamp': DateTime.now().toIso8601String(),
            },
          ];
          await prefs.setString(_cardHistoryKey, jsonEncode(seedData));
        }
        await prefs.setBool(_seedInitializedKey, true);
      }
    } catch (e) {
      // Secure SRE protocol: catch database init errors and fail-safe silently
      debugPrint('AppStorage initSeedDataIfNeeded error: $e');
    }
  }

  /// Check if EULA has been accepted.
  static Future<bool> isEulaAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_eulaAcceptedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set EULA acceptance status.
  static Future<void> setEulaAccepted(bool accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_eulaAcceptedKey, accepted);
    } catch (e) {
      debugPrint('AppStorage setEulaAccepted error: $e');
    }
  }

  /// Check if onboarding has been completed.
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as completed.
  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } catch (e) {
      debugPrint('AppStorage setOnboardingCompleted error: $e');
    }
  }

  /// Get the number of times the user has generated a card.
  static Future<int> getCardGenerationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_cardGenerationCountKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increment card generation count and return the new count.
  static Future<int> incrementCardGenerationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_cardGenerationCountKey) ?? 0;
      await prefs.setInt(_cardGenerationCountKey, current + 1);
      return current + 1;
    } catch (e) {
      debugPrint('AppStorage incrementCardGenerationCount error: $e');
      return 1;
    }
  }

  /// Check if review has already been prompted.
  static Future<bool> isReviewPrompted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_reviewPromptedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark review as prompted (so we don't prompt again).
  static Future<void> setReviewPrompted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reviewPromptedKey, true);
    } catch (e) {
      debugPrint('AppStorage setReviewPrompted error: $e');
    }
  }

  /// Save a card to history (up to [maxHistoryItems] most recent).
  static Future<void> addToCardHistory(
    WillCard card,
    CardTemplate template,
  ) async {
    try {
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
    } catch (e) {
      debugPrint('AppStorage addToCardHistory error: $e');
    }
  }

  /// Load card history.
  static Future<List<Map<String, dynamic>>> getCardHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_cardHistoryKey);

      if (historyJson == null) return [];

      try {
        return List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      } catch (_) {
        return [];
      }
    } catch (e) {
      debugPrint('AppStorage getCardHistory error: $e');
      return [];
    }
  }

  /// Clear card history.
  static Future<void> clearCardHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cardHistoryKey);
    } catch (e) {
      debugPrint('AppStorage clearCardHistory error: $e');
    }
  }

  /// Delete a card from history at a specific index.
  static Future<void> deleteCardFromHistory(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_cardHistoryKey);
      if (historyJson == null) return;

      final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      if (index >= 0 && index < history.length) {
        history.removeAt(index);
        await prefs.setString(_cardHistoryKey, jsonEncode(history));
      }
    } catch (e) {
      debugPrint('AppStorage deleteCardFromHistory error: $e');
    }
  }
}

