# Issue #12: [Apps] brand-web Relative Path Routing & Dynamic Integration

* **상태:** 완료 (Completed)
* **담당자:** AI Coding Agent
* **설명:**
  `Solve-for-X` 모노레포 하위의 brand-web 포털로 다중 테넌트 웹 앱들을 안전하게 자동 병합합니다. 정적 자원 404 에러를 방지하기 위해 `index.html` 내의 `<base href="/">`를 `<base href="/apps/[app_id]/">`로 자동 치환하는 정규식 패처를 주조 엔진에 탑재하고, `apps_registry.json`을 통해 brand-web 포털이 카드를 동적으로 렌더링하도록 연동합니다.
* **관련 커밋:**
  * `Commit 12-1`: `feat(infra/engine): implement Flutter index.html base href regex auto-patcher (resolves #12) [8033a23]`
  * `Commit 12-2`: `feat(apps/brand-web): establish registry mapper and dynamic iframe loader interface (refs #12) [fed3bc1]`
