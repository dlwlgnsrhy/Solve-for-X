# omo 투입용 단계별 프롬프트 — SFX Life-Log V3 (Step-by-Step + Skills)

로컬 양자화 모델(Gemma 4-bit)의 출력 한계를 고려하여, 앱 전체 생성을 쪼개고 **omo의 내장 스킬(Built-in Skills)**을 적극 활용하는 구조입니다.
`opencode` 세션에 아래 **Step 1부터 순서대로** 복사+붙여넣기 하십시오. omo가 답변을 완료(성공)하면 다음 Step을 넣으세요.

---

## 🟢 Step 1: 앱 생성 및 엔티티(모델) 정의

**[TASK]**
`apps/life_log_v3_stepbystep` 폴더에 Flutter 앱을 생성하고 데이터 모델을 정의하라.

**[MUST DO]**
1. 반드시 `apps/life_log_v3_stepbystep` 를 cwd로 지정하고 `flutter create .` 로 앱을 먼저 생성하라.
2. `pubspec.yaml` 의존성 추가: `flutter_riverpod: ^2.5.1`, `dio: ^5.4.1`, `google_fonts` (health 패키지 절대 추가 금지)
3. `flutter pub get` 을 실행하라.
4. `lib/domain/entities/checkin_data.dart` 파일을 생성하고 다음 구조를 명확히 작성하라:
   - 클래스명: `CheckinData`
   - 필드: `energyLevel` (int), `mood` (String), `focusMode` (String)
   - 생성자 및 `Map<String, dynamic> toJson()` 메서드 추가
5. 파일 작성 후 `flutter analyze`를 돌려서 에러가 발생하면 스스로 고쳐라. 완성되면 보고하라.

---

## 🟢 Step 2: 네트워크 API 클라이언트 구현

**[TASK]**
데이터 전송을 위한 API 클라이언트를 생성하라.

**[MUST DO]**
1. `lib/data/datasources/planner_api_client.dart` 파일을 생성하라.
2. `Dio`를 사용하여 `http://192.168.45.61:8080/api/health/daily-checkin` 경로로 POST 요청을 보내는 `PlannerApiClient` 클래스를 작성하라.
3. 데이터 파라미터는 `Map<String, dynamic> data` 로 받는다.
4. try-catch로 Dio 호출을 감싸고, 실패하더라도 앱이 크래시되지 않도록 단순히 실패 여부(bool 등)만 리턴하거나 예외를 로깅하라.
5. 파일 작성 후 `flutter analyze`를 돌려서 에러가 발생하면 스스로 고쳐라. 완성되면 보고하라.

---

## 🟢 Step 3: Riverpod 상태 관리 (Provider) 구현

**[TASK]**
UI와 통신 로직을 이어줄 Riverpod 상태 관리를 구현하라.

**[MUST DO]**
1. `lib/presentation/providers/checkin_provider.dart` 파일을 생성하라.
2. `CheckinState` enum을 정의하라: `idle`, `loading`, `success`, `error`
3. `CheckinNotifier`를 `StateNotifier<CheckinState>`를 상속받아 구현하라. 초기 상태는 `idle` 이다.
4. `submitCheckin(CheckinData data)` 비동기 메서드를 구현하라. 
   - 상태를 `loading`으로 변경
   - 파라미터로 주입받은 `PlannerApiClient`를 통해 전송
   - 성공 시 상태를 `success`로, 실패 시 `error`로 변경
5. 파일 작성 후 `flutter analyze`를 돌려서 에러가 발생하면 스스로 고쳐라. 완성되면 보고하라.

---

## 🟢 Step 4: 메인 체크인 UI 구현 (프리미엄 블러 효과) - 🎨 `frontend-ui-ux` 스킬 활용

**[TASK]**
사용자가 입력할 수 있는 아침 체크인 메인 화면을 구현하라. (주의: `frontend-ui-ux` 스킬을 로드하여 디자인 전문가의 관점에서 코드를 작성하라.)

**[MUST DO]**
1. `lib/presentation/screens/checkin_screen.dart` 파일을 생성하라. (ConsumerStatefulWidget 사용)
2. 전체 화면 배경은 짙은 남색~검정 그라데이션.
3. 메인 입력 카드는 Glassmorphism 스타일(BackdropFilter blur(12, 12), 테두리 반투명 흰색)로 제작하라.
4. 모닝 체크인 입력 항목 (수면 점수 없음):
   - 에너지 레벨: 터치 가능한 별 아이콘 5개 `Row`
   - 기분: 이모지 5개 탭 선택 (`😴 😐 🙂 😊 🔥`) 
   - 집중 모드: `ChoiceChip` 3개 `[Deep Work] [미팅 모드] [가벼운 업무]`
5. 화면 하단에 Action 버튼 (보라~파랑 그라데이션 배경, 글자 "AI 플래너 시작")
6. `checkinProvider`의 상태가 `loading`일 때는 Action 버튼 위치에 `CircularProgressIndicator`를 보여주어라.
7. 버튼을 누르면 위 화면에서 모은 값을 `CheckinData`에 담아 Provider의 `submitCheckin()`을 호출하라. `success` 상태가 되면 SnackBar를 띄워라.
8. 코드가 매우 길어질 수 있다. 한 번에 잘 만들어라. 
9. 작성 후 `flutter analyze` 필수.

---

## 🟢 Step 5: 앱 와이어링 및 마무리

**[TASK]**
`main.dart`를 작성하여 모든 컴포넌트를 연결하고 앱을 실행 가능하게 만들어라.

**[MUST DO]**
1. `lib/main.dart` 기존 파일을 덮어쓰기 하라.
2. `ProviderScope`로 전체 앱을 감싸라.
3. `plannerApiClientProvider`, `checkinNotifierProvider` (StateNotifierProvider) 등 2개의 Riverpod Provider를 `main.dart` 상단에 전역으로 선언하라.
4. `MaterialApp` 속성의 테마에 다크 테마 적용 및 기본 폰트를 적용하라 (`google_fonts` 패키지 활용).
5. `home` 을 방금 만든 `CheckinScreen()` 으로 연결하라.
6. 마지막으로 패키지 전체 폴더 단위로 `flutter analyze` 를 실행해 에러 수를 보고하라.

---

## 🔎 Step 6: 종합 리뷰 및 QA - 🤖 `review-work` 스킬 발동

> 위 단계들이 모두 완료되고 앱이 정상 실행되면, `opencode` 세션에 아래 명령어 한 줄만 입력하세요.

**[입력어]**
review my work

*(설명: 이 명령어를 입력하면 omo의 내장 `review-work` 스킬이 발동하여 5개의 에이전트(목표 검증, QA, 코드 리뷰, 보안, 컨텍스트 마이닝)가 병렬로 생성된 앱을 낱낱이 파헤칩니다.)* 사용)
2. 전체 화면 배경은 짙은 남색~검정 그라데이션.
3. 메인 입력 카드는 Glassmorphism 스타일(BackdropFilter blur(12, 12), 테두리 반투명 흰색)로 제작하라.
4. 모닝 체크인 입력 항목 (수면 점수 없음):
   - 에너지 레벨: 터치 가능한 별 아이콘 5개 `Row`
   - 기분: 이모지 5개 탭 선택 (`😴 😐 🙂 😊 🔥`) 
   - 집중 모드: `ChoiceChip` 3개 `[Deep Work] [미팅 모드] [가벼운 업무]`
5. 화면 하단에 Action 버튼 (보라~파랑 그라데이션 배경, 글자 "AI 플래너 시작")
6. `checkinProvider`의 상태가 `loading`일 때는 Action 버튼 위치에 `CircularProgressIndicator`를 보여주어라.
7. 버튼을 누르면 위 화면에서 모은 값을 `CheckinData`에 담아 Provider의 `submitCheckin()`을 호출하라. `success` 상태가 되면 SnackBar를 띄워라.
8. 코드가 매우 길어질 수 있다. 한 번에 잘 만들어라. 
9. 작성 후 `flutter analyze` 필수.

---

## 🟢 Step 5: 앱 와이어링 및 마무리

**[TASK]**
`main.dart`를 작성하여 모든 컴포넌트를 연결하고 앱을 실행 가능하게 만들어라.

**[MUST DO]**
1. `lib/main.dart` 기존 파일을 덮어쓰기 하라.
2. `ProviderScope`로 전체 앱을 감싸라.
3. `plannerApiClientProvider`, `checkinNotifierProvider` (StateNotifierProvider) 등 2개의 Riverpod Provider를 `main.dart` 상단에 전역으로 선언하라.
4. `MaterialApp` 속성의 테마에 다크 테마 적용 및 기본 폰트를 적용하라 (`google_fonts` 패키지 활용).
5. `home` 을 방금 만든 `CheckinScreen()` 으로 연결하라.
6. 마지막으로 패키지 전체 폴더 단위로 `flutter analyze` 를 실행해 에러 수를 보고하라.
