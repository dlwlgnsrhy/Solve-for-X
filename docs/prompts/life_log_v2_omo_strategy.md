# SFX Life-Log V2 : omo 에이전트 자동화 재건축 전략서

작성일: 2026-04-15  
참조: `apps/life_log_v1_failed`, `oh-my-openagent-dev/AGENTS.md`, `oh-my-openagent-dev/src/agents/sisyphus.ts`

---

## 1. V1 실패 원인 분석 (Root Cause)

| # | 증상 | 진짜 원인 |
|---|------|----------|
| 1 | 폴더가 `apps/apps/life_log_app`으로 중첩 생성됨 | Gemma에게 `cwd` 컨텍스트 없이 지시. 현재 작업 디렉토리를 인지 못함 |
| 2 | 크롬에서 `PlatformException` 크래시 | `health` 패키지가 Android 전용인데, `kIsWeb` 방어 코드 없음 |
| 3 | `Future<<voidvoid>` 등 제네릭 구문 오타 | 단일 프롬프트로 전체 파일을 한 번에 생성 → 토큰 압박 후반부 환각 |
| 4 | `main.dart` Riverpod 연결 누락 | 마찬가지로 방대한 생성 중 생략 발생 |
| 5 | 하얀 배경 + 기본 파란 버튼 촌스러운 UI | 디자인 제약 조건이 프롬프트에 없었음 |

**핵심 교훈:** 단일 프롬프트로 "전체 앱을 한 번에 만들어라" 방식은 Gemma 31B 단일 A100 환경에서는 후반부 토큰 압박으로 환각과 누락이 반드시 발생한다.

---

## 2. omo 에이전트 시스템 분석

`oh-my-openagent.json`에 설정된 에이전트 구성:
- **sisyphus** (Orchestrator): 전체 작업 조율, 병렬 위임 능력 탁월
- **oracle** (Architecture): 구조적 설계 리뷰
- **explore** (Code Search): 코드베이스 내부 탐색
- **librarian** (Docs Search): 외부 문서 검색
- **sisyphus-junior** (Sub-task): 단순 반복 작업

**핵심 발견**: `sisyphus.ts`에서 확인된 **6-Section Delegation Prompt 구조**:
```
1. TASK       : 원자적, 명확한 단일 목표
2. EXPECTED OUTCOME : 구체적인 결과물과 성공 기준
3. REQUIRED TOOLS   : 사용할 툴 명시
4. MUST DO    : 반드시 해야 하는 것 (빠짐없이)
5. MUST NOT DO: 절대 하면 안 되는 것
6. CONTEXT    : 파일 경로, 패턴, 제약사항
```

또한 **Session Continuity (`session_id`)** 를 통해 이전 컨텍스트를 유지하며 루프를 이어갈 수 있음이 확인됨.

---

## 3. V2 재건축 전략: 3가지 옵션

### 🅐 옵션 A: omo Sisyphus 자동 루프 (추천)
**작동 방식:** Sisyphus가 Oracle/Explore를 병렬로 깔고, 작업을 원자 단위(Atomic)로 분해하여 자동으로 검증-실패-재시도 루프를 돌림.

**장점:**
- Session ID로 이전 대화 컨텍스트 유지 → 환각 최소화
- 실패 3회 시 자동 Oracle 에스컬레이션 → 구조적 에러 자력 해결
- `lsp_diagnostics` 자동 실행 → `flutter analyze` 클린 보장

**프롬프트 투입 위치:** `opencode` (omo가 설치된 세션)

---

### 🅑 옵션 B: 단계별 수동 루프 (현재 방식 개선)
파일 단위로 쪼개서 Gemma 31B에 돌리되 매 단계마다 `flutter analyze`를 검증 조건으로 명시.

---

### 🅒 옵션 C: 제가(Antigravity) 직접 생성 (보장)
컨텍스트 루프 에러 없이 제가 직접 V2의 모든 Dart 파일을 작성. 가장 빠르고 확실함.

---

## 4. 옵션 A 실행: omo용 최적화 프롬프트 (즉시 투입용)

아래 프롬프트를 `opencode`(omo 세션)에 복사+붙여넣기 하세요.

```text
나는 `apps/life_log_v2_premium` 폴더에 SFX Life-Log Flutter 앱 V2를 처음부터 구현하려 한다.

다음 6-섹션 형식의 위임 지시를 정확히 지켜서 작업하라.

---

[TASK]
`apps/life_log_v2_premium` 폴더에 Flutter 앱을 새로 생성하고, 프리미엄 다크 UI와 크로스플랫폼 방어 로직을 갖춘 SFX Life-Log 클라이언트 전체를 구현하라.

[EXPECTED OUTCOME]
- `flutter analyze`를 돌렸을 때 에러가 0개인 완전히 컴파일 가능한 앱.
- `flutter run -d chrome`으로 크롬에서 실행 시 크래시 없이 UI가 렌더되고 동기화 버튼이 작동함.
- 첫 화면에서 "우와, 프리미엄하다" 느낌이 나는 다크테마 Glassmorphism UI.

[REQUIRED TOOLS]
- write_file, run_command, read_file, lsp_diagnostics

[MUST DO]
1. 반드시 `apps/life_log_v2_premium` 경로를 cwd로 고정해서 `flutter create .` 명령으로 앱을 먼저 생성하라.
2. `pubspec.yaml`에 다음 패키지를 추가하라: `flutter_riverpod: ^2.5.1`, `dio: ^5.4.1`, `health: ^13.1.3`, `google_fonts`
3. 앱 테마는 반드시 다크 테마 기반으로 설정하고, `google_fonts`의 Inter 폰트를 사용하라. 흰 배경/기본 파란 버튼 절대 금지.  
4. 다음 Clean Architecture 구조를 정확히 만들어라:
   - `lib/domain/entities/sleep_data.dart` : SleepData 모델 (score: int, duration: String, toJson())
   - `lib/domain/repositories/health_repository.dart` : abstract class
   - `lib/data/repositories/health_repository_impl.dart` : implements HealthRepository
   - `lib/data/datasources/planner_api_client.dart` : Dio POST 클라이언트
   - `lib/presentation/screens/dashboard_screen.dart` : ConsumerWidget UI
   - `lib/main.dart` : ProviderScope + 모든 Provider 정의
5. `HealthRepositoryImpl.getYesterdaySleepData()` 안에 반드시 다음 분기를 넣어라:
   ```dart
   if (kIsWeb) { return SleepData(score: 93, duration: '7h 30m'); }
   // 안드로이드일 때만 health 패키지 호출
   ```
6. `PlannerApiClient`는 Dio로 `http://192.168.45.61:8080/api/health/sleep` 에 POST하라.
7. `main.dart`에는 반드시 `ProviderScope`로 앱을 감싸고, `plannerApiClientProvider`, `healthRepositoryProvider`, `syncProvider`(StateNotifierProvider) 3개를 선언하라.
8. Glassmorphism 카드 UI: 반투명 배경(`Colors.white.withOpacity(0.1)`), border radius 20, blur effect(`BackdropFilter`, `ImageFilter.blur`)를 적용한 카드 안에 [AI 플래너 동기화] 버튼을 배치하라.
9. 각 파일 작성 후 `flutter analyze`를 돌리고 에러를 해결한 뒤 다음 파일로 넘어가라.
10. 모든 파일 완성 후 마지막으로 `flutter analyze`를 한 번 더 실행해 총 에러 수를 보고하라.

[MUST NOT DO]
- `apps/life_log_v2_premium` 외부의 다른 폴더(apps/, / 루트 등)에 파일을 생성하지 마라.
- `flutter create`를 실행하기 전에 Dart 파일을 먼저 만들지 마라. (생성 명령이 기존 파일을 덮어쓸 수 있음)
- `health` 패키지를 `kIsWeb` 분기 없이 직접 호출하지 마라.
- 기본 Material 파란색(Colors.blue, Colors.blueAccent)을 테마 기본색으로 쓰지 마라.
- 에러가 있는 상태에서 "완료"라고 보고하지 마라.

[CONTEXT]
- 대상 폴더: `/Users/apple/development/soluni/Solve-for-X/apps/life_log_v2_premium` (이미 빈 폴더로 존재함)
- Flutter SDK 경로: 전역 설치됨 (`flutter --version`으로 확인 가능)
- Mac IP(서버): `192.168.45.61`, 포트: `8080`
- V1 레퍼런스 코드 위치: `apps/life_log_v1_failed/lib/` (구조 참조용으로만 사용, 복붙 금지)
- V1 실패 원인: kIsWeb 분기 없음, main.dart Riverpod 누락, 흰 배경 UI
```

---

## 5. 검증 체크리스트 (지훈님이 직접 확인)

Sisyphus가 "완료"를 보고하면 반드시 아래를 순서대로 확인하라.

```bash
# 1. 정적 분석 클린 확인
cd apps/life_log_v2_premium
flutter analyze
# → 에러 0개 확인

# 2. 크롬 웹 실행 (CORS 없이 로컬 테스트)
flutter run -d chrome
# → 다크 배경/글래스모피즘 UI 렌더 확인
# → [AI 플래너 동기화] 버튼 클릭
# → "Mac으로 데이터 전송 완료" SnackBar 출력 확인
```

---

## 6. Sisyphus 루프 실패 시 에스컬레이션 플로우

```
Gemma → 에러 3회 이상 → 자동 Oracle 에스컬레이션
         ↓ 해결 안됨
         나(Antigravity)에게 에러 로그 가져와서 수술
```
