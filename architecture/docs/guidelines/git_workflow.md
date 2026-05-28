# Solve-for-X Git 형상 관리 및 개발 워크플로우 가이드라인

본 문서는 `Solve-for-X` 마이크로 앱 팩토리 및 보안 샌드박스 컴포넌트 개발 시 형상 관리의 투명성과 추적 가능성(Auditability)을 보장하기 위한 Git 협업 가이드라인입니다.

---

## 📌 1. Conventional Commits 커밋 규격

모든 커밋 메시지는 Conventional Commits 명세 및 프로젝트 검증 규칙을 반드시 충족해야 합니다. 규칙 위반 시 깃 커밋 훅(Commit Hook)에 의해 자동으로 차단됩니다.

### 기본 형식
```
<type>(<scope>): <subject> (resolves #<issue_number> 또는 refs #<issue_number>)
```

### 1. 허용하는 Type (Type List)
* `feat`: 새로운 기능 추가 (앱 코드, 레이아웃 등)
* `fix`: 버그나 컴파일 오류 수정
* `docs`: 문서 작성 및 수정 (README, 이슈, 워크스루 등)
* `style`: 코드 구조 스타일, 마크업 레이아웃, CSS 수정 (기능 변화 없음)
* `refactor`: 코드 리팩토링 (성능 개선, 중복 제거 등)
* `test`: 테스트 코드 추가 및 정적 린트/분석 검사 수정
* `chore`: 빌드 업무, 패키지 매니저 설정, 단순 자원 복사, 릴리즈 등

### 2. 영향 범위 명시 (Scope Constraint)
커밋의 영향 범위를 명시할 때는 반드시 `apps/`, `infra/`, `libs/` 등의 접두사로 시작하는 모듈 명을 기입해야 합니다.
* **예시:**
  * `feat(apps/todo): write JSON spec for Simple Todo application (resolves #9)`
  * `style(infra/dashboard): reorganize layout to clearly separate telemetry and controls (refs #8)`
  * `chore(apps/safetask): include accumulated local specifications (refs #7)`

---

## 📂 2. 로컬 마일스톤 및 이슈 관리 아키텍처

원격 GitHub 이슈 트래커의 토큰 만료 우회 및 완전한 온디바이스 개발 이력 보존을 위해 **'로컬 이슈 보드'** 시스템을 운용합니다.

### 1. 파일 보관 위치
```
architecture/docs/milestones/
```

### 2. 구성 요소
* **`milestone_*.md` (마스터 로드맵):** 해당 마일스톤의 목표, 시작일, 전체 이슈 리스트 및 완료 상태를 종합적으로 추적합니다.
* **`issue_*.md` (개별 이슈 문서):**
  - 개별 이슈 번호(Issue Number)를 제목으로 부여합니다 (예: `Issue #8: [Infra] ...`).
  - 이슈의 상태 (`완료 대기`, `진행 중`, `완료 (Completed)`)를 기록합니다.
  - 해당 이슈를 해결하기 위해 발행해야 하는 구체적인 Conventional Commits 리스트와 설명(Todo)을 템플릿화하여 보관합니다.

---

## 🔄 3. 실시간 QA 및 릴리즈 빌드 연동 파이프라인

1. **사양 정의 (Specification Phase):** 신규 앱의 구조를 JSON 규격으로 작성합니다.
2. **코드 주조 (Synthesis Phase):** `engine.py` 가동을 통해 무결성 소스코드를 자동 생성합니다.
3. **정적 무결성 스캔 (Integrity Phase):** 생성 폴더 내에서 `flutter analyze`를 가동해 Lint 경고와 에러를 0개 상태로 검증합니다.
4. **프로덕션 컴파일 (Compilation Phase):** `flutter build web --release`를 성공 완료시킵니다.
5. **원격 시뮬레이터 바인딩 (Web Preview):** 심볼릭 링크(`active_web_preview`)를 빌드 결과로 매핑하여 포트 `8502`로 클라이언트를 서빙합니다.
6. **동영상 증명 (Visual Proof):** Browser 서브에이전트를 가동해 시연 영상(`recording.webm`)을 캡처한 뒤 `walkthrough.md`에 최종 연동합니다.

---

## 💡 4. 권장 저장 및 자주 활용하는 요령

> [!TIP]
> * **이 가이드를 어디에 저장하나요?**
>   - 이 문서는 프로젝트의 코어 개발 원칙이므로 `architecture/docs/guidelines/git_workflow.md`에 저장하고, 프로젝트 루트 `README.md` 상단에 하이퍼링크로 연결해두는 것이 가장 좋습니다.
> * **에이전트와의 협업 시 활용 요령:**
>   - 새로운 작업을 요청받았을 때, **"docs/guidelines/git_workflow.md 가이드에 입각해서 마일스톤 계획부터 세우고 결재해줘"**라고 요청하십시오. 
>   - 그러면 AI 에이전트가 이 문서를 읽어 스스로 `issue_*.md` 뼈대를 작성하고, 촘촘한 커밋 플랜을 명시한 구현 계획서(implementation_plan.md)를 완벽하게 선제 보고할 것입니다.
