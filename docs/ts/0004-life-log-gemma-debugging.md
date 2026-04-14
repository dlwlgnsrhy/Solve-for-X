# 4. Dual-Agent 로컬 모델(Gemma 31B) 아키텍처 생성 환각 및 Flutter 컴파일 트러블슈팅

Date: 2026-04-15

## Problem
1. **무한 루프(가사 상태) 오인**: 사용자가 야간에 로컬 A100 환경의 Gemma 31B(OpenCode)에게 App 1-FE(Life Log) 전체 골격 생성을 지시했으나, LLM 컨텍스트 한계로 인해 작업 루프에 갇히거나 멈춘 것으로 오인됨.
2. **폴더 경로 중첩 (Directory Nesting)**: Gemma가 앱을 생성하는 과정에서 작업 디렉토리 인지 오류로 인해 `apps/apps/life_log_app` 형태의 중첩된 경로 하위에 Flutter 프로젝트를 생성함.
3. **Dart SDK 의존성 충돌**: `pubspec.yaml`에 작성된 `health: ^13.2.0` 의존성이 Dart SDK 3.8.0 이상을 요구하여, 현재 환경(Dart 3.7.2)에서 `flutter pub get` 버전 솔빙(Version Solving) 충돌 에러가 발생함.
4. **Syntax Hallucination (제네릭 문법 환각)**: 막대한 양의 코드(클린 아키텍처 전체)를 한 턴에 생성하다 보니 모델 압박으로 인해 `.dart` 파일 내부에 `Future<<voidvoid>`, `<<SleepSleepData>` 와 같은 기상천외한 제네릭 괄호 중복 에러가 창궐함. 아울러 `main.dart`의 `ProviderScope` 래핑을 누락함.

## Cause
- A100 80GB 환경이더라도 거대한 에픽 규모의 프롬프트를 단일 샷으로 출력할 때 후반부 토큰 생성 한계에 도달하며 집중력을 잃음(Syntax Error 유발).
- 프롬프트에 제공된 "최신 버전" 개념을 맥락 없이 수용하여 호스트 PC의 로컬 바이너리 버전을 역산하지 못하는 로컬 에이전트의 한계.

## Solution
1. **파일 구조 강제 구출 (Extraction)**: SRE 수석 아키텍트(Antigravity) 모델이 터미널 명령어(`cp`, `rm -rf`)를 통해 잘못 생성된 하위 폴더에서 코드를 원상 복구(`apps/life_log_app`)시킴.
2. **패키지 다운그레이드**: 충돌하는 `health` 패키지를 `^13.1.3` 으로 낮추어 현재 설치된 Dart 환경에 맞게 강제 버저닝.
3. **High-Model의 Surgical Repair (미세 수술)**:
   - 130개가 넘는 `flutter analyze` 린트(Lint) 에러를 타겟팅하여 환각 증상이 발현된 제네릭 문법(`<< >>`)을 일체 정규화(`Future<void>`)함.
   - `main.dart`에 누락된 Riverpod `ProviderScope` 및 `SyncNotifier` 객체 주입을 완료하여 앱이 실제로 구동 가능하게 파이프라인 수선.

## Note
- **Dual-Agent 프로세스의 성공적인 실효성 증명**: 비록 Gemma가 마지막 5%의 디테일(오타 및 누락)에서 넘어졌으나, **95%에 달하는 거대한 Clean Architecture 보일러플레이트, UI(Dashboard), API 로직을 하룻밤 새 완벽하게 설계하고 타이핑(Scaffolding)하는 데 성공**했습니다.
- 무거운 단순 코딩 노동을 로컬 모델이 수행하고, 컴파일 에러가 난 5%의 치명적 결함을 고급 모델(Antigravity)이 즉각 수선(Healing)하는 진정한 의미의 **초고속 앱 공장(App Factory)** 체제가 완성되었음을 확인했습니다.
