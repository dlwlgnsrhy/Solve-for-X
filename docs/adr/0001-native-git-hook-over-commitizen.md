# 1. Commitizen 등 서드파티 도구 도입 거절 및 Native Git Hook 채택

Date: 2026-03-27

## Status
Accepted

## Context
- SRE 에이전트와 레거시 설계자 간의 원활한 소통 및 릴리스 자동화를 위해 **Conventional Commits** 형식을 100% 강제해야 합니다.
- Node.js 기반의 `commitizen`, `husky`, `commitlint` 등을 도입하여 규칙을 강제하는 방법이 있으나, 이는 무거운 패키지 의존성(Node.js, npm/yarn)을 프로젝트에 추가하게 됩니다.
- 우리는 '최소한의 도구로 컨트롤하는 방법'을 핵심 가치로 지향하므로 추가적인 의존성 설치를 지양하고자 합니다.

## Decision
- 우리는 개발 편의성을 위한 Commitizen 및 이를 제어하는 Node.js 기반의 의존성(hook 관리자 등) 도입을 **거부(Reject)**합니다.
- 대신, Git 시스템에 내장된 순수 Bash 스크립트 기능인 **Native Git Hook (`.git/hooks/commit-msg`)**만을 사용하여 커밋 규칙을 엄격하게 강제합니다.
- 작성된 Bash 스크립트는 정규식을 통해 커밋 메시지를 검증하며, 'update', 'fix bug' 등의 모호한 단어 사용을 원천 차단합니다.
- 이는 CLI 툴, VS Code, **GitHub Desktop** 등 모든 Git 클라이언트에서 동일하게 완벽한 제어력을 보장합니다.

## Consequences
- **Positive:** 프로젝트 저장소가 매우 가볍게 유지되며(디펜던시 Zero), 모든 개발 환경에서 별도의 의존성 설치(`npm install` 등) 없이 즉각적으로 규약이 강제됩니다. 
- **Negative:** 대화형 CLI 보조 도구가 없으므로 커밋 메시지의 접두사(`feat()`, `fix()` 등)를 개발자가 직접 타이핑해야 합니다.

### 💡 첨부: GitHub Desktop 워크플로우 예시
Native Git Hook은 Git 코어 기능이므로 GitHub Desktop 커밋 버튼을 누르는 즉시 개입합니다.
- **성공 시:** 아무런 방해 없이 즉시 커밋 완료 및 타임라인 생성.
- **실패 시:** GUI 팝업으로 커밋이 차단되며, "에러 메시지 및 모호한 메시지 금지" 로그가 출력됩니다. 올바르게 제목을 수정 후 제출하면 통과합니다.
