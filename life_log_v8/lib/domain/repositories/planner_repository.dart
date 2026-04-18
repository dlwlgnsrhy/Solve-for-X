import '../entities/checkin_data.dart';

abstract class PlannerRepository {
  Future<bool> submitCheckin(CheckinData data);
}
