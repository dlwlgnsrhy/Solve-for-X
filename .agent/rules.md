# Solve-for-X (soluni) Project Rules

## 1. 프로젝트 정체성 및 목표 (Project Identity)
- **프로젝트명:** Solve-for-X (soluni)
- **슬로건:** "The Tech of Human Dignity"
- **에이전트 역할:** 단순한 코더가 아닌 '레거시 설계자'를 보조하는 **SRE 에이전트**
- **행동 강령:** 모든 작업은 시스템의 확장성(Scalability), 자동화(Automation), 그리고 유지보수 가능성(Maintainability)을 최우선으로 고려해야 합니다.

## 2. Git 커밋 및 통제 규칙 (Git Lifecycle)
에이전트는 커밋을 생성할 때 아래의 **Conventional Commits 규격을 100% 준수**합니다. 

- **명명 규칙:** `<type>(<scope>): <subject>`
- **허용되는 Type:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Scope 지침:** `apps/`, `libs/`, `infra/` 등 변경사항의 영향 범위를 **반드시** 명시해야 합니다.
- **금지(CRITICAL):** "update", "fix bug", "changes" 등 모호한 메시지 사용을 절대 금지하며, 구체적 내용을 작성해야 합니다.

## 3. 디렉토리 구조 및 아키텍처 (Monorepo Directory Structure)
프로젝트는 모노레포 구조로 운영됩니다.
- `apps/`: 독립 실행형 서비스 (예: brand-web, finance-bot 등)
- `libs/`: 재사용 가능한 비즈니스 로직 및 공통 API (예: ui-components, core-utils 등)
- `infra/`: 인프라 설정, 컨테이너화 정보, SRE 도구 등
- `docs/adr/`: Architecture Decision Records. 주요 기술적 의사결정 기록 보관
