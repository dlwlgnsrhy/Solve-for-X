import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  String _generateUUID() => const Uuid().v4();

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
