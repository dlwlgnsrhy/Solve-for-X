# Life-Log V5 Implementation Plan

## TL;DR

> **Quick Summary**: Implementation of a Flutter-based daily health check-in app with strict TDD for logic layers and premium glassmorphism UI.
> 
> **Deliverables**:
> - Fully functional Flutter app in `/apps/life_log_v5`
> - Unit tests for Domain and Data layers
> - Glassmorphism UI implementation
> - API integration with error handling
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 4 Waves
> **Critical Path**: Project Init → Domain/Data TDD → Provider Logic → UI Integration → Final QA

---

## Context

### Original Request
Build a "Life-Log V5" application as per the architecture blueprint, emphasizing the prevention of syntax hallucinations via strict TDD and terminal-based verification (`flutter test`, `flutter analyze`).

### Interview Summary
- **Test Strategy**: Strict TDD for Domain and Data layers. Agent-Executed QA for UI.
- **Key Constraints**: No reporting success without terminal proof. Atomic commits per layer.
- **Tech Stack**: Flutter, Riverpod, Dio, Google Fonts.

### Metis Review (Integrated)
- **Guardrails**: Every logic task must follow the sequence: Write Test → Run Test (Fail) → Write Code → Run Test (Pass).
- **Edge Cases**: Explicit handling of `DioException` for network timeouts and server errors.
- **UI Verification**: Visual confirmation via screenshots of the Glassmorphism effect.

---

## Work Objectives

### Core Objective
Create a high-fidelity, stable Flutter app for health check-ins that adheres to a professional layered architecture.

### Concrete Deliverables
- `lib/domain/entities/checkin_data.dart` + tests
- `lib/data/datasources/planner_api_client.dart` + tests
- `lib/presentation/providers/checkin_provider.dart`
- `lib/presentation/screens/checkin_screen.dart`
- `lib/main.dart`

### Definition of Done
- [ ] `flutter analyze` returns zero errors.
- [ ] `flutter test` passes for all domain and data tests.
- [ ] API call successfully sends JSON to the specified endpoint.
- [ ] UI matches the "Deep Abyss" Glassmorphism specification.

### Must Have
- Strict TDD for logic layers.
- Glassmorphism UI (Blur: 15, Opacity: 0.05, White border).
- Error handling for the API client.

### Must NOT Have
- No manual "looks good" confirmations; must provide terminal output.
- No combined layer implementations in a single task.

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO (Project being created)
- **Automated tests**: YES (TDD for Domain/Data)
- **Framework**: `flutter_test`
- **UI QA**: Agent-Executed via `flutter analyze` and screenshots.

### QA Policy
Every task MUST include terminal-based evidence. Logic tasks require `flutter test` logs. UI tasks require `flutter analyze` logs and visual evidence.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation):
├── Task 1: Project Scaffolding & Dependencies [quick]
└── Task 2: Domain Entity & TDD [deep]

Wave 2 (Data & Logic):
├── Task 3: API Client & TDD [deep]
└── Task 4: Riverpod State Provider [unspecified-high]

Wave 3 (UI Development):
├── Task 5: Theme & Global Styles [visual-engineering]
└── Task 6: CheckinScreen Glassmorphism UI [visual-engineering]

Wave 4 (Integration & Final Polish):
└── Task 7: Main Entry Point & Wiring [quick]

Wave FINAL (Review):
├── Task F1: Plan Compliance Audit [oracle]
├── Task F2: Code Quality Review [unspecified-high]
├── Task F3: Real Manual QA [unspecified-high]
└── Task F4: Scope Fidelity Check [deep]
```

### Dependency Matrix
- **Task 1**: - $\rightarrow$ 2, 3, 5, 7
- **Task 2**: 1 $\rightarrow$ 3, 4
- **Task 3**: 2 $\rightarrow$ 4
- **Task 4**: 3 $\rightarrow$ 6, 7
- **Task 5**: 1 $\rightarrow$ 6
- **Task 6**: 4, 5 $\rightarrow$ 7
- **Task 7**: 6 $\rightarrow$ FINAL

---

## TODOs

- [ ] 1. **Project Scaffolding & Dependencies**

  **What to do**:
  - Run `flutter create --no-pub .` in `/apps/life_log_v5`.
  - Add `flutter_riverpod: ^2.5.1`, `dio: ^5.4.1`, `google_fonts: ^6.3.2` to `pubspec.yaml`.
  - Run `flutter pub get`.
  - Verify folder structure.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (Foundation)
  - **Parallel Group**: Wave 1
  - **Blocks**: 2, 3, 5, 7
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `ls -la` shows standard Flutter project structure.
  - [ ] `pubspec.yaml` contains all three specified dependencies.

  **QA Scenarios**:
  ```
  Scenario: Dependency Verification
    Tool: Bash
    Steps:
      1. grep "flutter_riverpod" pubspec.yaml
      2. grep "dio" pubspec.yaml
      3. grep "google_fonts" pubspec.yaml
    Expected Result: All three dependencies found with correct versions.
    Evidence: .sisyphus/evidence/task-1-deps.txt
  ```

- [ ] 2. **Domain Entity & TDD**

  **What to do**:
  - Write `test/domain/entities/checkin_data_test.dart` first.
  - Implement `lib/domain/entities/checkin_data.dart` with `energyLevel` (1-5), `mood`, and `focusMode`.
  - Implement `toJson()` method.
  - Run `flutter test` to verify serialization.

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: 3, 4
  - **Blocked By**: 1

  **Acceptance Criteria**:
  - [ ] `flutter test test/domain/entities/checkin_data_test.dart` $\rightarrow$ PASS.
  - [ ] `flutter analyze` $\rightarrow$ NO errors.

  **QA Scenarios**:
  ```
  Scenario: JSON Serialization Happy Path
    Tool: Bash (flutter test)
    Steps:
      1. Create CheckinData object.
      2. Call toJson().
      3. Assert map contains correct keys and values.
    Expected Result: Test PASS.
    Evidence: .sisyphus/evidence/task-2-test.txt
  ```

- [ ] 3. **API Client & TDD**

  **What to do**:
  - Write `test/data/datasources/planner_api_client_test.dart` mocking Dio.
  - Implement `lib/data/datasources/planner_api_client.dart`.
  - Implement POST to `http://192.168.45.61:8080/api/health/daily-checkin`.
  - Implement `DioException` handling to throw custom Exception.
  - Run `flutter test`.

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 4
  - **Blocked By**: 2

  **Acceptance Criteria**:
  - [ ] `flutter test test/data/datasources/planner_api_client_test.dart` $\rightarrow$ PASS (covering both 200 and 500 responses).
  - [ ] `flutter analyze` $\rightarrow$ NO errors.

  **QA Scenarios**:
  ```
  Scenario: API Error Handling
    Tool: Bash (flutter test)
    Steps:
      1. Mock Dio to return 500 Internal Server Error.
      2. Call API client.
      3. Assert custom Exception '서버 연결 실패...' is thrown.
    Expected Result: Test PASS.
    Evidence: .sisyphus/evidence/task-3-error-test.txt
  ```

- [ ] 4. **Riverpod State Provider**

  **What to do**:
  - Implement `lib/presentation/providers/checkin_provider.dart`.
  - Define `enum CheckinState { idle, loading, success, error }`.
  - Implement `StateNotifier<<CheckCheckinState>` and `submitCheckin` method.
  - Integrate `PlannerApiClient`.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2
  - **Blocks**: 6, 7
  - **Blocked By**: 3

  **Acceptance Criteria**:
  - [ ] `flutter analyze` $\rightarrow$ NO errors.
  - [ ] Provider correctly transitions from `idle` $\rightarrow$ `loading` $\rightarrow$ `success/error`.

  **QA Scenarios**:
  ```
  Scenario: Provider State Transition
    Tool: Bash (flutter test - if applicable, or analyze)
    Steps:
      1. Trigger submitCheckin.
      2. Check state is 'loading'.
      3. Wait for API response.
      4. Check state is 'success'.
    Expected Result: State transitions as expected.
    Evidence: .sisyphus/evidence/task-4-state.txt
  ```

- [ ] 5. **Theme & Global Styles**

  **What to do**:
  - Define a theme utility or constants for the "Deep Abyss" colors.
  - Set up the gradient colors: `Color(0xFF0F2027)`, `Color(0xFF203A43)`, `Color(0xFF2C5364)`.

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: 6
  - **Blocked By**: 1

  **Acceptance Criteria**:
  - [ ] Color constants are correctly defined.

  **QA Scenarios**:
  ```
  Scenario: Theme Constant Verification
    Tool: Bash (flutter analyze)
    Steps:
      1. Verify theme file exists and compiles.
    Expected Result: No errors.
    Evidence: .sisyphus/evidence/task-5-theme.txt
  ```

- [ ] 6. **CheckinScreen Glassmorphism UI**

  **What to do**:
  - Implement `lib/presentation/screens/checkin_screen.dart`.
  - Background: Deep Abyss Gradient.
  - Glassmorphism Card: `BackdropFilter` (blur 15), white opacity 0.05, border opacity 0.2.
  - Energy Level: Row of 5 star icons.
  - Mood: Wrap of emojis.
  - Focus Mode: 3 styled ChoiceChips.
  - Bottom Gradient Button: State-aware (Loading indicator vs Text).

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: 7
  - **Blocked By**: 4, 5

  **Acceptance Criteria**:
  - [ ] `flutter analyze` $\rightarrow$ NO errors.
  - [ ] UI contains all specified input components.

  **QA Scenarios**:
  ```
  Scenario: UI Visual Layout Check
    Tool: Playwright/Screenshot (if available) or flutter analyze
    Steps:
      1. Verify presence of BackdropFilter in the widget tree.
      2. Verify gradient background implementation.
    Expected Result: Glassmorphism visual elements present.
    Evidence: .sisyphus/evidence/task-6-ui-screen.png
  ```

- [ ] 7. **Main Entry Point & Wiring**

  **What to do**:
  - Update `lib/main.dart`.
  - Wrap with `ProviderScope`.
  - Set `ThemeData.dark()`.
  - Apply `GoogleFonts.interTextTheme()`.
  - Set `home: CheckinScreen()`.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4
  - **Blocks**: FINAL
  - **Blocked By**: 6

  **Acceptance Criteria**:
  - [ ] App launches without crashing.
  - [ ] `flutter analyze` $\rightarrow$ NO errors.

  **QA Scenarios**:
  ```
  Scenario: App Launch Verification
    Tool: Bash
    Steps:
      1. Run 'flutter run' or build command.
      2. Verify app starts and displays CheckinScreen.
    Expected Result: App launches successfully.
    Evidence: .sisyphus/evidence/task-7-launch.txt
  ```

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Verify every "Must Have" (TDD for logic, Glassmorphism UI) is implemented. Check that `test/` files exist for Domain and Data layers.
  Output: `Must Have [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `flutter analyze` and `flutter test`. Check for `as dynamic` or ignored errors.
  Output: `Analyze [PASS/FAIL] | Tests [N pass/0 fail] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Execute the full flow: Open App $\rightarrow$ Select Energy/Mood/Focus $\rightarrow$ Submit $\rightarrow$ Verify SnackBar.
  Output: `Flow [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  Compare final files against the blueprint. Ensure no unauthorized features were added.
  Output: `Fidelity [SURE/FAIL] | VERDICT`

---

## Commit Strategy

- **C1**: `feat(init): initialize project and dependencies`
- **C2**: `feat(domain): implement CheckinData and tests`
- **C3**: `feat(data): implement PlannerApiClient and tests`
- **C4**: `feat(presentation): implement checkin provider`
- **C5**: `feat(ui): implement glassmorphism checkin screen`
- **C6**: `feat(main): wiring and app entry point`

---

## Success Criteria

### Verification Commands
```bash
flutter analyze
flutter test
```

### Final Checklist
- [ ] All logic layers have accompanying tests that pass.
- [ ] Glassmorphism visual specs (blur 15, opacity 0.05) are applied.
- [ ] API error handling is verified.
- [ ] Zero analysis errors in the project.
