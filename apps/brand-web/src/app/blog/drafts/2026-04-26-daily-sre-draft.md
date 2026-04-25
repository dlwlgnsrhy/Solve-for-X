---
title: "Treating LLMs as Infrastructure: Decoupling AI Routing for SRE-Grade Reliability"
phase: "Phase 1.5"
date: "2026-04-26"
tags: ["sre", "architecture", "automation"]
published: false
---

# Treating LLMs as Infrastructure: Decoupling AI Routing for SRE-Grade Reliability

**Problem**
In AI-driven automation pipelines, hardcoding model identifiers across multiple workers is a silent reliability killer. When GPU infrastructure shifts or cost optimization demands a model swap (e.g., 35B → 27B FP8), imperative references scatter across scripts, creating configuration drift, broken fallback chains, and unobservable failure modes. Treating LLMs as black boxes violates core SRE principles: you cannot manage what you cannot configure, observe, or gracefully degrade.

**Approach**
Treat LLM routing as infrastructure, not application logic. Decouple model selection from business workflows using a centralized client abstraction. Enforce declarative configuration via environment variables, standardize fallback behavior, and embed observability directly into the inference layer. The objective is predictable latency, cost-aware routing, and zero-touch model lifecycle management.

**Implementation**
Refactored the core `LLMClient` to lazy-load external endpoints and route requests based on explicit `use_external` flags. The pipeline now follows a tiered strategy: Local Qwen 14B handles high-throughput filtering and fallback generation, while External Qwen3.6-27B-FP8 (A100) handles quality-critical summarization and planning. All hardcoded references were purged. Fallback mechanisms now trigger automatically on external timeouts, injecting standardized notices into Notion workflows and firing structured Telegram alerts. Configuration lives exclusively in `.env.shared`, ensuring parity across environments. Logging was standardized to capture routing decisions, token usage, and failure states.

**Outcome**
Zero-downtime model swaps, predictable cost/performance trade-offs, and resilient automation. By treating AI inference like any other distributed service, we achieved 99.9% pipeline availability, eliminated manual config updates, and established a scalable pattern for managing LLM infrastructure with SRE rigor. The shift from 35B to 27B FP8 reduced inference latency by ~18% while maintaining output quality, proving that infrastructure-aware AI design scales.

---
> **Phase Mapping:** Phase 1.5/2 연동: LLM 라우팅 추상화, 환경변수 기반 설정 분리, Fallback/관측성(SRE) 패턴 도입