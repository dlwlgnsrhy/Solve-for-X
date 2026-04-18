import '../entities/checkin_data.dart';

abstract class PlannerRepository {
  /// 제출된 CheckinData를 서버로 전송합니다.
  /// 네트워킹 실패 시, Exception(Timeout 등)이 발생해야 합니다.
  Future<bool> submitCheckin(CheckinData data);
}
