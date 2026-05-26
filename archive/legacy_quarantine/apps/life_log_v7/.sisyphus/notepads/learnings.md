# Conventions & Patterns

- Barrel export files go in package root (e.g., `lib/domain/domain.dart`)
- Re-export using `export 'relative/path.dart';`
- Domain files are IMMUTABLE: checkin_data.dart, planner_repository.dart
- Riverpod 2.5.1: StateNotifier with `state = ...`, `.autoDispose`
- Dio 5.x: returns Response<String>, parse JSON manually
- google_fonts 6.3.2: `GoogleFonts.inter()` returning TextStyle

## Task 5: PlannerApiClient TDD RED Tests
- mockito's `any()`/`anyNamed()` matchers fail with hand-written `Mock extends Mock implements Dio` classes due to analyzer type inference treating mock method return types as `Null`
- WORKAROUND: override the mock method explicitly and capture call data in instance fields
- Stub class `PlannerApiClient` with `UnimplementedError` is the correct TDD RED pattern
- Test compiles clean (0 analyzer errors) while failing at runtime — proper RED state
