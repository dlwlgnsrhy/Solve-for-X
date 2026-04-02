# Phase 2 Legacy_Core 셋업 및 SRE 연동 로그

**작성일**: 2026-04-03
**관련 로드맵**: [01-macro-blueprint.md](./01-macro-blueprint.md)
**주요 목표**: Phase 2 (Legacy_Core 인프라 설계) 돌입 및 Phase 1.5 (SRE 대시보드) UI 완전 통합

## 1. 아키텍처 개요
Legacy_Core는 모든 데이터 주권을 보존하기 위한 중앙 통제 Java/Spring Boot 애플리케이션입니다. 초기 셋업 단계에서 프론트엔드 모니터보드(Next.js)와 백엔드 심장부(Legacy_Core)를 다이렉트로 연결하여 99.9% SRE 철학의 기반을 세웠습니다.

## 2. 작업 상세 내용
### 2.1 Spring Boot 3 + Java 21 기반 애플리케이션 초기화
- `apps/legacy-core` 하위에 Spring Initializr를 통해 Gradle (Kotlin DSL) 기반의 뼈대 구성.
- `web`, `data-jpa`, `postgresql`, `actuator` 등 엔터프라이즈급 아키텍처 의존성 추가 완료.
- **Docker/DB 의존성 제거 전략**: 로컬 네트워크에서 즉시 실행 및 테스트가 가능하도록 `build.gradle.kts`와 `application.yml`을 H2 인메모리(in-memory) 데이터베이스로 임시 스위칭하여 데몬 없이 즉각 구동 가능하도록 대응. 

### 2.2 SRE Health Proxy 로직
- Spring Actuator의 무거운 데이터를 그대로 보내지 않고, `HealthController.java` (`/api/v1/health`) 를 통해 커스텀 상태 JSON (`{status: "UP"}`)만 송출.
- Next.js의 `page.tsx`가 주기적으로(10초) 폴링하며 서버 상태 뱃지를 `🔴 Offline` / `🟢 Live`로 동적 치환.
- API Route Proxy (`/api/sre/health/route.ts`) 기술을 사용하여 브라우저 CORS 제약 우회 및 로컬 HMR 네트워크 접근(`allowedDevOrigins`) 개통.

## 3. Next Steps (진행 예정)
1. **Spring Data JPA & DDL 설계**: PostgreSQL(또는 H2) 테이블 연동을 위한 자산(Asset)과 기록(Memory)의 마스터 엔티티 구조(`@Entity`) 설계.
2. **Spring Security & JWT 설계**: 외부의 허가받지 않은 접근을 엄격히 차단할 엔터프라이즈급 API 보안 규칙 정의.
