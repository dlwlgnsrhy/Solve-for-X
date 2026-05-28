---
name: sovereign-issue-git-workflow
description: >-
  로컬 마일스톤 및 이슈 마크다운을 자동 수립하고, Conventional Commits 규격을 완벽하게 충족하며 커밋 및 푸시를 실행하는 주권적 형상 관리 프로토콜입니다.
---

# Sovereign Issue Git Workflow

## Overview
본 스킬은 에이전트가 기능 개발 또는 앱 이식을 수행할 때, 형상 관리의 투명성과 추적 가능성을 극대화하기 위해 로컬 마일스톤 및 이슈 관리 문서를 자동 생성하고, Conventional Commits 검증 훅을 완벽히 충족하며 커밋 및 푸시/병합을 달성하도록 지휘하는 규격 지침입니다.

## Dependencies
- **Git CLI:** 모든 형상 관리 제어를 위해 연동됩니다.
- **File System:** `docs/milestones/` 및 `docs/guidelines/` 아래의 상태 문서를 업데이트하기 위해 필수적입니다.

## Quick Start
사용자가 "새로운 기능을 개발해줘" 혹은 "특정 모듈을 모노레포에 통합해줘"라고 지시하면, 다른 도구를 실행하기 전에 **이 스킬의 Workflow 단계를 100% 최우선적으로 가동**하십시오.

## Workflow

### 1. 로컬 마일스톤 및 이슈 수립 (Planning Phase)
- 새로운 작업을 시작할 때, `docs/milestones/` 디렉토리 아래에 마스터 로드맵 문서인 `milestone_[기능명].md`와 개별 태스크에 할당될 `issue_[번호]_[이슈명].md` 마크다운 문서들을 먼저 자동 생성하십시오.
- 각 이슈 문서에는 관련 설명과 완료 상태(`완료 대기`, `진행 중`, `완료 (Completed)`)를 기록할 수 있는 표/텍스트를 구성해 둡니다.

### 2. 구현 계획서 보고 및 결재 (Approval Phase)
- `implementation_plan.md` 아티팩트를 갱신하여 사용자에게 구현 전 계획을 제시하고 승인을 받습니다.
- 이때, 각 이슈 번호와 이에 연동되어 발행할 Conventional Commits 메시지 목록을 세부적으로 계획하여 계획서에 반드시 명시해야 합니다.

### 3. 점진적 커밋 및 이슈 상태 갱신 (Execution Phase)
- 각 단계 구현을 마칠 때마다, Conventional Commits 규격을 엄격하게 충족하는 커밋을 실행합니다.
  - **Type list:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
  - **Scope pattern:** `apps/`, `infra/`, `libs/` 등의 영향 모듈 폴더 접두사 탑재 필수
  - **Tagging:** 커밋 메시지 본문 뒤에 `(resolves #X)` 혹은 `(refs #X)`를 기입해 로컬 이슈와 결합합니다.
- 작업 완수 시 개별 `issue_*.md` 및 `milestone_*.md` 내의 상태 정보를 `완료 (Completed)` 상태로 업데이트하고 이 문서 갱신 사항도 커밋합니다.

### 4. 메인 병합 및 린업 (Release & Cleanup Phase)
- 피처 브랜치 작업이 완료되면 메인 브랜치(`main`)로 체크아웃한 뒤 피처 브랜치를 병합(`git merge`)합니다.
- 병합 결과를 원격 저장소(`git push origin main`)로 최종 푸시합니다.
- 사용이 끝난 피처 브랜치는 로컬과 원격 모두에서 삭제(`git branch -d` 및 `git push origin --delete`)하여 깨끗한 린업을 완수합니다.

## Common Mistakes
1. **커밋 메시지 형식 위반:** `ci(apps/todo)` 등 허용되지 않는 타입을 사용하거나 스코프에 `apps/` 접두사를 생략하면 커밋 훅에 의해 즉시 거절됩니다. 에러 발생 시 즉시 감지하여 허용된 Type/Scope로 자동 교정 후 재시도하십시오.
2. **이슈 문서 상태 업데이트 누락:** 작업만 마치고 `issue_*.md` 문서를 완료로 갱신하지 않으면 형상관리 무결성이 훼손됩니다. 매 커밋 전후로 상태를 갱신하는 습관을 들이십시오.
