import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user data with SharedPreferences.
class PreferenceService {
  static const String _keyUserId = 'user_id';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyIsOnboarded = 'is_onboarded';

  SharedPreferences? _prefs;

  Future<PreferenceService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _recordFirstLaunch();
    return this;
  }

  void _recordFirstLaunch() {
    if (_prefs?.getBool(_keyIsFirstLaunch) != true) {
      _prefs?.setBool(_keyIsFirstLaunch, true);
      _generateAndStoreUserId();
    }
  }

  void _generateAndStoreUserId() {
    final String userId = _generateUUID();
    _prefs?.setString(_keyUserId, userId);
  }

  String _generateUUID() {
    final List<int> bytes = List<int>.generate(16, (_) => 0);
    // Set version 4 (random) and variant bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    final String hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return '${hex.substring(0,8)}-${hex.substring(8,12)}-4${hex.substring(13)}-a${hex.substring(17)}-${hex.substring(20)}';
  }

  /// Unique user identifier. Auto-generated on first launch.
  String get userId => _prefs?.getString(_keyUserId) ?? '';

  /// Whether this is the first launch of the app.
  String get isFirstLaunch => _prefs?.getBool(_keyIsFirstLaunch) == true ? 'true' : 'false';

  /// Whether the user has completed onboarding.
  Future<void> setOnboarded(bool value) async {
    await _prefs?.setBool(_keyIsOnboarded, value);
  }

  bool get isOnboarded => _prefs?.getBool(_keyIsOnboarded) ?? false;

  /// Reset all stored preferences.
  Future<void> resetAll() async {
    await _prefs?.clear();
  }
}

/// Async lazy-initialized singleton provider.
final globalPreferenceService = PreferenceService();
