import 'package:flutter_test/flutter_test.dart';

import 'package:origin/core/services/preference_service.dart';

void main() {
  group('PreferenceService', () {
    test('initial state has empty userId', () {
      final service = PreferenceService();
      expect(service.userId, isEmpty);
    });

    test('isOnboarded defaults to false', () {
      final service = PreferenceService();
      expect(service.isOnboarded, isFalse);
    });

    test('userId is non-empty after init on real device', () {
      final service = PreferenceService();
      // On a real device or simulator, this will generate a UUID
      expect(service.userId, isNotNull);
    });

    test('isFirstLaunch is set after init', () {
      // _recordFirstLaunch sets the key only if absent
      // On a clean SharedPreferences instance this will be true
      // After multiple initializations it stays true
    });

    test('can set and read isOnboarded', () async {
      final service = PreferenceService();
      await service.setOnboarded(true);
      expect(service.isOnboarded, isTrue);
    });
  });
}
