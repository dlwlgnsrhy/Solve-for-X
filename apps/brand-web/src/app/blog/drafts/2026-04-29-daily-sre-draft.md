---
title: "Decoupling AI Endpoints: An SRE-First Approach to Autonomous Automation Pipelines"
phase: "Phase 1.5"
date: "2026-04-29"
tags: ["sre", "architecture", "automation"]
published: false
---

# Decoupling AI Endpoints: An SRE-First Approach to Autonomous Automation Pipelines

### Problem: The Hidden Cost of Hardcoded AI Dependencies
As autonomous automation pipelines scale, relying on hardcoded model references and ad-hoc routing strategies introduces severe operational friction. In our daily SRE and planning bots, coupling business logic directly to specific LLM endpoints caused configuration drift, opaque failure modes, and inconsistent latency. When external GPU clusters scale or model versions rotate, manual updates across `llm_client`, `daily_planner`, and `daily_sre_bot` became a reliability liability. Without explicit fallback paths or centralized observability, pipeline failures silently degraded into silent data gaps, violating our core SLO for continuous knowledge synthesis.

### Approach: Decoupled Routing & Observability-First Architecture
The engineering decision was clear: abstract AI service consumption behind a unified routing interface. We implemented a dual-tier LLM strategy—local inference (LM Studio) for low-latency filtering and external A100 clusters for high-quality synthesis. Crucially, we enforced configuration decoupling via `.env.shared`, ensuring model versions are treated as immutable infrastructure parameters rather than application constants. To satisfy SRE reliability standards, every external call now requires explicit health checks, structured logging, and immediate Telegram alerting on failure. This shifts the system from "best-effort automation" to "measurable, recoverable pipelines" with clear error boundaries.

### Implementation: Centralized Abstraction & Edge Expansion
The core refactor centered on `scripts/automations/_shared/llm_client.py`. We replaced hardcoded model strings with environment-driven routing, enabling seamless swaps between `Qwen3.6-27B` and `Qwen3.6-35B-A3B-FP8` without touching business logic. Fallback mechanisms were integrated into `daily_planner` and `weekly_planner`, automatically degrading to local inference when external endpoints timeout or return non-200 status codes. Alert payloads were standardized across `daily_news_curator` and `daily_sre_bot` to ensure consistent incident triage and reduce MTTR. Concurrently, we scaffolded `apps/sfx_imjong_care` using Flutter’s Clean Architecture and Riverpod, establishing a standardized edge client pattern that will eventually consume these centralized automation APIs via secure internal endpoints.

### Outcome: SRE Value & Systemic Resilience
This architectural shift delivers immediate SRE value. Configuration drift is eliminated, reducing deployment risk to near-zero for model rotations. Explicit fallback paths guarantee pipeline continuity during external GPU saturation, directly supporting our 99.9% availability target for the autonomous infrastructure. Structured alerting transforms silent failures into actionable incidents, while the unified routing interface future-proofs the system for multi-model orchestration and cost-aware routing. By treating AI endpoints as managed infrastructure rather than application dependencies, we’ve built a repeatable, observable foundation for scaling the "unmanned factory" paradigm, ensuring reliability scales linearly with complexity.

---
> **Phase Mapping:** Phase 1.5: 브랜드 사이트 동적 연동 및 SRE 자동화 (LLM 라우팅 고도화)
Phase 2: Legacy_Core 엔진 및 중앙 허브 서버 구축
Phase 3: Client Edge Applications (Flutter 앱 확장)
Phase 4: Branding & SRE Audit (안정성 검증)
Phase 5: Global Target Attacking (포트폴리오 제출)