# 📊 Solve-for-X 전체 프로젝트 종합 분석 리포트

**작성일**: 2026-04-17  
**분석 범위**: `apps/`, `docs/`, `scripts/automations/`  
**Git HEAD**: `034b861` (`feat(apps/life_log_v6): initialize v6 with anti-collapse entity skeleton`)

---

## 1. 전체 구조 조감도

```
Solve-for-X/
├── apps/                          # 9개 앱 프로젝트
│   ├── brand-web/                 # ✅ 운영 중 (Next.js, GitHub Pages 배포)
│   ├── legacy-core/               # 🟡 기반 구축 중 (Spring Boot)
│   ├── imjong_care_app/           # 🔴 코드 부패 (Flutter)
│   ├── career_vault_web/          # ⚪ 빈 껍데기 (README만 존재)
│   ├── life_log_v1_failed/        # 🔴 실패 아카이브
│   ├── life_log_v2_failed/        # 🔴 실패 아카이브 (반복 루프)
│   ├── life_log_v4/               # 🔴 실패 아카이브 (환각)
│   ├── life_log_v5_failed/        # 🔴 실패 아카이브 (문법 붕괴)
│   └── life_log_v6/               # 🟠 진행 중 (Antigravity 스켈레톤)
├── docs/
│   ├── adr/                       # 7개 아키텍처 결정 기록
│   ├── ts/                        # 8개 트러블슈팅 리포트
│   ├── prompts/                   # 6개 omo 프롬프트/가이드
│   ├── plans/                     # 1개 설계도
│   └── roadmap/                   # 5개 로드맵 문서
└── scripts/automations/           # 5개 자동화 파이프라인 (Python)
```

---

## 2. 앱별 상세 분석

### 2-1. ✅ brand-web (Next.js) — **운영 중, 건강**

| 항목 | 내용 |
|------|------|
| **기술** | Next.js, React, CSS Modules |
| **디스크** | 499MB (node_modules 포함) |
| **소스 파일** | 3개 (`page.tsx`, `layout.tsx`, `route.ts`) |
| **코드 라인** | ~292줄 (page.tsx) |
| **배포** | GitHub Pages |
| **상태** | SRE Health Check 실시간 폴링, 제품 생태계 소개, Medium 블로그 연동 |

> [!TIP]
> 가장 안정적인 프로젝트입니다. 마우스 추적 스포트라이트, 모달 기반 제품 상세 등 인터랙티브 UI가 잘 구축되어 있습니다.

---

### 2-2. 🟡 legacy-core (Spring Boot) — **기반 구축 중**

| 항목 | 내용 |
|------|------|
| **기술** | Java, Spring Boot, Spring Security, JPA |
| **디스크** | 64MB |
| **소스 파일** | 20개 Java 파일 |
| **구현된 기능** | Auth(JWT), Health Check, LifeLog CRUD, Member/Asset 도메인 |
| **상태** | Docker Compose 포함, 구조적으로 가장 성숙한 백엔드 |

> [!NOTE]
> 이 프로젝트는 모든 Flutter 앱의 **데이터 허브** 역할을 해야 합니다. Life-Log V6의 API 엔드포인트(`/api/health/daily-checkin`)도 이 서버를 바라봐야 합니다.

---

### 2-3. 🔴 imjong_care_app (Flutter) — **코드 부패, 컴파일 불가**

| 항목 | 내용 |
|------|------|
| **기술** | Flutter, Riverpod, Freezed |
| **디스크** | 60MB |
| **코드 라인** | 456줄 |
| **치명적 오류** | 4건 |

**발견된 문제점:**

1. **쉘 스크립트 오염**: `i_medical_directive_repository.dart` 파일의 내용이 **Dart 코드가 아닌 bash `cat << EOF` 스크립트**입니다. 자동화 스크립트에서 파일을 생성하다가 실패한 잔해입니다.
2. **Gemma 4-bit 문법 붕괴**: 같은 파일 내 `Future<<voidvoid>`, `Future<<UserUser?>` 등 **동일한 제네릭 중복 패턴**이 발견됩니다.
3. **import 경로 오류**: `main.dart`에서 `import 'lib/presentation/...'` (상대경로에 `lib/` 접두사를 붙이면 안 됨).
4. **패키지 혼용**: `provider` 패키지를 import하면서 `ConsumerWidget`(riverpod)을 사용 — 컴파일 오류.

> [!CAUTION]
> 이 앱은 **구제보다 V6 통합이 더 효율적**입니다. CarePlan, CareTask 등의 도메인 모델 설계(51줄)는 참고 자료로 보존할 가치가 있습니다.

---

### 2-4. ⚪ career_vault_web — **빈 프로젝트**

빈 `README.md`(0바이트)만 존재합니다. 기획 단계에서 디렉토리만 예약한 상태입니다.

---

### 2-5. Life-Log 시리즈 (V1 → V6) — **실패 기록 연대기**

| 버전 | 기간 | 코드 라인 | 핵심 실패 원인 | 상태 |
|------|------|-----------|----------------|------|
| **V1** | ~Apr 15 | 166줄 | 삼성헬스 API 연동 실패, 기획 변경 | 🔴 `_failed` |
| **V2** | ~Apr 15 | **458줄** (대부분 `}` 반복) | Gemma 4-bit **반복 루프 붕괴** — 닫는 괄호 `}` 가 **439번** 반복된 괴물 파일 | 🔴 `_failed` |
| **V4** | ~Apr 15 | 20줄 | V3의 환각에서 온 잔해, `Map<<StringString` 오타 | 🔴 보존 중 |
| **V5** | ~Apr 16 | 20줄 + 빈 테스트 | 같은 오타 + 구현체 없는 테스트(공수표 TDD) | 🔴 `_failed` |
| **V6** | ~Apr 17 | **188줄** | Antigravity가 직접 작성한 스켈레톤. 하지만 `planner_api_client.dart`에 **또다시** `Future<<boolbool>` 발견 | 🟠 진행 중 |

#### V2의 반복 루프 — 실물 증거

`apps/life_log_v2_failed/lib/domain/entities/checkin_data.dart`는 **458줄**인데, 실제 유효한 코드는 19줄뿐이고, **나머지 439줄이 전부 닫는 괄호 `}`의 무한 반복**입니다. 이것이 Gemma 4-bit의 토큰 출력 한계를 넘어섰을 때 일어나는 전형적인 "반복 루프 붕괴"의 실물 증거입니다.

#### V6의 잔존 문제

V6에서 Antigravity가 직접 작성한 `checkin_data.dart`와 `planner_repository.dart`는 **무결**합니다. 그러나 omo가 작성한 `planner_api_client.dart` 17번째 줄에 여전히 `Future<<boolbool>` 오류가 남아 있습니다.

---

## 3. 자동화 파이프라인 (scripts/automations/)

| 모듈 | 파일 | 역할 | 상태 |
|------|------|------|------|
| `_shared/` | `config.py`, `llm_client.py`, `notion_client.py`, `telegram_client.py`, `alert_manager.py` | 공통 인프라 | ✅ 정상 |
| `daily_planner/` | `main.py` | 매일 아침 AI 플래너 생성 | ✅ 운영 중 |
| `daily_news_curator/` | `main.py` | RSS 뉴스 큐레이션 | ✅ 운영 중 |
| `daily_sre_bot/` | `main.py` | SRE 모니터링 | ✅ 운영 중 |
| `weekly_planner/` | `main.py` | 주간 회고 플래너 | ✅ 운영 중 |
| `health_receiver/` | `main.py` + FastAPI venv | 삼성헬스 데이터 수신 | 🟡 셋업만 완료 |

> [!IMPORTANT]
> 자동화 스크립트는 이 프로젝트에서 **가장 안정적이고 실제 가치를 발휘하는 영역**입니다. Notion 연동, Telegram 알림, LLM Fallback(로컬→외부) 구조가 매우 잘 설계되어 있습니다.

---

## 4. 문서 체계

### 트러블슈팅 (docs/ts/) — 8건
| 번호 | 주제 | 교훈 |
|------|------|------|
| TS-0001 | LM Studio 컨텍스트 초과 | 로컬 모델 한계 인식 |
| TS-0002 | Next.js 배포 실패 | basePath/assetPrefix 설정 |
| TS-0003 | 자동화 복원력 | Notion 연동 안정화 |
| TS-0004 | Life-Log Gemma 디버깅 | 모델 디버깅 기법 |
| TS-0005 | V2 반복 루프 | 토큰 한계 → Step-by-Step |
| TS-0006 | V3 환각 | 도구 호출 누락 |
| TS-0007 | V4 중단 | 초기 오타 연쇄 반응 |
| TS-0008 | V5 문법 붕괴 | 공수표 TDD |

### ADR (docs/adr/) — 7건
Git 훅 설계, 로컬 모델 선택, 하이브리드 기술 스택, DB 인프라, Next.js 배포, 건강 데이터, Dual-Agent 워크플로 등 아키텍처 결정을 문서화.

---

## 5. 핵심 발견 사항 요약

### 🔴 Critical (즉시 조치)

1. **V6의 `planner_api_client.dart` 17번째 줄**: `Future<<boolbool>` — omo가 작성한 부분으로, 현재 V6에서 유일한 컴파일 에러입니다.
2. **`imjong_care_app`의 쉘 스크립트 오염**: `i_medical_directive_repository.dart`가 bash EOF 스크립트로 오염되어 있습니다.

### 🟡 Warning (정리 필요)

3. **디스크 낭비**: 실패한 Life-Log 버전들(V1, V2, V4, V5)이 합계 **~96MB**를 차지하고 있습니다. 특히 V1, V5는 flutter `build/` 디렉토리까지 포함.
4. **`career_vault_web`**: 빈 디렉토리. 기획 중이 아니라면 삭제 대상.

### ✅ Positive (잘 되고 있는 것)

5. **자동화 파이프라인**: Python 기반 5개 자동화가 매일 안정적으로 동작 중.
6. **brand-web**: GitHub Pages에 성공적으로 배포, SRE 실시간 모니터링 내장.
7. **legacy-core**: Spring Boot 기반 백엔드가 JWT Auth, JPA, Docker까지 갖춘 성숙한 구조.
8. **문서화 습관**: TS 8건, ADR 7건의 문서화가 꾸준히 이루어지고 있어 반면교사 자산이 훌륭.

---

## 6. 권장 조치 사항 (Action Items)

### 즉시 실행 (Today)
- [ ] V6 `planner_api_client.dart` 의 `Future<<boolbool>` 문법 오류 수정
- [ ] 실패 아카이브들(v1, v2, v4, v5) 정리 여부 결정 (삭제 or `.gitignore`)

### 단기 (This Week)
- [ ] V6 Phase 2 진행: Provider 및 UI 구현 (Antigravity 직접 작성 권장)
- [ ] `imjong_care_app` 처분 결정: V6에 Care 도메인 통합할지 vs 별도 유지할지

### 중기 (This Month)
- [ ] `legacy-core`(Spring Boot)를 V6 Flutter 앱의 실제 백엔드로 연결
- [ ] `career_vault_web` 기획 확정 또는 제거

---

## 7. Gemma 4-bit 오류 패턴 종합 (V1~V6에서 발견된 모든 패턴)

| 패턴 | 발생 빈도 | 예시 | 발생 조건 |
|------|-----------|------|-----------|
| **제네릭 중복** | V2, V4, V5, V6 (4회) | `Map<<StringString>`, `Future<<boolbool>` | Dart 제네릭 `< >` 처리 시 |
| **반복 루프 붕괴** | V2 (1회) | 닫는 괄호 `}` 439번 반복 | 토큰 출력 한계 도달 시 |
| **도구 호출 환각** | V3, V5 (2회) | 파일 미생성인데 "완료" 보고 | 다중 파일 동시 생성 지시 시 |
| **쉘 오염** | imjong_care (1회) | Java EOF 블록이 Dart 파일에 삽입 | bash 자동화 파이프 실패 시 |

> [!WARNING]
> **결론**: Gemma 31B 4-bit 모델은 **Dart 제네릭 구문에서 구조적으로 취약**합니다. 모든 `< >` 가 들어가는 타입 선언을 omo에게 직접 시키면 안 되며, Antigravity가 사전에 인터페이스를 하드코딩하고 omo는 비즈니스 로직(조건문, API 호출)만 채워넣는 분업이 필수적입니다.
