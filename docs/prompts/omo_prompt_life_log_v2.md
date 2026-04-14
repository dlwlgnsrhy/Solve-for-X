# omo 투입용 프롬프트 — SFX Life-Log V2

> 아래 전체 텍스트를 `opencode` (omo 세션)에 그대로 복사+붙여넣기 하세요.

---

`apps/life_log_v2_premium` 폴더에 SFX Life-Log Flutter 앱 V2를 처음부터 구현하라.

**[SERVICE PURPOSE]**
SFX Life-Log는 **성취 지향 직장인·개발자**를 위한 **AI 기반 데일리 플래너 앱**이다.

**핵심 포지셔닝:**
Samsung Health·Apple Health 등 기존 헬스 앱은 "몸 상태를 보여주는 앱"이다.
SFX Life-Log는 다르다. "유저가 30초 체크인으로 자신의 컨디션을 입력하면, AI가 오늘 하루 업무 강도와 스케줄을 자동으로 설계해주는 앱"이다.

**왜 수동 입력인가:**
Samsung Health·Apple Health API는 파트너십 심사가 필요해 범용 MVP에 부적합하다.
수동 입력(슬라이더·별점·이모지)으로 30초 안에 간편하게 컨디션을 기록하는 것이 이 앱의 UX 핵심이다.

**타겟 유저:** 루틴을 중요하게 여기는 고성과 직장인, 개발자, 스타트업 창업자.

**핵심 차별점:**
- **30초 체크인**: 타이핑 없이 슬라이더·별점·이모지 탭으로 빠르게 컨디션 입력.
- **AI 플래너 자동 설계**: 입력된 컨디션 데이터를 기반으로 오늘의 최적 스케줄과 업무 강도를 AI가 자동 결정.
- **생산성 도구 연동**: Notion·Calendar 등 실제 업무 도구에 결과를 자동 반영. (Phase 2)

**슬로건:** *"30초 체크인으로 AI가 오늘 하루를 설계합니다."*

**V2 MVP 범위 (Phase 1):**
아침 체크인 UI(수동 입력) → 입력값 JSON → 백엔드 POST 전송.
UI는 상용 앱 최고급 퀄리티로 구현. (기기 자동 연동·Notion 발행은 Phase 2)

**개발 백엔드 (임시):** `http://192.168.45.61:8080/api/health/daily-checkin` (Phase 1 로컬 서버)

---

**[TASK]**
`/Users/apple/development/soluni/Solve-for-X/apps/life_log_v2_premium` 에 Flutter 앱을 생성하고, 아래 명세에 따라 프리미엄 다크테마 아침 체크인 앱을 완성하라.

---

**[EXPECTED OUTCOME]**
- `flutter analyze` 실행 시 에러 0개
- `flutter run -d chrome` 실행 시 크래시 없이 아래 화면이 렌더됨:
  1. **체크인 카드**: 에너지 레벨(별 1~5), 기분(이모지 선택), 집중 모드(칩 선택) 3개 입력 UI
  2. **[AI 플래너 시작] 버튼 클릭** → JSON POST → 성공 시 "오늘의 플랜 생성 완료!" SnackBar
- 첫 화면을 봤을 때 "이건 프리미엄 앱이다" 느낌이 즉각적으로 나야 한다

---

**[REQUIRED TOOLS]**
write_file, run_command, read_file, lsp_diagnostics

---

**[MUST DO]**

**① 앱 초기 세팅**
1. `apps/life_log_v2_premium` 를 cwd로 지정하고 `flutter create .` 로 앱을 먼저 생성하라.
2. `pubspec.yaml` 의존성 추가: `flutter_riverpod: ^2.5.1`, `dio: ^5.4.1`, `google_fonts`
   - **`health` 패키지는 절대 추가하지 마라.** 이 앱은 기기 자동 연동을 하지 않는다.

**② UI 디자인 (가장 중요)**
3. 전체 테마: 다크모드. 배경은 짙은 남색~검정 그라데이션 (`Color(0xFF0A0E1A)` ~ `Color(0xFF1A1F35)` 계열).
4. `google_fonts`로 Inter 또는 Outfit 폰트를 전체에 적용하라.
5. 메인 체크인 카드는 Glassmorphism 스타일로 구현하라:
   - `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))`
   - 배경: `Colors.white.withOpacity(0.05)`, border: `Colors.white.withOpacity(0.1)`
   - `borderRadius: BorderRadius.circular(24)`
6. 체크인 입력 요소 3가지를 카드 안에 구현하라 (수면 점수 없음):
   - **에너지 레벨**: 별 아이콘 5개, 탭 시 노란색으로 채워짐 (`Icons.star` / `Icons.star_border`)
   - **기분**: 이모지 Row (`😴 😐 🙂 😊 🔥`) 중 하나 선택, 선택 시 테두리 강조
   - **집중 모드**: 칩(ChoiceChip) 3개 `[Deep Work] [미팅 모드] [가벼운 업무]`, 선택 시 보라색 활성화
7. 하단 CTA 버튼: `LinearGradient` 보라~파랑 배경, 텍스트 "AI 플래너 시작", `AnimatedScale` 탭 애니메이션.
8. 전송 중 로딩: 버튼 자리에 `CircularProgressIndicator` 표시.

**③ 아키텍처 (Clean Architecture)**
9. 다음 파일 구조를 정확히 생성하라:
   - `lib/domain/entities/checkin_data.dart` — `energyLevel: int`, `mood: String`, `focusMode: String`, `toJson()` 포함
   - `lib/data/datasources/planner_api_client.dart` — Dio POST 클라이언트
   - `lib/presentation/providers/checkin_provider.dart` — `CheckinState` (idle/loading/success/error) + `StateNotifier`
   - `lib/presentation/screens/checkin_screen.dart` — 메인 UI (ConsumerStatefulWidget)
   - `lib/main.dart` — `ProviderScope` + 다크테마 + `plannerApiClientProvider`, `checkinProvider` 선언
10. POST Body 형식:
    ```json
    { "energy": 4, "mood": "😊", "focus_mode": "Deep Work" }
    ```
11. **크래시 방어**: Dio POST를 `try-catch`로 감싸라. 실패 시 에러 SnackBar만 뜨고 앱이 뻗으면 안 된다.

**④ 검증**
12. 파일 하나 완성 후 `lsp_diagnostics` 또는 `flutter analyze`를 실행해 에러를 즉시 수정하라.
13. 모든 파일 완성 후 `flutter analyze` 결과와 에러 수를 반드시 보고하라.

---

**[MUST NOT DO]**
- `apps/life_log_v2_premium` 외부에 파일을 생성하지 마라
- `flutter create` 실행 전에 Dart 파일을 먼저 만들지 마라
- **`health` 패키지를 추가하거나 사용하지 마라** (이 앱은 기기 자동 연동 없음)
- **수면 점수(sleep score) 입력 필드를 만들지 마라** (수동 입력 항목에서 제거됨)
- 입력 필드를 `TextField`(타이핑 방식)로 만들지 마라. 반드시 별/이모지/칩 탭 방식으로 만들어라
- 흰 배경, 기본 파란 버튼, 기본 Material 테마를 쓰지 마라
- 에러가 있는 상태에서 완료라고 보고하지 마라

---

**[CONTEXT]**
- 대상 폴더: `/Users/apple/development/soluni/Solve-for-X/apps/life_log_v2_premium` (빈 폴더 존재함)
- 서버 엔드포인트: `http://192.168.45.61:8080/api/health/daily-checkin`
- V1 실패 참조: `apps/life_log_v1_failed/lib/` (구조 참고만, 코드 복붙 금지)
- V1 실패 원인: health 패키지 크래시 / Riverpod 누락 / 흰 배경 UI / sleep score 자동 연동 시도
