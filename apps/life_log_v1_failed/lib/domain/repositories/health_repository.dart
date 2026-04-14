import '../entities/sleep_data.dart';

abstract class HealthRepository {
  Future<SleepData> getYesterdaySleepData();
  Future<void> syncSleepData(SleepData data);
}
