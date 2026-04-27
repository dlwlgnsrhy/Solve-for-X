import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';

/// Local storage service using shared_preferences.
/// Persists will card data across app restarts.
class WillCardStorage {
  static const String _keyName = 'will_name';
  static const String _keyValues = 'will_values';
  static const String _keyWill = 'will_will';

  /// Save a [WillCard] to local storage.
  Future<void> saveCard(WillCard card) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, card.name);
    await prefs.setString(_keyValues, jsonEncode(card.values));
    await prefs.setString(_keyWill, card.will);
  }

  /// Restore a [WillCard] from local storage.
  /// Returns null if no saved data exists.
  Future<WillCard?> loadCard() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final valuesJson = prefs.getString(_keyValues);
    final will = prefs.getString(_keyWill);

    if (name == null || valuesJson == null || will == null) {
      return null;
    }

    try {
      final values = List<String>.from(jsonDecode(valuesJson));
      return WillCard(
        name: name,
        values: values,
        will: will,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear all saved data.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyValues);
    await prefs.remove(_keyWill);
  }

  /// Check if there is saved data.
  Future<bool> hasSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyName);
  }
}
