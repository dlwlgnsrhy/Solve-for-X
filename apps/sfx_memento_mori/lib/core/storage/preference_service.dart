import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user data with SharedPreferences.
class PreferenceService {
  static const String _keyBirthDate = 'birth_date';
  static const String _keyTargetAge = 'target_age';
  static const String _keyEulaAccepted = 'eula_accepted';
  static const String _keyOnboarded = 'onboarded';
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyReviewPrompted = 'review_prompted';
  static const String _keyWelcomeSeen = 'welcome_seen';

  SharedPreferences? _prefs;

  Future<PreferenceService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _recordFirstLaunch();
    return this;
  }

  void _recordFirstLaunch() {
    if (_prefs?.getString(_keyFirstLaunchDate) == null) {
      _prefs?.setString(_keyFirstLaunchDate, DateTime.now().toIso8601String());
    }
  }

  // EULA
  Future<void> setEulaAccepted(bool value) async {
    await _prefs?.setBool(_keyEulaAccepted, value);
  }

  bool get eulaAccepted => _prefs?.getBool(_keyEulaAccepted) ?? false;

  // Onboarding
  Future<void> setOnboarded(bool value) async {
    await _prefs?.setBool(_keyOnboarded, value);
  }

  bool get isOnboarded =>
      _prefs?.getBool(_keyOnboarded) ?? false;

  // Birth date
  Future<void> setBirthDate(DateTime date) async {
    await _prefs?.setString(_keyBirthDate, date.toIso8601String());
  }

  DateTime? get birthDate {
    final String? value = _prefs?.getString(_keyBirthDate);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  // Target age
  Future<void> setTargetAge(int age) async {
    await _prefs?.setInt(_keyTargetAge, age);
  }

  int? get targetAge => _prefs?.getInt(_keyTargetAge);

  // Review prompt tracking
  Future<void> setReviewPrompted(bool value) async {
    await _prefs?.setBool(_keyReviewPrompted, value);
  }

  bool get reviewPrompted => _prefs?.getBool(_keyReviewPrompted) ?? false;

  DateTime? get firstLaunchDate {
    final String? value = _prefs?.getString(_keyFirstLaunchDate);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  // Welcome screen tracking
  Future<void> setWelcomeSeen(bool value) async {
    await _prefs?.setBool(_keyWelcomeSeen, value);
  }

  bool get welcomeSeen => _prefs?.getBool(_keyWelcomeSeen) ?? false;

  // Reset all
  Future<void> resetAll() async {
    await _prefs?.clear();
  }
}
