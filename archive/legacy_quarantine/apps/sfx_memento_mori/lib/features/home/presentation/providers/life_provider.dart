import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_memento_mori/core/utils/life_calculator.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

/// Provider that computes life stats from stored preferences.
final lifeProvider = Provider<LifeStats?>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  final birthDate = prefs.birthDate;
  final targetAge = prefs.targetAge;

  if (birthDate == null || targetAge == null) {
    return null;
  }

  return LifeCalculator.getLifeStats(birthDate, targetAge);
});
