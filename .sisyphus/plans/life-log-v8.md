# Life-Log V8 — Flutter Clean Architecture 앱 구축

## TL;DR
> V7의 7번 실패 원인(DI 미연결, SnackBar 없음, 검증 없음, 타임아웃 없음)을 모두 해결.
> Deliverables: 9 dart 파일, 실행 가능한 Flutter 프로젝트 1개
> Effort: Medium (8 작업, 순차적) | Critical Path: create → analyze

## Context
- **Request**: Flutter Life-Log V8. 에너지(1-5별), 기분(이모지 5개), 포커스(4개) → API POST. 성공/실패 SnackBar.
- **Decision**: `flutter create` 새 프로젝트, 구현 우선 (공수표 TDD 금지), flutter analyze 검증
- **Metis Fix**: DI 연결, SnackBar(ref.listen), 입력검증, Dio timeout, flutter create, barrel 한 번에, ChoiceChip

## Work Objectives
- 새 폴더 life_log_v8/에 flutter create 후 빈 프로젝트에 Clean Architecture 구현
- Domain → Data → Presentation 2단계 의존성
- Glassmorphism: 3단계 그라디언트 + BackdropFilter(blur 15,15) + White/5% glass 카드
- ChoiceChip (ActionChip 아님), ref.listen 리액티브 SnackBar, Dio BaseOptions (5s/10s)
- **Must NOT**: v7 복사, 제네릭 오타, console.log, commented-out, 빈 barrel 후 수정

## Verification
- flutter analyze 에러 0건 | 앱 실행 시 CheckinScreen 표시 | Submit → SnackBar

## Execution
T1 create → T2 pubspec → T3 domain → T4 data → T5 provider → T6 screen → T7 main → T8 analyze

## TODOs

---

- [ ] T1: 프로젝트 초기화 (flutter create)

  **What to do**:
  - cd /Users/apple/development/soluni/Solve-for-X/apps/
  - flutter create --org com.lifelogg --project-name life_log_v8 --platforms android,ios life_log_v8
  - ls life_log_v8/ → lib/, pubspec.yaml 존재 확인
  - ls life_log_v8/lib/ → main.dart만 존재 확인
  - V7/V6/V4 절대 건드리지 않음

  **Must NOT do**: v7 코드 복사, 생성 후 바로 코드 수정 (pubspec은 T2에서)

  **Parallel**: NO | Blocks: T2 | BlockedBy: None

  **Acceptance Criteria**:
  - [ ] ls life_log_v8/lib/main.dart 존재
  - [ ] ls life_log_v8/pubspec.yaml 존재
  - [ ] ls life_log_v8/lib/ 에 main.dart만

  **QA**:
  ```
  Scenario: 새 Flutter 프로젝트 생성
    Tool: Bash
    Steps:
      1. ls life_log_v8/lib/main.dart
      2. cat life_log_v8/pubspec.yaml (name: life_log_v8)
    Expected: main.dart 존재, pubspec.yaml에 name: life_log_v8
    Evidence: .sisyphus/evidence/T1-done.txt
  ```

---

- [ ] T2: pubspec.yaml — 의존성 추가 + flutter pub get

  **What to do**:
  - life_log_v8/pubspec.yaml 읽기, dependencies에 다음 추가:
    - cupertino_icons: ^1.0.8
    - dio: ^5.4.1
    - flutter_riverpod: ^2.5.1
    - google_fonts: ^6.3.2
  - dev_dependencies에 flutter_lints: ^5.0.0 (mockito/build_runner 등 불필요 의존 제거)
  - flutter pub get 실행
  - cat pubspec.yaml로 최종 확인

  **Must NOT do**: sdk 버전 변경, 기존 의존성 제거, mockito/unused 의존 포함

  **Parallel**: NO | Blocks: T3 | BlockedBy: T1

  **Acceptance Criteria**:
  - [ ] grep dio/pubspec.yaml 매칭됨
  - [ ] grep flutter_riverpod/pubspec.yaml 매칭됨
  - [ ] grep google_fonts/pubspec.yaml 매칭됨
  - [ ] flutter pub get 성공 (exit 0)

  **QA**:
  ```
  Scenario: 의존성 pubspec에 표시
    Tool: Bash
    Steps:
      1. grep "dio:" life_log_v8/pubspec.yaml
      2. grep "flutter_riverpod:" life_log_v8/pubspec.yaml
      3. grep "google_fonts:" life_log_v8/pubspec.yaml
    Expected: 3줄 모두 매칭
    Evidence: .sisyphus/evidence/T2-done.txt
  ```

---

- [ ] T3: Domain Layer (entity + repository interface + barrel)

  **What to do**:
  - life_log_v8/lib/domain/entities/checkin_data.dart 작성:
    ```dart
    class CheckinData {
      final int energyLevel;
      final String mood;
      final String focusMode;
      const CheckinData({required this.energyLevel, required this.mood, required this.focusMode});
      Map<String, dynamic> toJson() => {'energyLevel': energyLevel, 'mood': mood, 'focusMode': focusMode};
    }
    ```
  - life_log_v8/lib/domain/repositories/planner_repository.dart 작성:
    ```dart
    import '../entities/checkin_data.dart';
    abstract class PlannerRepository { Future<bool> submitCheckin(CheckinData data); }
    ```
  - life_log_v8/lib/domain/domain.dart 작성 (barrel):
    ```dart
    export 'entities/checkin_data.dart';
    export 'repositories/planner_repository.dart';
    ```
  - 각 파일 cat 확인 → flutter analyze lib/domain/

  **Must NOT do**: fromJson 추가 금지, 빈 barrel 후 추후 수정 금지

  **Parallel**: NO | Blocks: T4, T5 | BlockedBy: T2

  **Acceptance Criteria**:
  - [ ] CheckinData class + toJson 존재
  - [ ] abstract PlannerRepository 존재
  - [ ] domain.dart barrel export 2줄
  - [ ] flutter analyze lib/domain/ 에러 0건

  **QA**:
  ```
  Scenario: barrel export 정상
    Tool: Bash
    Steps:
      1. cat life_log_v8/lib/domain/domain.dart
      2. grep -c "export" life_log_v8/lib/domain/domain.dart
    Expected: 2개 export
    Evidence: .sisyphus/evidence/T3-done.txt
  ```

---

- [ ] T4: Data Layer (API client + repo impl + barrel)

  **What to do**:
  - life_log_v8/lib/data/datasources/planner_api_client.dart 작성:
    ```dart
    import 'package:dio/dio.dart';
    import '../../../domain/domain.dart';
    class PlannerApiClient {
      final Dio dio;
      PlannerApiClient({required this.dio});
      Future<bool> submitCheckin(CheckinData data) async {
        try {
          final r = await dio.post('http://192.168.45.61:8080/api/health/daily-checkin', data: data.toJson());
          return r.statusCode == 200;
        } on DioException catch (e) {
          throw Exception('API 요청 실패: ${e.message}');
        } catch (e) {
          throw Exception('예상치 못한 오류: $e');
        }
      }
    }
    ```
  - life_log_v8/lib/data/repositories/planner_repository_impl.dart 작성:
    ```dart
    import '../../../domain/domain.dart';
    import '../datasources/planner_api_client.dart';
    class PlannerRepositoryImpl implements PlannerRepository {
      final PlannerApiClient apiClient;
      PlannerRepositoryImpl({required this.apiClient});
      @override Future<bool> submitCheckin(CheckinData data) => apiClient.submitCheckin(data);
    }
    ```
  - life_log_v8/lib/data/data.dart 작성 (barrel):
    ```dart
    export '../datasources/planner_api_client.dart';
    export 'repositories/planner_repository_impl.dart';
    ```
  - cat 확인 → flutter analyze lib/data/

  **Must NOT do**: V7 baseUrl/endpoint 분리 패턴 복사, baseUrl 상수 사용

  **Parallel**: NO | Blocks: T5 | BlockedBy: T3

  **Acceptance Criteria**:
  - [ ] PlannerApiClient Dio POST + 에러 처리 존재
  - [ ] PlannerRepositoryImpl implements 존재
  - [ ] data.dart barrel export 2줄
  - [ ] flutter analyze lib/data/ 에러 0건

  **QA**:
  ```
  Scenario: barrel export 정상
    Tool: Bash
    Steps:
      1. grep -c "export" life_log_v8/lib/data/data.dart
    Expected: 2개 export
    Evidence: .sisyphus/evidence/T4-done.txt
  ```

---

- [ ] T5: Presentation — CheckinNotifier + Riverpod Provider

  **What to do**:
  - life_log_v8/lib/presentation/providers/checkin_provider.dart 작성:
    ```dart
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
      Future<void> submitCheckin(CheckinData data) async {
        state = const CheckinNotifierState(state: CheckinState.loading);
        try {
          final s = await repository.submitCheckin(data);
          if (s) {
            state = const CheckinNotifierState(state: CheckinState.success, message: '오늘의 AI 플래너가 생성되었습니다!');
          } else {
            state = const CheckinNotifierState(state: CheckinState.error, message: '제출에 실패했습니다. 다시 시도해주세요.');
          }
        } catch (e) {
          state = CheckinNotifierState(state: CheckinState.error, message: '에러 발생: $e');
        }
      }
    }
    final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
      throw UnimplementedError('plannerRepositoryProvider must be overridden with PlannerRepositoryImpl in main.dart');
    });
    final checkinProvider = StateNotifierProvider<CheckinNotifier, CheckinNotifierState>((ref) {
      return CheckinNotifier(repository: ref.watch(plannerRepositoryProvider));
    });
    ```
  - cat 확인 → flutter analyze lib/presentation/providers/

  **V8 개선**: submitCheckin `Future<void>` (V7의 Future<bool> 재현 금지), catch에 rethrow 없음, ref.listen과 호환

  **Must NOT do**: Future<bool> 시그니처 유지, catch에서 rethrow

  **Parallel**: NO | Blocks: T6 | BlockedBy: T3, T4

  **Acceptance Criteria**:
  - [ ] CheckinNotifier + CheckinNotifierState 존재
  - [ ] submitCheckin 시그니처 Future<void>
  - [ ] catch 블록에 rethrow 없음
  - [ ] flutter analyze 에러 0건

  **QA**:
  ```
  Scenario: submitCheckin 시그니처
    Tool: Bash
    Steps:
      1. grep "Future<void> submitCheckin" life_log_v8/lib/presentation/providers/checkin_provider.dart
    Expected: 매칭됨
    Evidence: .sisyphus/evidence/T5-done.txt
  ```

---

- [ ] T6: Presentation — CheckinScreen (Glassmorphism + ChoiceChip + ref.listen + 검증)

  **What to do**:
  - life_log_v8/lib/presentation/screens/checkin_screen.dart 작성:
    - ConsumerStatefulWidget (CheckinScreen)
    - 에너지: 5별 IconButton 선택 (default: 3별)
    - 기분: 5개 이모지 InkWell (😡😢😐🙂😄)
    - 포커스: 4개 ChoiceChip (딥워크/메일/회의/학습) — V7의 ActionChip 교체
    - Dio BaseOptions: connect 5s, receive 10s
    - ref.listen for checkinProvider → success일 때 green SnackBar "오늘의 AI 플래너가 생성되었습니다!"
      - error일 때 red SnackBar
      - 초기 상태(initial/loading)에서 변경될 때만 표시 (중복 방지)
    - _onSubmit: mood/focus null 체크 후 Submit (V7의 null 제출 방지) — 비선택 시 orange SnackBar
    - Glassmorphism: LinearGradient(0xFF0F2027 → 0xFF203A43 → 0xFF2C5364) + BackdropFilter(blur: 15, 15) + White/5% glass 카드
    - FocusMode enum: deepWork, email, meeting, study — V7의 parallel array 문제 해결
    - GoogleFonts.inter for all text
    - ElevatedButton Submit (로딩 시 비활성화)
  - cat 확인 → flutter analyze lib/presentation/screens/

  **V8 주요 개선**:
  1. ref.listen으로 리액티브 SnackBar (V7의 가장 큰 결함 — state 변화를 감지하여 자동 표시)
  2. _onSubmit 입력 검증 (mood/focus null 방지 — V7의 버그)
  3. ActionChip -> ChoiceChip (선택 위젯)
  4. FocusMode enum (parallel array 문제 해결)
  5. non-selected star color: Colors.white38 (dark background 가시성)

  **Must NOT do**: ActionChip 사용, ref.listen 없이 watch만, V7 _onSubmit void pattern 복사

  **Parallel**: NO | Blocks: T7 | BlockedBy: T3, T4, T5

  **Acceptance Criteria**:
  - [ ] BackdropFilter(blur: 15, 15) + glassmorphism 카드
  - [ ] ChoiceChip 4개 (딥워크/메일/회의/학습)
  - [ ] ref.listen checkinProvider → SnackBar 표시
  - [ ] _onSubmit: mood/focus null 체크 후 Submit
  - [ ] flutter analyze 에러 0건

  **QA**:
  ```
  Scenario: Glassmorphism + ChoiceChip
    Tool: Bash
    Steps:
      1. grep "BackdropFilter" life_log_v8/lib/presentation/screens/checkin_screen.dart
      2. grep "ChoiceChip" life_log_v8/lib/presentation/screens/checkin_screen.dart
      3. grep "ref.listen" life_log_v8/lib/presentation/screens/checkin_screen.dart
    Expected: 3줄 모두 매칭
    Evidence: .sisyphus/evidence/T6-done.txt
  ```

---

- [ ] T7: main.dart — DI 연결 + Dio BaseOptions + 앱 실행

  **What to do**:
  - life_log_v8/lib/main.dart 작성 — 전체 재작성 (V7의 UnimplementedError 버그 수정):
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:dio/dio.dart';
    import 'package:google_fonts/google_fonts.dart';

    import 'data/data.dart';
    import 'presentation/presentation.dart';

    void main() {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final apiClient = PlannerApiClient(dio: dio);
      final repository = PlannerRepositoryImpl(apiClient: apiClient);

      runApp(
        ProviderScope(
          overrides: [
            plannerRepositoryProvider.overrideWithValue(repository),
          ],
          child: MyApp(),
        ),
      );
    }

    class MyApp extends StatelessWidget {
      const MyApp({super.key});
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'Life-Log V8',
          theme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.green,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          home: CheckinScreen(),
        );
      }
    }
    ```
  - cat 확인
  - flutter analyze lib/main.dart

  **V8 주요 개선**:
  1. main.dart에서 PlannerRepositoryImpl 직접 생성 + ProviderScope override (V7의 UnimplementedError 버그 해결)
  2. Dio BaseOptions (connectTimeout 5s, receiveTimeout 10s) — V7의 무한 대기 방지
  3. barrel import: data/data.dart, presentation/presentation.dart

  **Must NOT do**: V7의 ProviderScope(w/o overrides) 패턴 유지,dio에 BaseOptions 미설정

  **Parallel**: NO | Blocks: T8 | BlockedBy: T3-T6

  **Acceptance Criteria**:
  - [ ] main.dart에 ProviderScope overrides 존재
  - [ ] Dio(BaseOptions) 구성 존재
  - [ ] Barrel import data/data.dart + presentation/presentation.dart
  - [ ] flutter analyze 에러 0건

  **QA**:
  ```
  Scenario: DI 연결 확인
    Tool: Bash
    Steps:
      1. grep "overrideWithValue" life_log_v8/lib/main.dart
      2. grep "BaseOptions" life_log_v8/lib/main.dart
    Expected: 2줄 모두 매칭
    Evidence: .sisyphus/evidence/T7-done.txt
  ```

---

- [ ] T8: 전체 프로젝트 검증 (flutter analyze)

  **What to do**:
  - cd life_log_v8/
  - flutter analyze lib/ — 에러 0건 확인
  - 모든 에러 발생 시: 에러 분석 → 수정 → 재분석 (에러 0건 될 때까지 반복)
  - 분석 결과는 .sisyphus/evidence/T8-done.txt에 저장
  - 성공 시: flutter run — 앱 실행 확인 (크래시 없이 CheckinScreen 표시)

  **Must NOT do**: 에러 존재하고 다음 단계로 진행

  **Parallel**: NO | Blocks: None (최종) | BlockedBy: T7

  **Acceptance Criteria**:
  - [ ] flutter analyze lib/ — 에러 0건
  - [ ] 앱 실행 시 크래시 없이 CheckinScreen 표시
  - [ ] Submit → API 호출 → 성공/실패 SnackBar 표시

  **QA**:
  ```
  Scenario: 전체 프로젝트 분석
    Tool: Bash
    Steps:
      1. flutter analyze lib/
    Expected: No issues found
    Evidence: .sisyphus/evidence/T8-done.txt
  ```

---

## Commit Strategy
T1: git init + 첫 커밋 (flutter create 결과)
T2: pubspec 의존성 추가
T3-T7: 각 파일 단위 커밋
T8: 전체 검증 완료 커밋

## Success Criteria
1. flutter analyze — 에러 0건
2. flutter run — CheckinScreen 표시 (크래시 없음)
3. Submit → 성공 SnackBar "오늘의 AI 플래너가 생성되었습니다!"
4. Submit (입력 안 함) → orange SnackBar "기분과 포커스 모드를 선택해주세요."
5. API 실패 → red SnackBar 에러 메시지

---
## Final Verification Wave
- F1: flutter analyze lib/ — 에러 0건 확인
- F2: flutter run — 앱 실행 및 체크인 제출 플로우 확인

## Plan Summary
- **Scope**: 새 Flutter 프로젝트 생성 → Clean Architecture 구현 → 최종 검증
- **Total Files**: 9 dart 파일 + pubspec.yaml barrel 3개 + 분석 스크립트
- **V7에서 배운 교훈**: DI 연결, SnackBar, 검증, 타임아웃, flutter create 필수
