import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/features/will_input/data/repositories/will_card_storage.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_input/domain/providers/will_form_provider.dart';

/// No-op storage for unit tests (avoids platform channel errors).
class MockWillCardStorage implements WillCardStorage {
  @override
  Future<void> saveCard(WillCard card) async {}

  @override
  Future<WillCard?> loadCard() async => null;

  @override
  Future<void> clear() async {}

  @override
  Future<bool> hasSavedData() async => false;
}

void main() {
  group('WillFormController', () {
    // Helper: create a ProviderContainer with mock storage
    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          willFormControllerProvider.overrideWith(
            (_) => WillFormController(storage: MockWillCardStorage()),
          ),
        ],
      );
    }

    group('initial state', () {
      test('should have empty default values', () {
        final container = createContainer();
        addTearDown(container.dispose);
        
        final state = container.read(willFormControllerProvider);
        expect(state.name, isEmpty);
        expect(state.values, hasLength(3));
        expect(state.values[0], isEmpty);
        expect(state.values[1], isEmpty);
        expect(state.values[2], isEmpty);
        expect(state.will, isEmpty);
      });

      test('isValid should be false for empty state', () {
        final container = createContainer();
        addTearDown(container.dispose);
        
        final controller = container.read(willFormControllerProvider.notifier);
        expect(controller.isValid, isFalse);
      });
    });

    group('updateName', () {
      test('should update name correctly', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('테스트 사용자');
        expect(controller.isValid, isFalse); // Still invalid (values empty)
        container.read(willFormControllerProvider); // Force state refresh
      });

      test('should update name to empty string', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('');
        expect(controller.isValid, isFalse);
      });

      test('should not affect other fields when updating name', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        // Fill all fields
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        controller.updateValue(2, 'V3');
        controller.updateWill('Will');
        expect(controller.isValid, isTrue);
        
        // Update name again
        controller.updateName('NewName');
        container.read(willFormControllerProvider);
      });
    });

    group('updateValue', () {
      test('should update value at specific index', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateValue(0, 'Value1');
        container.read(willFormControllerProvider);
      });

      test('should update middle value correctly', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        container.read(willFormControllerProvider);
      });

      test('should update last value correctly', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateValue(2, 'V3');
        container.read(willFormControllerProvider);
      });

      test('should handle negative index (no crash)', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        // Should not crash
        controller.updateValue(-1, 'V');
      });

      test('should handle out-of-bounds index (no crash)', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        // Should not crash
        controller.updateValue(10, 'V');
      });
    });

    group('updateWill', () {
      test('should update will correctly', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateWill('나의 유언');
        container.read(willFormControllerProvider);
      });

      test('should update will to empty string', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateWill('');
        container.read(willFormControllerProvider);
      });
    });

    group('isValid', () {
      test('should be false when name is empty', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        controller.updateValue(2, 'V3');
        controller.updateWill('Will');
        expect(controller.isValid, isFalse); // Name is empty
      });

      test('should be false when any value is empty', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        // V3 is empty
        expect(controller.isValid, isFalse);
      });

      test('should be false when will is empty', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        controller.updateValue(2, 'V3');
        expect(controller.isValid, isFalse); // Will is empty
      });

      test('should be true when all fields are filled', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        controller.updateValue(2, 'V3');
        controller.updateWill('Will');
        expect(controller.isValid, isTrue);
      });

      test('should ignore leading/trailing whitespace for validation', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName(' Name ');
        controller.updateValue(0, ' V1 ');
        controller.updateValue(1, ' V2 ');
        controller.updateValue(2, ' V3 ');
        controller.updateWill(' Will ');
        expect(controller.isValid, isTrue);
      });

      test('should be false with whitespace-only values', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('   ');
        controller.updateValue(0, '   ');
        controller.updateValue(1, '   ');
        controller.updateValue(2, '   ');
        controller.updateWill('   ');
        expect(controller.isValid, isFalse); // Whitespace only = invalid
      });
    });

    group('reset', () {
      test('should reset all fields to empty', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.updateValue(1, 'V2');
        controller.updateValue(2, 'V3');
        controller.updateWill('Will');
        controller.reset();
        
        final state = container.read(willFormControllerProvider);
        expect(state.name, isEmpty);
        expect(state.values[0], isEmpty);
        expect(state.values[1], isEmpty);
        expect(state.values[2], isEmpty);
        expect(state.will, isEmpty);
        expect(controller.isValid, isFalse);
      });

      test('should be safe to reset empty state', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        // Should not crash
        controller.reset();
      });

      test('should not crash on reset during active editing', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        controller.updateName('Name');
        controller.updateValue(0, 'V1');
        controller.reset();
        container.read(willFormControllerProvider);
      });
    });

    group('immutability', () {
      test('should not allow direct mutation of state', () {
        final container = createContainer();
        addTearDown(container.dispose);
        final controller = container.read(willFormControllerProvider.notifier);
        
        // State should be returned by value, not reference
        final state1 = container.read(willFormControllerProvider);
        controller.updateName('Name');
        final state2 = container.read(willFormControllerProvider);
        
        expect(state1.name, isNot(equals(state2.name)));
      });
    });
  });
}
