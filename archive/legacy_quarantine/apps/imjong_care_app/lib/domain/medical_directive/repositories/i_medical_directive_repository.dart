/// 사전연명의료의향서(Medical Directive) 도메인의 영속성 관리를 선언하는 추상 리포지토리 명세입니다.
abstract class IMedicalDirectiveRepository {
  /// 향후 의료의향서 상태 저장을 위해 준비된 규약입니다.
  Future<void> saveDirective();
}
