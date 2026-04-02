# soluni & Solve-for-X (SFX) 거시적 아키텍처 확장 로드맵 (Macroscopic Blueprint)

현재 완벽하게 구축된 **Phase 1 (Brand Website Basecamp)**을 바탕으로, 향후 설계자님이 개발하실 모든 백엔드 자동화 및 앱 서비스(Flutter)들이 이 '본진(Basecamp)'과 어떻게 결합되어 거대한 유니버스를 이룰지 거시적 관점에서 정리한 가이드입니다. 

---

## 🧭 Macroscopic Expansion Guide

### 📍 Phase 1.5: 브랜드 사이트 '라이브' 동적 연동 (Next.js 고도화) 및 SRE 자동화
현재 하드코딩된 모달(Modal) 창의 텍스트와 UI, 그리고 `[🟢 System Live]` 배지들을 수동 타이핑이 아닌, 향후 백엔드 및 라이브 파이프라인과 API 로직으로 연결합니다.
1. **[✅ 구축 완료] Tech Blog 옴니채널(Omnichannel) 자동화 연계:** Git Commit 파싱 스크립트가 단순히 외부 블로그에 송출하는 데 그치지 않고, 로컬 AI(LM Studio)의 4단계 추론(Phase Analysis)을 거쳐 완벽한 영문 서사로 Next.js 웹사이트 방어막(`drafts/`) 및 Dev.to(Canonical SEO)로 동시 배포되는 시스템을 완성했습니다.
   👉 상세 아키텍처 및 코어 워크플로우는 `01-1-phase1.5-sre-automation-details.md` 하위 문서 참조.
2. **모달 리소스 치환:** 추후 Flutter 앱의 UX/UI 프론트엔드가 설계되면 스크린샷 에셋만 캡처하여 메인 페이지 모달의 `Image Placeholder` 부분에 넣어 완벽한 쇼케이스 카드를 완성합니다.

### 📍 Phase 2: 『Legacy_Core』 엔진 개발 (Java/Spring Boot)
모든 앱 데이터의 불변성을 유지할 중앙 허브 서버이자 권력의 핵심 설계 단계입니다.
1. **아키텍처:** 엔터프라이즈급 Spring Security와 세션/JWT를 활용하여 권한을 엄격히 통제합니다. 
2. **[✅ 구축 완료] 모니터링 연결성 (SRE):** 앞서 Brand 웹에 만들어둔 SRE 메트릭스 뱃지들을 단순히 장식이 아닌, 이 Spring Boot 백엔드의 `Health Check` API 핑(Ping)과 통신시켜 진짜 돌아가는 SRE 라이브보드로 격상시켰습니다. (Next.js API Route 기반 CORS 회피 / Polling 완료)
3. **로컬 AI 결속:** 텔레그램과 연동된 로컬 AI 머신 서버를 로컬 API로 결속하여, 텍스트/이미지를 외부 유출 없이 독자적으로 분석하는 파이프라인을 뚫습니다.

### 📍 Phase 3: Client Edge Applications (Flutter App)
실제 유저(혹은 설계자 스스로)가 모바일로 매일 컨트롤하게 될 엣지 스크린을 짓습니다.
1. **SFX Life-Log (멀티모달 아이덴티티 앱):** iOS/Android 양대 마켓에 퍼블리싱. 일기를 쓰거나 사진을 올리면, 엣지단 앱이 아닌 `Legacy_Core` 딥 서버로 데이터를 전송해 영구 암호화 보관합니다.
2. **SFX Finance (오토 대시보드):** 거래소 API(Upbit/Binance 등)와 백그라운드 코어가 연결된 무한매수 봇의 수익률, 자산 비중을 관제하는 Flutter 뷰어.

### 📍 엔드게임: "SRE / 글로벌 SWE 이력 증명"
이 거대한 시스템(Client - API Core - Native App - AI Machinery)이 거미줄처럼 모두 결합될 때 세상은 묻습니다. 
**"당신은 엔지니어로서 어떤 시스템을 다뤘습니까?"** 
이때 대답은 단 하나, **"Solve-for-X (SFX) 생태계 접속 링크 (베이스캠프)"** 하나를 전달하는 것으로 증명은 끝납니다. 이 웹사이트 자체가 이지훈 설계자님의 퍼포먼스 마스터피스가 됩니다.
