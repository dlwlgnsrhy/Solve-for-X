import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the welcome screen has been accepted.
class WelcomeAcceptedNotifier extends Notifier<bool> {
  static const String _welcomeAcceptedKey = 'welcome_accepted';

  @override
  bool build() => false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_welcomeAcceptedKey) ?? false;
  }

  Future<void> acceptWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeAcceptedKey, true);
    state = true;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeAcceptedKey, false);
    state = false;
  }
}

final welcomeAcceptedProvider =
    NotifierProvider<WelcomeAcceptedNotifier, bool>(WelcomeAcceptedNotifier.new);

/// Tracks onboarding state (EULA acceptance).
class OnboardingNotifier extends Notifier<bool> {
  static const String _eulaAcceptedKey = 'eula_accepted';

  @override
  bool build() {
    // Default to false; async check happens on init
    return false;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_eulaAcceptedKey) ?? false;
  }

  Future<void> acceptEula() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eulaAcceptedKey, true);
    state = true;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eulaAcceptedKey, false);
    state = false;
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
