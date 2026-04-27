import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_memento_mori/core/storage/preference_service.dart';

/// Provider for the preference service instance.
final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  throw Exception('PreferenceService not initialized. Use preferenceServiceProvider.overrideWith() in your app.');
});

/// Notifier that manages onboarding state.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferenceService _prefs;

  OnboardingNotifier(this._prefs) : super(const OnboardingState());

  void setBirthDate(DateTime date) {
    state = state.copyWith(birthDate: date);
  }

  void setTargetAge(int age) {
    state = state.copyWith(targetAge: age);
  }

  void toggleEulaAccepted() {
    state = state.copyWith(eulaAccepted: !state.eulaAccepted);
  }

  Future<void> completeOnboarding() async {
    if (state.birthDate == null || state.targetAge == null) return;
    await _prefs.setBirthDate(state.birthDate!);
    await _prefs.setTargetAge(state.targetAge!);
    await _prefs.setEulaAccepted(state.eulaAccepted);
    await _prefs.setOnboarded(true);
  }

  /// Load saved onboarding data from preferences.
  void loadFromPrefs() {
    final birthDate = _prefs.birthDate;
    final targetAge = _prefs.targetAge;
    final eulaAccepted = _prefs.eulaAccepted;
    if (birthDate != null || targetAge != null) {
      state = state.copyWith(
        birthDate: birthDate ?? state.birthDate,
        targetAge: targetAge ?? state.targetAge,
        eulaAccepted: eulaAccepted,
      );
    }
  }

  bool get canSubmit => state.birthDate != null &&
      state.targetAge != null &&
      state.eulaAccepted;

  void resetState() {
    state = const OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  return OnboardingNotifier(prefs)..loadFromPrefs();
});

class OnboardingState {
  final DateTime? birthDate;
  final int? targetAge;
  final bool eulaAccepted;

  const OnboardingState({
    this.birthDate,
    this.targetAge,
    this.eulaAccepted = false,
  });

  OnboardingState copyWith({
    DateTime? birthDate,
    int? targetAge,
    bool? eulaAccepted,
  }) {
    return OnboardingState(
      birthDate: birthDate ?? this.birthDate,
      targetAge: targetAge ?? this.targetAge,
      eulaAccepted: eulaAccepted ?? this.eulaAccepted,
    );
  }
}
