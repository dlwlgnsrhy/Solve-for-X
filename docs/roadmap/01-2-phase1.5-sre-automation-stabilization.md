# Phase 1.5: SRE Automation Stabilization & Refinement

본 문서는 기존 Phase 1.5의 초자동화 파이프라인의 운영 불안정성을 해결하고, 실제 프로젝트 로드맵과 동기화된 고품질 콘텐츠를 생성하기 위한 상세 실행 전략을 정의합니다.

---

## 📋 핵심 과제 (Key Objectives)

1.  **로드맵 동시성 (Roadmap Sync)**: `daily_sre_bot`이 `ROADMAP.md`의 최신 상태를 파싱하여, 블로그 본문에 "오늘의 진척도"와 "내일의 목표"를 자동으로 포함시킵니다.
2.  **SRE 가치 증명 (Standardize Content)**: 요약 위주의 글을 지양하고, 구글 SRE의 5가지 핵심 원칙(Reliability, Automation 등) 관점에서 아카이브를 구성합니다.
3.  **운영 신뢰성 (Launchd Reliability)**: `launchd` 실행 상태를 텔레그램으로 즉시 보고받고, 실패 시 로그 요약을 전달받아 조치 시간을 최소화합니다.
4.  **포스팅 하이웨이 (Dev Connectivity)**: 생성된 초안이 `apps/brand-web`의 실제 노출 경로(`/blog/posts`)로 자동 이동하여 `npm run dev` 대기 중인 로컬 화면에서 즉시 확인 가능하게 합니다.

---

## 🛠️ 세부 작업 단계 (Detailed Tasks)

### 1단계: daily_sre_bot 코어 고도화
- [ ] `main.py` 내 `ROADMAP.md` 전용 파서(Parser) 구현 및 프롬프트 인젝션.
- [ ] 텔레그램 시작(`🚀 Start`) 및 에러(`❌ Error`) 핸들러 추가.
- [ ] `--publish` 플래그 추가: 초안을 `drafts/`에서 `posts/`로 자동 이동 및 깃 커밋 관리.

### 2단계: Launchd 인프라 재건
- [ ] `setup_launchd.sh`: `WorkingDirectory` 절대 경로 주입 및 가상환경(venv) 경로 명시.
- [ ] `com.soluni.dailysrebot.plist`: `StartCalendarInterval` 외에 실패 시 재시도 로직 보강.

### 3단계: 콘텐츠 퀄리티 가이드라인 (Prompt Engineering)
- [ ] AI 엔진(Qwen3 30B)에게 전달할 'SRE 사고 방식' 가이드라인 최적화.
- [ ] 한글 분석(Phase Analysis)과 영문 서사(Narrative)의 밸런스 조정.

---

## 📅 타임라인 및 마일스톤
- **Step 1 (개발)**: 4/6 오전 중 코어 로직 수정 완료.
- **Step 2 (안정화)**: 4/7 새벽 05:00 첫 성공 알림 확인.

---

> [!NOTE]
> 본 문서는 `ROADMAP.md`에서 참조되는 Phase 1.5의 핵심 보완 기술 문서입니다.
