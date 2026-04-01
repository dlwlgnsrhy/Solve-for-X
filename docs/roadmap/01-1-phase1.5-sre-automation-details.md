# Phase 1.5: SRE Tech Blog 옴니채널 초자동화 (Omnichannel SRE Automation)
**상위 로드맵 참조:** `01-macro-blueprint.md`

## 1. 아키텍처 개요 (Architecture Overview)
본 문서는 일상의 커밋(Commit) 로그가 완벽한 형태의 글로벌 영문 기술 블로그와 링크드인(LinkedIn) 영업 브리핑으로 변환되어 멀티-플랫폼에 동시 전송되는 **"Phase-Driven 4단계 초자동화 파이프라인"**의 상세 스펙을 정의합니다.

- **Objective:** 코딩 이외의 '블로그 작성 및 퍼스널 브랜딩'에 소모되는 시간을 0으로 수렴하게 만들고, 남는 시간을 Legacy_Core 엔진 개발에 집중한다.
- **Trigger Condition:** macOS 백그라운드 매니저(`launchd`)를 통한 심야 자동 스케줄링(Catch-up Sleep 복구 기능 포함).

## 2. 파이프라인 4단계 추론 구조 (Chain of Thought Pipeline)
단순한 형태의 번역을 거부하고, AI가 스스로 로드맵과 작업물을 매핑하는 지능형 검사를 선행합니다.

1. **Phase Validation (사전 검증):**
   - 로컬 모델 서버(LM Studio Qwen3 30B)가 `01-macro-blueprint.md`와 오늘의 `Code Diff`를 대조하여, "오늘의 코드가 거시적 로드맵의 어느 Phase에 속하는가"를 먼저 추론합니다.
2. **Dynamic Headline (글로벌 타이틀 생성):**
   - 앞선 분석을 바탕으로, `[Phase 1.5 | Chapter 1: UI Polish]` 와 같은 직관적인 영문 블로그 타이틀을 동적으로 뽑아냅니다.
3. **Blog Generation (서사 기반 본문):**
   - 파편화된 로그 설명 수준을 넘어, 서사가 담긴 **전문적인 글로벌 비즈니스 영문(US English)** 블로그 마크다운을 산출합니다.
4. **LinkedIn Extraction (비즈니스 브리핑):**
   - 트렌디한 이모지를 포함한 3줄짜리 영문 링크드인 사본을 별도로 작성해 텔레그램으로 배달합니다.

## 3. Human-in-the-Loop 배포망 (안전장치)
초자동화가 낳을 수 있는 'AI 스팸 공장화'를 완벽히 억제하기 위한 2중 안전 장치(Failsafe)를 확보했습니다.

- **Dev.to (글로벌 확성기):** REST API를 통해 자동 발행하되, 무조건 **임시저장(Draft) 모드**로 전송하며 원본이 Brand Web임을 구글 검색엔진에 알리는 `Canonical URL`을 못 박습니다.
- **Brand Web (본진 데이터베이스):** Next.js의 바로 배포 폴더인 `posts/`가 아닌 격리된 `drafts/` 폴더로 파일을 커밋하고, YAML 메타데이터(Frontmatter) 상단에 봇이 분석한 `Phase` 태그를 주입합니다.
- **Telegram (관제탑 결재):** 텔레그램으로 완료 로그가 오면 인간 아키텍트가 최종적으로 글을 1분 읽고(Human Touch) 최종 폴더로 승인/이동시킵니다.

## 4. 향후 로드맵 교차 지점 (Next Steps)
현재의 파이썬 기반 로컬 타임크론 배치(Batch)는 성공적으로 안착했습니다. 훗날 **Phase 2 (Legacy_Core Spring Boot 적용기)**가 도래하면 이 파이썬 스크립트 로직들은 점진적으로 Spring Boot의 `@Scheduled` 배치(Batch) 서버 내장형 파이프라인으로 흡수되어 영구적 중앙 통제(CQRS 등 적용)를 받게 될 것입니다.
