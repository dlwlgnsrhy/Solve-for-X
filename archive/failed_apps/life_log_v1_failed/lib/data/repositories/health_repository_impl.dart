import 'package:health/health.dart';
import '../../domain/entities/sleep_data.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/planner_api_client.dart';

class HealthRepositoryImpl implements HealthRepository {
  final PlannerApiClient apiClient;
  HealthRepositoryImpl({required this.apiClient});

  @override
  Future<SleepData> getYesterdaySleepData() async {
    // In a real app, we'd check permissions here.
    // Mocking sleep data for demonstration as health plugin requires real device/Health Connect
    return SleepData(score: 93, duration: "7h 30m");
  }

  @override
  Future<void> syncSleepData(SleepData data) async {
    await apiClient.postSleepData(data.toJson());
  }
}
