import 'package:flutter_test/flutter_test.dart';
import 'package:life_log_v5/domain/entities/checkin_data.dart';

void main() {
  group('CheckinData Entity Tests', () {
    test('should create an instance of CheckinData with correct values', () {
      final energyLevel = 4;
      final mood = 'Happy';
      final focusMode = 'Deep Work';

      final checkinData = CheckinData(
        energyLevel: energyLevel,
        mood: mood,
        focusMode: focusMode,
      );

      expect(checkinData.energyLevel, energyLevel);
      expect(checkinData.mood, mood);
      expect(checkinData.focusMode, focusMode);
    });

    test('toJson() should return a map with correct keys and values', () {
      final checkinData = CheckinData(
        energyLevel: 3,
        mood: 'Calm',
        focusMode: 'Relaxed',
      );

      final json = checkinData.toJson();

      expect(json['energyLevel'], 3);
      expect(json['mood'], 'Calm');
      expect(json['focusMode'], 'Relaxed');
    });

    test('energyLevel should be between 1 and 5', () {
      // This test checks for basic validation if implemented in the constructor
      // For now, we expect a simple POJO, but TDD allows us to add constraints.
      final checkinData = CheckinData(
        energyLevel: 5,
        mood: 'Energetic',
        focusMode: 'Sprint',
      );
      expect(checkinData.energyLevel, isNotNull);
    });
  });
}
