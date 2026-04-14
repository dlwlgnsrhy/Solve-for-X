import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'data/datasources/planner_api_client.dart';
import 'data/repositories/health_repository_impl.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Model for Sync State
class SyncState {
  final bool isLoading;
  final String? message;
  SyncState({this.isLoading = false, this.message});
}

// StateNotifier for Sync
class SyncNotifier extends StateNotifier<SyncState> {
  final HealthRepositoryImpl repository;

  SyncNotifier(this.repository) : super(SyncState());

  Future<void> syncSleepData() async {
    state = SyncState(isLoading: true);
    try {
      final sleepData = await repository.getYesterdaySleepData();
      await repository.syncSleepData(sleepData);
      state = SyncState(isLoading: false, message: 'Mac으로 데이터 전송 완료');
    } catch (e) {
      state = SyncState(isLoading: false, message: '동기화 실패: $e');
    }
  }
}

// Providers
final plannerApiClientProvider = Provider((ref) => PlannerApiClient());
final healthRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(plannerApiClientProvider);
  return HealthRepositoryImpl(apiClient: apiClient);
});
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final repository = ref.watch(healthRepositoryProvider);
  return SyncNotifier(repository);
});

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFX Life-Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
