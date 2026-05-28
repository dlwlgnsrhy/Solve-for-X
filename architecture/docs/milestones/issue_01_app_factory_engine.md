# Issue #1: [Infra] App Factory Engine & Local Fallback API Chain Integration

* **상태:** 완료 대기
* **담당자:** AI Coding Agent
* **설명:**
  로컬 앱 팩토리 파이프라인에서 핵심을 담당하는 파이썬 생성 엔진 코드를 이식하고, `.env`를 통한 환경 변수 세팅 및 구글 Generative Language API 모델 우선순위 체인(Gemini 3.5 Flash, Gemma 4, Gemini 2.5 Flash)을 가동하기 위한 연동을 진행합니다.
* **관련 커밋:**
  * `Commit 1-1`: `feat(factory): import App Factory Engine files and core python structures (resolves #1)`
  * `Commit 1-2`: `config(factory): establish secure local env configuration template (refs #1)`
  * `Commit 1-3`: `feat(factory): configure fallback API routing models chain (Gemini 3.5, Gemma 4) (refs #1)`
