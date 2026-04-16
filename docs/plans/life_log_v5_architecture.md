# Life-Log V5 Architecture & Implementation Blueprint

## 🎯 1. Project Initialization & Structure
- **Path**: `/Users/apple/development/soluni/Solve-for-X/apps/life_log_v5`
- **Command**: `flutter create --no-pub .`
- **Dependencies**: Add `flutter_riverpod: ^2.5.1`, `dio: ^5.4.1`, `google_fonts: ^6.3.2` to `pubspec.yaml`.
- **Validation**: Run `flutter pub get` and verify creation via `ls -la`.

## 🧪 2. QA & Test Strategy (Decision)
- **Domain & Data Layers (Logic)**: **Strict TDD Workflow**. The agent MUST write `test/` files for API clients and Entity models first. A successful `flutter test` is the only acceptable proof of completion to overcome past syntax hallucination issues.
- **Presentation Layer (UI)**: **Agent-Executed QA**. Rely on `flutter analyze` and manual layout rendering check. No need for complex UI widget tests.

## 🏗️ 3. Domain & Entity Layer
- **File**: `lib/domain/entities/checkin_data.dart`
- **Class**: `CheckinData`
- **Fields**:
  - `int energyLevel` (Range: 1 to 5)
  - `String mood` (Valid values: '😴', '😐', '🙂', '😊', '🔥')
  - `String focusMode` (Valid values: 'Deep Work', '미팅 모드', '가벼운 업무')
- **Logic**: Must have cleanly formatted `Map<String, dynamic> toJson()` method.
- **Unit Test**: `test/domain/entities/checkin_data_test.dart` verifying object to JSON serialization without syntax errors.

## 🌐 4. Data & Network Layer
- **File**: `lib/data/datasources/planner_api_client.dart`
- **Endpoint**: `POST http://192.168.45.61:8080/api/health/daily-checkin`
- **Payload**: JSON serialization of `CheckinData`.
- **Error Handling**: Graceful fallback. If `DioException` occurs (timeout, 404, 500), catch it and throw a custom `Exception('서버 연결 실패. 다시 시도해주세요.')` rather than crashing the app.
- **Unit Test**: `test/data/datasources/planner_api_client_test.dart` mocking Dio to test both 200 OK and 500 Error paths.

## 🧠 5. Presentation Layer (State Management)
- **File**: `lib/presentation/providers/checkin_provider.dart`
- **State Enum**: `enum CheckinState { idle, loading, success, error }`
- **Provider**: `StateNotifier<CheckinState>` utilizing Riverpod `StateNotifierProvider`.
- **Method**: `Future<void> submitCheckin(CheckinData data)`. 
  - On trigger -> `state = CheckinState.loading`
  - Try API Call -> If success, `state = CheckinState.success`
  - If exception -> `state = CheckinState.error(message)`

## 🎨 6. UI Layer (Premium Glassmorphism)
- **File**: `lib/presentation/screens/checkin_screen.dart`
- **Theme Concept**: Deep Abyss. Use a background `Container` with a dark linear gradient (`Color(0xFF0F2027)` to `Color(0xFF203A43)` to `Color(0xFF2C5364)`).
- **Core Component**:
  - A main Card wrapped in `ClipRRect` and `BackdropFilter` (blur: sigmaX 15, sigmaY 15).
  - Background color: `Colors.white.withOpacity(0.05)`.
  - Border: `Border.all(color: Colors.white.withOpacity(0.2))`.
- **Inputs**:
  - `energyLevel`: A row of 5 clickable `IconButton(Icons.star)` wrapping a local value.
  - `mood`: `Wrap` of emojis using gesture detectors or simple TextButtons.
  - `focusMode`: `Wrap` of 3 `ChoiceChip`s explicitly styled with rounded corners.
- **Action**: A bottom gradient submit button. If `checkinProvider` is `loading`, display `CircularProgressIndicator` instead of text. Upon success, show `SnackBar("오늘의 AI 플래너가 생성되었습니다!")`.

## ⚙️ 7. Main Integration & Wiring
- **File**: `lib/main.dart`
- **Logic**: 
  - Wrap the `runApp` widget in `ProviderScope`. 
  - Configure `MaterialApp` with `ThemeData.dark()`.
  - Apply `GoogleFonts.interTextTheme()` for clean typography.
  - Set `home: CheckinScreen()`.

## 🛑 8. Execution Directives for omo (Night Shift)
1. **No Hallucination**: Do not report success strictly based on LLM text output. You MUST run `flutter analyze` or `flutter test` via terminal command tools to prove success.
2. **Atomic Commits**: Generate one layer at a time (e.g., Domain -> test -> verify. Data -> test -> verify). Do not combine multiple layers in a single tool call to prevent 4-bit precision loss.
