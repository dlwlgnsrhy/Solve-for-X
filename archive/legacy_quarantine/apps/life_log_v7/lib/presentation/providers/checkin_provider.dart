import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';

enum CheckinState { initial, loading, success, error }

class CheckinNotifierState {
  final CheckinState state;
  final String? message;

  const CheckinNotifierState({required this.state, this.message});
}

class CheckinNotifier extends StateNotifier<CheckinNotifierState> {
  final PlannerRepository repository;

  CheckinNotifier({required this.repository})
    : super(const CheckinNotifierState(state: CheckinState.initial));

  Future<bool> submitCheckin(CheckinData data) async {
    state = const CheckinNotifierState(state: CheckinState.loading);
    try {
      final success = await repository.submitCheckin(data);
      if (success) {
        state = const CheckinNotifierState(
          state: CheckinState.success,
          message: '오늘의 AI 플래너가 생성되었습니다!',
        );
        return true;
      } else {
        state = const CheckinNotifierState(
          state: CheckinState.error,
          message: '제출에 실패했습니다.',
        );
        throw Exception(state.message);
      }
    } catch (e) {
      state = CheckinNotifierState(
        state: CheckinState.error,
        message: e.toString(),
      );
      rethrow;
    }
  }
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  throw UnimplementedError(
    'plannerRepositoryProvider must be overridden in tests or DI',
  );
});

final checkinProvider =
    StateNotifierProvider<CheckinNotifier, CheckinNotifierState>((ref) {
      final repository = ref.watch(plannerRepositoryProvider);
      return CheckinNotifier(repository: repository);
    });
