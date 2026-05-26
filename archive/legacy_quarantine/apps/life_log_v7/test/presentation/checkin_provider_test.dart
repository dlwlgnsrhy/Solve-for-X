import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:life_log_v7/domain/domain.dart';
import 'package:life_log_v7/presentation/presentation.dart';

class MockPlannerRepository extends Mock implements PlannerRepository {}

class SuccessMockRepository extends Mock implements PlannerRepository {
  @override
  Future<bool> submitCheckin(CheckinData data) => Future.value(true);
}

class ErrorMockRepository extends Mock implements PlannerRepository {
  @override
  Future<bool> submitCheckin(CheckinData data) =>
      Future.error(Exception('Network failed'));
}

void main() {
  group('CheckinNotifier', () {
    test('initial state is CheckinState.initial', () {
      final container = ProviderContainer(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(MockPlannerRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(checkinProvider.notifier);
      expect(notifier.state.state, CheckinState.initial);
    });

    test('submitCheckin transitions loading - success', () async {
      final container = ProviderContainer(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(SuccessMockRepository()),
        ],
      );
      addTearDown(container.dispose);

      final testData = const CheckinData(
        energyLevel: 3,
        mood: '😐',
        focusMode: '딥워크',
      );

      final future = container
          .read(checkinProvider.notifier)
          .submitCheckin(testData);

      // Should be loading immediately after calling (microtask)
      expect(container.read(checkinProvider).state, CheckinState.loading);

      // After completion
      await future;

      expect(container.read(checkinProvider).state, CheckinState.success);
      expect(container.read(checkinProvider).message, '오늘의 AI 플래너가 생성되었습니다!');
    });

    test('submitCheckin transitions loading - error on failure', () async {
      final container = ProviderContainer(
        overrides: [
          plannerRepositoryProvider.overrideWithValue(ErrorMockRepository()),
        ],
      );
      addTearDown(container.dispose);

      final testData = const CheckinData(
        energyLevel: 3,
        mood: '😐',
        focusMode: '딥워크',
      );

      final future = container
          .read(checkinProvider.notifier)
          .submitCheckin(testData);

      // Should be loading
      expect(container.read(checkinProvider).state, CheckinState.loading);

      await expectLater(future, throwsA(isA<Exception>()));

      expect(container.read(checkinProvider).state, CheckinState.error);
      expect(container.read(checkinProvider).message, isNotNull);
    });
  });
}
