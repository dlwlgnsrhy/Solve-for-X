## T3: Domain Layer 구축

### Pattern — Domain Layer Structure
- entities/와 repositories/를 별도 디렉토리로 분리
- barrel export(domain.dart)는 lib/ 최상위에서 동시에 제공됨
- import 경로는 파일베이스 상대경로 사용 (e.g. `../entities/checkin_data.dart`)

### Conventions — Entity 클래스
- CheckinData는 final 필드 + const 생성자 + toJson만 포함
- fromJson 추가 금지 (V7에서 불필요한 복잡성으로 발생)
- toJson은 API 요청용 직렬화만 담당

### Conventions — Repository Interface
- abstract class 패턴 사용
- Future<T> 반환 타입으로 비동기 계약 정의
- 실제 구현은 data layer에서 의존성 역전으로 구현

### Gotcha — Flutter Analyze 0건
- 도메인 계층은 외부 의존성 없이 순수 Dart
- flutter analyze에서 에러 없이 통과 — Clean Architecture 원칙 준수
