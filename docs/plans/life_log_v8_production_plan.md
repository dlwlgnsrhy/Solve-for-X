# 🚀 Life-Log V8 — V7 MVP 기반 프로덕션 강화 계획서

**작성일**: 2026-04-18  
**기반**: V7 MVP (388줄, 10파일, Glassmorphism UI)  
**모델**: Qwen 3.6-35B-A3B  
**실행**: omo 풀 오케스트레이션 (Prometheus → Atlas → Sisyphus)

---

## 📊 V7 현황 진단 (V8이 필요한 이유)

V7은 **첫 번째 성공적인 MVP**이지만, 프로덕션에 올리기엔 아직 부족합니다:

### ✅ V7 완성된 것
- Clean Architecture 3계층 구조 (domain/data/presentation)
- CheckinData Entity + PlannerRepository Interface
- PlannerApiClient (Dio POST)
- CheckinProvider (Riverpod StateNotifier)
- CheckinScreen (228줄 Glassmorphism UI)
- main.dart 통합 (ProviderScope + Dark Theme + GoogleFonts)
- 테스트 3개 (327줄)

### ❌ V7에서 빠진 것 (V8 목표)

| 번호 | 누락 사항 | 심각도 | 설명 |
|------|----------|--------|------|
| 1 | **DI 미완성** | 🔴 Critical | `plannerRepositoryProvider`가 `throw UnimplementedError`로 되어있어 **실행 시 즉시 크래시** |
| 2 | **SnackBar 미연결** | 🟡 Medium | 제출 성공/실패 시 사용자 피드백(SnackBar) 미구현 |
| 3 | **입력 검증 없음** | 🟡 Medium | mood/focusMode 미선택 시에도 제출 가능 |
| 4 | **로딩 인디케이터 없음** | 🟡 Medium | 제출 중 버튼이 비활성화되지만 로딩 스피너 미표시 |
| 5 | **에러 화면 없음** | 🟡 Medium | 서버 오류 시 사용자에게 아무런 피드백 없음 |
| 6 | **legacy-core 미연동** | 🟠 Low | API 엔드포인트가 하드코딩(192.168.45.61)이며 실제 Spring Boot 서버와 미연결 |
| 7 | **테스트 미검증** | 🟠 Low | 테스트 파일 3개 존재하나 실제 flutter test 통과 여부 미확인 |

---

## 🎯 V8 목표: "V7을 실행 가능한 프로덕션 앱으로"

### Phase 1: DI 완성 및 크래시 해결 (Critical)
- `plannerRepositoryProvider`에 실제 `PlannerRepositoryImpl` + `PlannerApiClient(dio: Dio())` 주입
- main.dart에서 ProviderScope의 overrides로 DI 완성

### Phase 2: UX 완성 (사용자 피드백 루프)
- 제출 성공 → SnackBar("오늘의 AI 플래너가 생성되었습니다!") + 초기화
- 제출 실패 → SnackBar(에러 메시지, 빨간색)
- 로딩 중 → CircularProgressIndicator 표시
- 입력 검증 → mood/focusMode 미선택 시 제출 버튼 비활성화

### Phase 3: 코드 품질 (테스트 + 분석)
- `flutter analyze` 에러 0건 검증
- `flutter test` 통과 검증
- 불필요한 import 정리

---

## 📦 Step 0: V8 프로젝트 초기화 (Antigravity 수동)

```bash
cd /Users/apple/development/soluni/Solve-for-X

# V7을 V8로 복사
cp -R apps/life_log_v7 apps/life_log_v8

# pubspec 이름 변경
sed -i '' 's/name: life_log_v7/name: life_log_v8/' apps/life_log_v8/pubspec.yaml

# test import 업데이트
find apps/life_log_v8 -name "*.dart" -exec sed -i '' 's/life_log_v7/life_log_v8/g' {} +

# 의존성 설치
cd apps/life_log_v8 && flutter pub get && cd ../..

# .sisyphus 폴더 정리
mkdir -p .sisyphus/plans .sisyphus/drafts
```

---

## 🔵 Step 1: Prometheus 기획 (Tab → 붙여넣기)

omo에서 Tab을 눌러 Prometheus 진입 후:

```
나는 Life-Log V8 앱을 업그레이드하고 있어.

## 현재 상태 (V7 MVP)
- 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v8
- 기술: Flutter, Riverpod, Dio, GoogleFonts
- 구조: Clean Architecture (domain/data/presentation) 완성
- UI: Glassmorphism CheckinScreen 완성 (228줄)
- 문제: plannerRepositoryProvider가 throw UnimplementedError로 되어있어 실행 시 크래시

## V8에서 수정할 것

### 1. DI 완성 (Critical - 먼저 해결)
- main.dart에서 ProviderScope의 overrides에 plannerRepositoryProvider를 실제 구현체로 주입
- PlannerApiClient에 Dio 인스턴스 생성하여 PlannerRepositoryImpl에 전달
- 이 작업 후 앱이 크래시 없이 실행 가능해야 함

### 2. SnackBar 사용자 피드백 추가
- checkin_screen.dart에서 checkinProvider 상태 변화를 ref.listen으로 감지
- success → 초록색 SnackBar("오늘의 AI 플래너가 생성되었습니다!") + 선택값 초기화
- error → 빨간색 SnackBar(에러 메시지)

### 3. 입력 검증
- mood와 focusMode가 모두 선택되어야 제출 버튼 활성화
- 미선택 시 버튼 회색 비활성화

### 4. 로딩 인디케이터
- 제출 중(loading 상태)일 때 버튼 텍스트 대신 CircularProgressIndicator 표시

### 5. flutter analyze + flutter test 통과
- 모든 수정 완료 후 flutter analyze 에러 0건
- flutter test 통과 확인

## 반드시 지키기
- 기존 domain/ 파일(checkin_data.dart, planner_repository.dart) 수정 금지
- import는 package:life_log_v8/... 사용
- 제네릭 오타 금지
- 각 파일 수정 후 flutter analyze 검증
```

---

## 🟡 Step 2: 실행 (자고 가기)

Prometheus 설계서가 저장되면:

```
/start-work
```

이후 주무시면 됩니다. 아침에 확인할 체크리스트:

```bash
# 1. 파일이 수정되었는지 확인
ls -la apps/life_log_v8/lib/main.dart
ls -la apps/life_log_v8/lib/presentation/screens/checkin_screen.dart

# 2. DI가 주입되었는지 확인 (UnimplementedError가 사라져야 함)
grep -n "UnimplementedError" apps/life_log_v8/lib/**/*.dart

# 3. SnackBar가 추가되었는지 확인
grep -n "SnackBar" apps/life_log_v8/lib/presentation/screens/checkin_screen.dart

# 4. 빌드 검증
cd apps/life_log_v8 && flutter analyze && flutter test
```

---

## 📊 V7 → V8 예상 변화

| 지표 | V7 (현재) | V8 (목표) |
|------|----------|----------|
| 실행 가능 | ❌ 크래시 | ✅ 정상 실행 |
| 사용자 피드백 | 없음 | SnackBar 성공/실패 |
| 입력 검증 | 없음 | mood/focus 필수 선택 |
| 로딩 표시 | 버튼 비활성화만 | CircularProgressIndicator |
| flutter analyze | 미검증 | 0 에러 |
| flutter test | 미검증 | 전체 통과 |

---

## 🔮 V8 이후 로드맵

| 버전 | 목표 | 예상 시기 |
|------|------|----------|
| **V8** | 프로덕션 실행 가능 (DI + UX) | 이번 주 |
| V9 | legacy-core(Spring Boot) 실서버 연동 | 다음 주 |
| V10 | 삼성헬스 수면 데이터 자동 수신 통합 | 2주 후 |
| V11 | AI 회고 생성 (Qwen 3.6 로컬 추론) | 3주 후 |
| V12 | Google Play Store 배포 | 1개월 후 |
