# Phase 2.2 REST API 기반 데이터 조작 및 JWT 인증 로직 구축

**작성일**: 2026-04-03
**관련 로드맵**: [01-macro-blueprint.md](./01-macro-blueprint.md)
**주요 목표**: JWT 로그인 파이프라인 생성 및 생애 서사(LifeLog) MVP 파이프라인(CRUD) 개통.

## 1. 1인 최고 권한 방어선 설계 (No-Signup)
- 시스템의 철학인 "데이터 주권"을 달성하기 위해, 외부로부터의 가입(Sign-up) API 구멍 자체를 만들지 않았습니다.
- Flyway `V2__seed_master.sql`을 통하여 오직 시스템이 초기 구동될 때 DB 스크립트 상으로 단 1개의 무적 권한(`ROLE_ARCHITECT`) 계정을 삽입(`jihoon@soluni.com`)합니다. 이것이 유일한 시스템 통제자입니다.

## 2. JWT (Access Token) 코어 유틸리티
- `/api/v1/auth/login` 엔드포인트를 개통하여 인증에 성공하면 JWT가 발급되도록 하였습니다. (`AuthService`, `AuthController`)
- 이렇게 발급된 토큰을 Bearer Header로 보내면, `JwtAuthenticationFilter`에서 가로채서 서명을 검증하고 시큐리티 컨텍스트에 멤버 계정 정보를 부여합니다. SRE Health 엔드포인트를 제외한 모든 API는 이 필터벽을 통과해야 합니다.

## 3. 도메인 비즈니스 (LifeLog)
- `LifeLogRequest` DTO로 감정 점수 등을 입력 받습니다.
- `LifeLogController`를 통해:
  - `POST /api/v1/lifelogs`: 본인의 1인 계정 ID로 새로운 서사와 감정 상태를 DB에 영속화.
  - `GET /api/v1/lifelogs`: 내가 쓴 서사의 전체 리스트업을 시간 역순으로 로드.

## Next Steps (Phase 3으로의 도약)
이것으로 `Legacy_Core`는 외부의 Flutter 앱이나 시스템 봇들과 대화하고 통제할 가장 탄탄한 준비를 마쳤습니다. 다음은 실제 자산을 관제하는 **Finance Entity 및 비즈니스 로직(Phase 2 마무리)**, 혹은 곧바로 **Flutter 모바일 애플리케이션 프론트엔드 연동 (Phase 3)**으로 넘어갈 수 있습니다.
