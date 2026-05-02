import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing SQLite encryption keys.
/// Stores a single encryption key in SharedPreferences for database encryption.
class EncryptionService {
  static const String _keyEncryptionKey = 'encryption_key';

  SharedPreferences? _prefs;

  /// Initialize the service with SharedPreferences instance.
  Future<EncryptionService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// Generates a new random encryption key as a hex-encoded SHA-256 hash.
  String generateEncryptionKey() {
    final String seed = DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecond.toString() +
        _randomString(32);
    final bytes = sha256.convert(utf8.encode(seed));
    return bytes.toString();
  }

  /// Saves the encryption key to SharedPreferences.
  Future<void> saveKey(String key) async {
    await _prefs?.setString(_keyEncryptionKey, key);
  }

  /// Retrieves the stored encryption key, or null if none exists.
  String? getStoredKey() {
    return _prefs?.getString(_keyEncryptionKey);
  }

  /// Checks if an encryption key is already stored.
  bool hasStoredKey() {
    return _prefs?.getString(_keyEncryptionKey) != null;
  }

  /// Deletes the stored encryption key.
  Future<void> deleteKey() async {
    await _prefs?.remove(_keyEncryptionKey);
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List<int>.generate(length, (_) => DateTime.now().millisecondsSinceEpoch % chars.length);
    return random.map((i) => chars[i]).join();
  }
}

/// Async lazy-initialized singleton provider.
final globalEncryptionService = EncryptionService();
