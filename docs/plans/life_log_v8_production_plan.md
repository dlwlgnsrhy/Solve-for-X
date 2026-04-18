# 🏭 Life-Log V8 — omo A-to-Z 앱 완성 시스템 검증

**작성일**: 2026-04-18  
**목적**: 오픈 LLM(Qwen 3.6) + omo로 앱을 **처음부터 끝까지** 만들 수 있는 시스템을 구축하고 검증  
**핵심 원칙**: V7 코드를 복사하지 않는다. omo가 빈 폴더에서 시작한다.

---

## 🧭 궁극적 비전

> **"오픈 LLM 하나로 앱 MVP가 나오는 파이프라인"**

V1~V7은 시행착오였다. 그 시행착오에서 얻은 **교훈**을 시스템(프롬프트 + 가드레일 + 검증 루프)에 녹여넣어서, 앞으로는 누구든 아래 3단계만 밟으면 앱이 나오는 구조를 만드는 것이 목표다.

```
[1] 요구사항 입력 (Tab → Prometheus)
[2] 실행 (/start-work)
[3] 아침에 결과 확인
```

---

## 📚 V1~V7 시행착오에서 추출한 시스템 규칙

| 버전 | 실패 원인 | 추출된 시스템 규칙 |
|------|----------|------------------|
| V1 | 기획 변경으로 폐기 | **R1**: 요구사항을 Prometheus 인터뷰로 확정한 뒤에만 코딩 시작 |
| V2 | 반복 루프 붕괴 (`}` 439회) | **R2**: 1턴에 1파일만 생성. 토큰 한계 초과 방지 |
| V3 | 도구 호출 환각 (파일 미생성) | **R3**: 파일 생성 후 반드시 `ls` 또는 `cat`으로 물리적 존재 검증 |
| V4 | 제네릭 문법 붕괴 | **R4**: 코드 작성 후 즉시 `flutter analyze` 실행. 에러 시 자체 수정 |
| V5 | 공수표 TDD (구현 없이 테스트만) | **R5**: 테스트 파일보다 구현 파일을 먼저 작성 |
| V6 | 스켈레톤 의존 (사람이 뼈대 작성) | **R6**: 사람이 코드를 미리 작성하지 않는다. omo가 전부 한다 |
| V7 | ✅ 성공했으나 DI 미완성 | **R7**: 앱이 크래시 없이 실행 가능한 상태까지 검증하고 끝낸다 |

---

## 🏗️ V8 시스템 설계: omo A-to-Z 파이프라인

### 입력: Prometheus에게 전달할 단 하나의 프롬프트

omo 터미널에서 **Tab → Prometheus** 진입 후, 아래 프롬프트를 붙여넣기합니다.  
이 프롬프트 안에 V1~V7의 모든 교훈이 **시스템 규칙**으로 내장되어 있습니다.

```
나는 Flutter 앱을 처음부터 만들고 싶어.

## 앱 요구사항
- 앱 이름: Life-Log V8
- 경로: /Users/apple/development/soluni/Solve-for-X/apps/life_log_v8
- 기능: 매일 아침 에너지(1-5), 기분(이모지), 포커스 모드를 체크인하면 AI 플래너 서버로 전송
- API: POST http://192.168.45.61:8080/api/health/daily-checkin (JSON body)
- 기술: Flutter, Riverpod(flutter_riverpod), Dio, GoogleFonts
- 아키텍처: Clean Architecture (domain → data → presentation)
- 디자인: 프리미엄 Glassmorphism (어두운 그라디언트 + 반투명 카드 + BackdropFilter)
- 성공 시: SnackBar "오늘의 AI 플래너가 생성되었습니다!"
- 실패 시: 에러 SnackBar + 재시도 가능

## 필수 시스템 규칙 (과거 7번의 실패에서 추출한 불변 규칙)
1. **프로젝트 초기화부터 시작**: flutter create --no-pub 또는 동등한 방법으로 빈 프로젝트 생성. 기존 코드를 절대 복사하지 말 것.
2. **1턴 1파일**: 한 번의 작업 단위에서 2개 이상의 파일을 동시에 생성하지 말 것. 토큰 한계 초과로 인한 반복 루프 붕괴를 예방한다.
3. **물리적 검증 필수**: 파일을 생성하거나 수정한 직후, 반드시 run_command로 ls 또는 cat을 실행하여 파일이 실제로 존재하는지 검증할 것. 텍스트로만 "만들었습니다"라고 보고하지 말 것.
4. **즉시 정적 분석**: 모든 .dart 파일 작성/수정 후 즉시 flutter analyze를 실행. 에러가 0건이 아니면 다음 파일로 넘어가지 말고 먼저 수정할 것.
5. **구현 우선**: 테스트 파일보다 구현 파일을 먼저 작성할 것. 구현체 없이 테스트만 존재하는 "공수표 TDD"를 금지한다.
6. **DI 완성까지 끝내기**: 앱이 크래시 없이 실행 가능한 상태까지 도달해야 "완료"다. Provider에 throw UnimplementedError를 남기지 말 것.
7. **제네릭 오타 금지**: Dart 제네릭 타입 선언 시 부등호를 절대 중복하지 말 것 (예: Future<<boolbool>, Map<<StringString> 금지).

## 완료 기준
- flutter analyze 에러 0건
- 앱 실행 시 크래시 없이 CheckinScreen이 표시됨
- 체크인 제출 → API 호출 → 성공/실패 SnackBar 표시 흐름이 동작
```

### 출력: `/start-work` 한 줄로 전체 실행

Prometheus가 설계서를 저장하면:

```
/start-work
```

Atlas가 설계서를 읽고, 다음 순서로 Sisyphus에게 위임합니다:

```
1. flutter create → pubspec.yaml 수정 → flutter pub get
2. domain/entities/checkin_data.dart
3. domain/repositories/planner_repository.dart
4. data/datasources/planner_api_client.dart
5. data/repositories/planner_repository_impl.dart
6. presentation/providers/checkin_provider.dart
7. presentation/screens/checkin_screen.dart
8. main.dart (DI 완성 + 테마 + 라우팅)
9. flutter analyze → 최종 검증
```

**각 파일 사이에 R2(1턴 1파일), R3(물리 검증), R4(즉시 분석)가 자동 적용됩니다.**

---

## 🔄 이 시스템의 재현 가능성

V8이 성공하면, 같은 프롬프트 구조로 **어떤 앱이든** 만들 수 있습니다:

```
[Life-Log]     → 건강 체크인 앱
[Finance]      → 자산 관리 대시보드
[Career Vault] → 경력 포트폴리오 앱
[Imjong Care]  → 임종 돌봄 앱
```

바뀌는 것은 **"앱 요구사항" 섹션**뿐이고,  
**"필수 시스템 규칙" 7개 + 완료 기준**은 불변입니다.

---

## 📊 성공 기준

| 항목 | 기준 |
|------|------|
| 시작점 | **빈 폴더** (V7 코드 복사 없음) |
| 사람 개입 | **0줄의 코드** (프롬프트만 제공) |
| flutter analyze | 에러 0건 |
| 앱 실행 | 크래시 없이 UI 표시 |
| 체크인 흐름 | API 호출 → SnackBar 피드백 동작 |
| 재현 가능 | 같은 프롬프트로 다른 앱도 생성 가능 |

---

## ⏰ 실행 타이밍

1. **지표님이 할 일**: omo 터미널에서 Tab → 위 프롬프트 붙여넣기 → `/start-work` → 취침
2. **아침 확인**: `flutter analyze` + `flutter run` 으로 검증
3. **성공 시**: 이 파이프라인을 다른 앱(Finance, Career Vault)에도 적용

---

**V8의 의미: 앱 하나를 만드는 것이 아니라, "앱을 만드는 시스템"을 만드는 것.**
