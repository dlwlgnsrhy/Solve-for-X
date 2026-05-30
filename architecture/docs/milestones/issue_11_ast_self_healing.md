# Issue #11: [Infra] AST-based Self-Healing Compiler Optimization

* **상태:** 완료 (Completed)
* **담당자:** AI Coding Agent
* **설명:**
  플러터 코드 합성 중 발생하는 린트 경고 및 문법 에러의 `flutter analyze` 결과를 AST(Abstract Syntax Tree) 분석기를 모방하여 파싱하고, 오작동이 나는 클래스, 메서드, 라인 구역을 핀포인트로 정교하게 치료하는 자가 치유(Self-Correction) 예외 극복 로직을 코어 엔진(`engine.py`)에 이식합니다.
* **관련 커밋:**
  * `Commit 11-1`: `feat(infra/engine): implement precise compiler traceback parser and AST pinpoint self-healing (resolves #11) [945babb]`
