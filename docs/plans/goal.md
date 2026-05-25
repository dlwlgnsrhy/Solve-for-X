# 🏆 Solve-for-X (SFX): 1인 유니콘 기업을 위한 자율 소프트웨어 공장 5개년 로드맵 (goal.md)

> **"최소한의 인력으로 무한히 확장 가능한 서비스를 찍어낸다."**  
> Solve-for-X(SFX)는 인간 기획자(지훈님)의 비전 아래, 지능형 AI 에이전트 연합(Antigravity, Hermes, Claude Code)과 고도로 표준화된 DevOps 인프라를 융합하여 1인 유니콘 기업의 자생적 생태계를 구축하는 것을 목표로 합니다.

---

## 🏗️ 1. Multi-Phase Evolutionary Roadmap (5개년 발전 로드맵)

### Phase 1: Blueprint & Template Era (Year 1) - [달성 완료 및 실증 완수]
**목표: '검증된 설계도(Blueprints)'와 '공통 핵심 모듈'의 확보 및 표준화**
*   **Engineering Focus:**
    *   **Standardized Tech Stack:** `Flutter (Mobile)` + `Next.js/React (Web)` + `BaaS Supabase/PostgreSQL (Backend)`. 어떤 아이디어든 10분 내에 프로토타입 서빙이 가능한 보일러플레이트 완비.
    *   **Modular Architecture:** 인증(Auth), 비동기 오프라인 연동([sync_service.dart](file:///Users/apple/development/soluni/Solve-for-X/apps/sfx_memento_mori/lib/core/services/sync_service.dart)), 알림(Push/Telegram Notify), 결제 및 구독(Payment Hub)을 완전 독립 모듈로 구현하여 조립형 개발 체계 확보.
    *   **CI/CD Automation:** 커밋 및 푸시 한 번으로 빌드, 테스트, 배포 관문을 텔레그램 승인(/confirm)을 거쳐 자율 수행하는 파이프라인 수립.
*   **Business Focus:**
    *   **MVP Prototyping:** 아주 작고 뾰족한 문제(X)를 해결하는 초경량 서비스(`Memento Mori`, `Imjong Care` 등)를 초고속 출시하여 Product-Market Fit 확인.
    *   **Brand Identity:** SFX를 '문제를 기어코 해결해내는 고품질 소프트웨어 브랜드'로 브랜딩하기 위한 초기 품질 관리(QA) 체계 정초.

---

### Phase 2: The Factory Construction (Year 2 - 3) - [100% 구축 및 자율 가동 완료 - 2026.05.22]
**목표: 'Agentic Workflow'를 통한 소프트웨어 생산의 완전 자율화 (Automation of Production)**
*   **Engineering Focus:**
    *   **Agent-Driven Development (ADD):** 지훈님이 아이디어 설계도만 전달하면, AI 에이전트가 코드를 정적 주입(`ModuleInjector`)하고 컴파일 오류를 자율 트러블슈팅하여 최종 풀 리퀘스트를 생성하는 자율 개발 체제 구축.
    *   **Automated QA Engine:** Puppeteer 헤드리스 크롬과 OpenCV 기반의 픽셀 오차 분석 엔진([visual_regression_qa.py](file:///Users/apple/development/soluni/Solve-for-X/scripts/factory/store_asset_generator.py))을 통한 레이아웃 검증 및 다중 해상도 앱스토어 마케팅 에셋([store_asset_generator.py](file:///Users/apple/development/soluni/Solve-for-X/scripts/factory/store_asset_generator.py)) 자율 패키징 및 출하.
    *   **Interactive Orchestration:** 노션의 일일 체크박스를 추적하여 아침 브리핑을 전송하고, 텔레그램 명령어(`/antigravity`)를 통해 백그라운드 코딩 데몬을 깨워 실시간 물리 렌더링 캡처본과 함께 작업 완료 보고서를 디스패치하는 관제망 가동.
*   **Business Focus:**
    *   **Hyper-Velocity Launching:** 개별 마이크로 앱의 빌드 및 출시 주기를 '주 단위'로 단축하여 시장 반응 속도 극대화.
    *   **Unified Analytics Platform:** 출시된 모든 독립 플랫폼들의 로그 및 지표(Traffic, Retention, LTV)를 PostgreSQL/Supabase 통합 데이터베이스에 수집하여 데이터 중심의 의사결정 체계 확보.

---

### Phase 3: The Ecosystem Era (Year 4) - [차기 고도화 마일스톤]
**목표: '플랫폼 간 시너지'와 'SSO 통합 및 데이터 상호작용'을 통한 자생적 생태계 완성**
*   **Engineering Focus:**
    *   **Cross-Platform Identity (SSO):** 단일 계정(OAuth 2.0 / Supabase Auth 기반)으로 `Memento Mori`, `Imjong Care`, `Legacy Vault` 등 SFX 생태계 내 모든 하위 서비스(Sub-platforms)를 경계 없이 넘나드는 초경량 통합 유저 경험 설계.
    *   **Edge Data Cross-Pollination:** 플랫폼 간의 고유 사용자 데이터를 익명화 및 공유하는 에지 API 게이트웨이를 형성하여, A 앱의 사용자 프로필을 B 앱에서 지능형 개인화 추천 모델의 데이터셋으로 활용할 수 있게 연계.
    *   **Pluggable System Evolution:** 과거에 구축한 자율 공장(`sx-factory`)이 스스로 깃허브 이슈와 실시간 서버 헬스체크 로그를 모니터링하며 독립적인 패치 브랜치를 생성해 자동 배포하는 수준으로 업그레이드.
*   **Business Focus:**
    *   **Network Effect Trigger:** 마이크로 서비스 간의 상호 유입 링크 및 크로스 마케팅 구조를 자동화하여 마케팅 비용 제로(Zero-CAC)의 오가닉 트래픽 성장 실현.
    *   **Platformization (SaaS):** SFX 공장 아키텍처를 외부 기획자나 인디 개발자에게 API/SaaS 형태로 개방하여, 아이디어 템플릿만 넣으면 앱을 빌드 및 배포해 주는 'No-Code App-Factory SaaS' 비즈니스 모델로의 수평 확장.

---

### Phase 4: Autonomous Operations & Self-Evolution (Year 5+) - [1인 유니콘의 궁극적 비전]
**목표: 0인(Zero-Touch) 운영 체제와 AI 에이전트 군집의 자율 경영 및 자가 진화**
*   **Engineering Focus:**
    *   **Self-Healing & Auto-Patching (자가 장애 치유):** Sentry/Datadog 등의 APM에서 크리티컬 에러나 서버 레이턴시 폭증 감지 시, 관제 데몬이 에이전트를 자율 기동 -> 에러 로그 분석 -> 소스 코드의 취약점 자동 패치 -> GitHub Actions 배포 -> 무중단 롤백 검증을 5분 이내에 스스로 완수하는 자율 복구망 구현.
    *   **FinOps & Serverless Scaling Optimization:** 실시간 클라우드 리소스 소비량 및 트래픽 양을 실시간 추적하여, 사용되지 않는 서버리스 컴퓨팅 리소스는 즉시 슬립 처리하고 트래픽 폭증 시 Cloudflare 에지 네트워킹과 Supabase Edge Functions로 즉각 전역 스케일아웃을 전개하는 지능형 비용 관리 에이전트 이식.
*   **Business Focus:**
    *   **Algorithmic Growth Engine:** 구글 플레이스토어, 애플 앱스토어의 순위 및 키워드 트렌드를 실시간 스크래핑하여, 스토어 상위 노출에 최적화된 메타데이터(ASO)와 마케팅 목업 에셋을 에이전트가 스스로 재생산하고 정기 업데이트를 단행하는 AI 그로스해킹 엔진 가동.

---

## 🛠️ 2. 1인 유니콘 DevOps Standard Architecture (글로벌 표준 아키텍처)

1인의 노동력으로 수만 명의 동시 접속과 다중 플랫폼 인프라를 안정적으로 핸들링하기 위한 SFX DevOps 표준 가이드라인입니다.

```mermaid
graph TD
    A[Global Users] -->|DNS / Security / Edge Cache| B[Cloudflare CDN & WAF]
    B -->|Fast Delivery / SSR| C[Next.js Brand Dashboard - Vercel]
    B -->|BaaS / Live DB / Auth| D[Supabase Core Engine]
    D -->|Realtime Synced DB| E[(PostgreSQL Instance)]
    D -->|Serverless Business Logic| F[Supabase Edge Functions]
    G[GitHub Repository] -->|Autonomous CI/CD Pull| H[GitHub Actions Engine]
    H -->|Dockerized Push| I[DigitalOcean / VPS App Server]
    J[Telegram App - Jihun] <-->|Interactive Bot Command| K[Telegram Commander Orchestrator]
    K <-->|Task Queue Sync| E
    K -->|Headless Daemon Launch| L[Antigravity / Hermes Agent]
    L -->|Auto Fix & Capture| G
```

### Key Infrastructure Pillars:
1.  **Infrastructure as Code (IaC):** 모든 Supabase 스키마, Cloudflare 라우팅 설정, DigitalOcean 가상 머신 사양을 `Terraform` 코드로 형상 관리하여, 재난 상황 시 전 지역 멀티 클라우드로 인프라를 3분 내에 100% 복구 가능하게 설계.
2.  **Continuous Monitoring & SRE Alerting:** 모든 서버 레이턴시, DB 커넥션 풀 경보, 예외 스택 트레이스를 `Telegram Commander`의 알림 데몬(`worker_monitor`)에 직결하여, 지훈님의 텔레그램 채팅방으로 0.5초 내에 경보 디스패치 및 에이전트 대기 모드 활성화.
3.  **Edge Compute Dominance:** 무거운 Node.js 백엔드를 구축하는 대신, 경량 비즈니스 로직을 `Supabase Edge Functions (Deno 기반)`과 `Cloudflare Workers`로 100% 분산 처리하여 인프라 비용 최소화 및 글로벌 응답 속도 밀리초(ms) 단위 유지.

---

## 🛰️ 3. Special Addendum: MCP & Skills Configuration for sx-factory

AI 에이전트(Antigravity, Hermes, Claude Code)의 개발 속도와 파일 시스템/데이터베이스 접근 권한을 극대화하여 1인 유니콘 최적화 파트너로 세팅하기 위한 실제 설정 스펙 가이드입니다.

### 3.1. Claude Code / Antigravity Custom Skill 설정 (`SKILL.md`)
에이전트가 특정 작업을 자율적이고 표준화된 방식으로 완수하게 만들기 위한 프롬프트 프레임워크 스킬셋입니다.

*   **글로벌 스킬 저장소:** `~/.claude/skills/`
*   **프로젝트별 스킬 저장소:** `.claude/skills/`

#### 📝 [Example] `visual-regression-qa` Skill 템플릿
에이전트가 UI 코드를 수정한 뒤, 실측 픽셀 오차 분석과 캡처를 수행하고 텔레그램으로 자동 리포팅하도록 만드는 Custom Skill 정의서입니다.

```markdown
---
name: visual-regression-qa
description: UI/UX 레이아웃 수정 및 디자인 변경 시 물리적 런타임 렌더링 캡처본을 분석하고 visual 회귀 테스트를 통과시킨 후 결과를 리포트합니다.
allowed-tools: [View, Grep, Command]
---

# Visual Regression QA & Verification Protocol

당신이 UI나 디자인 서체를 변경했다면, 반드시 다음 순서에 따라 물리 검증 및 visual 캡처 보고 프로세스를 실행해야 합니다.

1. **빌드 안정성 검증**:
   - 먼저 수정된 애플리케이션의 타입 검사와 정적 분석 컴파일 빌드를 수행하십시오.
   - 명령: `npm run build` (Next.js) 또는 `flutter build web` (Flutter Memento Mori)

2. **물리 캡처 및 픽셀 오차 분석 구동**:
   - 캡처 스크립트를 백그라운드 헤드리스 브라우저 엔진으로 기동하십시오.
   - 명령: `python3 scripts/factory/store_asset_generator.py`
   - 생성된 스냅샷 파일들이 `docs/images/` 디렉토리에 정확히 내려앉았는지 파일 크기와 해상도를 실측하십시오.

3. **Telegram Bridge 리포팅 연동**:
   - 검증이 완료되면, Antigravity Bridge 모듈을 구동하여 지훈님께 스크린샷과 동적 마일스톤 리포트가 텔레그램으로 정상 송출되게 유도하십시오.
   - 명령: `python3 scripts/factory/support/antigravity_bridge.py "UI/UX 서체 버그 패치 및 Visual QA 통과"`

4. **결과 문서화**:
   - 수정된 상세 내용과 물리 캡처 이미지 경로를 [docs/plans/walkthrough.md](file:///Users/apple/development/soluni/Solve-for-X/docs/plans/walkthrough.md) 파일에 기록하여 형상 관리를 완료하십시오.
```

---

### 3.2. Model Context Protocol (MCP) 서버 최적화 구성
에이전트가 외부 데이터베이스, 파일 시스템, 깃허브 API 등과 다이렉트로 stdio/http 채널을 형성하여 복잡한 API 브릿지 스크립트를 거치지 않고도 자원을 자율 탐색 및 변형할 수 있는 MCP 최적화 설정입니다.

*   **글로벌 MCP 설정 파일:** `~/.claude/.mcp.json`
*   **프로젝트 로컬 MCP 설정 파일:** `.claude/.mcp.json` (또는 `.vscode/mcp.json`)

#### ⚙️ `.mcp.json` 1인 유니콘 최적화 Production Spec

```json
{
  "mcpServers": {
    "supabase-db-connector": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://postgres:your-supabase-db-password@db.supabase.co:5432/postgres"
      ],
      "env": {
        "NOTE": "Supabase PostgreSQL 인스턴스에 에이전트가 직접 쿼리하여 agent_jobs 상태 변경 및 사용자 메트릭을 실시간 실측하도록 허용"
      }
    },
    "github-agent-integration": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_secure_github_pat_token_here",
        "NOTE": "에이전트가 직접 Pull Request 작성, 이슈 분석, 브랜치 생성을 수행할 수 있는 권한 부여"
      }
    },
    "local-filesystem-sandbox": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/apple/development/soluni/Solve-for-X",
        "/Users/apple/Desktop/Moon_Whisper/Moon_Whisper"
      ],
      "env": {
        "NOTE": "에이전트가 샌드박싱 영역인 Solve-for-X와 Moon_Whisper 디렉토리 사이에서 소스코드 및 에셋 파일을 자유롭게 복사하고 이동시킬 수 있도록 허용"
      }
    }
  }
}
```

---

## 👁️ 4. Runtime QA & Verification Checklist (현재 프로세스 작동 자가 진단)

본 로드맵의 실현 가능성과 인프라의 투명성을 위해 현재 실 기동 중인 각 모듈에 대한 무결성 진단 기준을 정의합니다.

- [x] **Next.js Brand Dashboard (Port 3000):** Turbopack 정적 컴파일 무오류 및 CSS 반응형 Glassmorphism 스타일 가동 적격 여부.
- [x] **Flutter Memento Mori App (Port 8080):** SharedPreferences 오프라인 상태 저장과 4,160 격자 위젯 렌더링 무오류 적격 여부.
- [x] **Telegram Commander Daemon (Orchestrator):** Notion API 동기화 및 `/confirm` 백그라운드 비동기 기동 적격 여부.
- [x] **Antigravity SRE Bridge (Python Daemon):** `/antigravity` 명령 파싱 시 헤드리스 캡처본 텔레그램 Multipart/Form 동적 멀티미디어 수신 성공 적격 여부.