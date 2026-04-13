# 7. 기획(Antigravity)과 구현(로컬 31B 모델) 분리형 Dual-Agent 개발 파이프라인 도입 및 브랜드 생태계 피벗

Date: 2026-04-14

## Status
Accepted

## Context
- Solve-for-X 브랜드 포트폴리오 기획 과정에서, 단일 앱이 아닌 생애 주기(Living Well = Dying Well)를 포괄하는 5대 프로덕트(Life-Log, Finance, Career Vault, Imjong Care, Time Capsule) 에코시스템이 설계되었습니다.
- 앱 기획에 대한 사용자(설계자)의 철학적 가이드라인에 따라, 리스크가 큰 앱(Finance Dashboard)은 개인용 내부망으로 한정하고 Time Capsule은 무기한 보류하며, Imjong Care는 MZ세대를 타겟팅한 긍정적 회고/소셜 유서 앱으로 스코프(Scope)를 피벗(Pivot)하기로 합의했습니다.
- 위 거대한 에코시스템을 개발함에 있어, 비용 효율화와 구글 SRE 관점의 강력한 오케스트레이션(Orchestration)을 실험하기 위해 **Dual-Agent 파이프라인** 아키텍처 실험이 대두되었습니다.
- 단일 A100 GPU 환경에서 로컬 `gemma-4-31b-dense` 모델이 OpenCode 도구를 사용해 코딩 무한루프를 돌 경우, 모델의 컨텍스트 한계(Context Limit)로 인해 대형 태스크 지시 시 환각(Hallucination) 및 코드 유실이 발생할 위험이 있습니다.

## Decision
- **SRE 오케스트레이션 (Dual-Agent Pipeline) 채택**
  - **Antigravity (고사양 API 모델):** 프로덕트 매니저(PM) 겸 수석 아키텍트 역할을 수행합니다. 전체 스코프를 조율하고, VRAM 한계를 가진 로컬 모델이 소화할 수 있도록 코딩 작업을 가장 작은 최소 단위(Micro-Task / Atomic PR)로 쪼개어 지시서를 생성합니다.
  - **Gemma 31B (로컬 모델):** 개발(Coder) 역할을 수행합니다. OpenCode를 통해 Antigravity가 하달한 명세서를 그대로 이행합니다.
  - **Human-in-the-Loop (설계자 개입):** 인간은 Antigravity의 설계 명세서를 복사해 Gemma에게 전달하고, 발생한 논리적 결함을 Antigravity에게 되먹임(Feedback Routing)하는 프록시 관리자 역할을 합니다.
- **포트폴리오 우선순위 결정**
  - 당장 매일의 자동화 스크립트 효율을 높여줄 생체 센서 앱인 **SFX Life-Log (Health Connect 연동부)**를 Dual-Agent 파이프라인의 첫 번째 실전 프로젝트로 선정하여 착수합니다.

## Consequences
- **Positive:**
  - AI에게 '스스로 통제권'을 모두 주었을 때 범하는 오류(블랙박스화)를 막고, 단위 테스트 수준의 철저한 코드 품질 검증이 가능해집니다.
  - 로컬 자원(A100)을 100% 활용하면서도, 고급 모델의 티켓 분석 능력을 결합해 비용(Token Cost)과 논리(Logic)의 완벽한 밸런스를 맞출 수 있습니다.
- **Negative:**
  - 인간 관리자가 중간에서 복사/붙여넣기를 하거나 에러를 판별해 프록시 역할을 계속 수행해야 하므로 100% 물리적 무인 자동화보다는 피로도가 존재합니다.
