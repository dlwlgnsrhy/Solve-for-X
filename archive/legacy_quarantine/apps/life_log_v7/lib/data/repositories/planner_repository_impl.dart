import '../../../domain/domain.dart';
import '../datasources/planner_api_client.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerApiClient apiClient;

  PlannerRepositoryImpl({required this.apiClient});

  @override
  Future<bool> submitCheckin(CheckinData data) {
    return apiClient.submitCheckin(data);
  }
}
