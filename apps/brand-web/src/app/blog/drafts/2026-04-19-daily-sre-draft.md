---
title: "Deterministic AI Workflows: Building a Fault-Tolerant Autonomous Pipeline"
phase: "Phase 2"
date: "2026-04-19"
tags: ["sre", "architecture", "automation"]
published: false
---

# Deterministic AI Workflows: Building a Fault-Tolerant Autonomous Pipeline

# Problem

AI-assisted code generation has matured, but autonomous software delivery remains fundamentally fragile. When large language models generate multi-file applications, they routinely exceed context windows, hallucinate import paths, or leave dependency injection incomplete. The result is a cascade of manual fixes that negates the promised efficiency. For a solo engineer or small team, the bottleneck is no longer writing code; it is orchestrating a reliable, self-correcting delivery pipeline that survives token limits, state drift, and environmental variance. Traditional CI/CD solves deployment, but it does not solve the generation-to-verification gap. We need a system that treats AI not as a chat interface, but as a distributed build node with strict boundaries, observable state, and deterministic guardrails.

# Approach

The solution requires decoupling design, generation, verification, and feedback into discrete execution phases. I architected a six-wave autonomous pipeline that enforces strict boundaries between each stage. The core philosophy is deterministic guardrails over probabilistic generation. By isolating each wave into separate execution contexts, we prevent context window exhaustion from corrupting the build state. We also replace textual AI reports with physical verification: file system checks, static analysis passes, and live tunneling for real-device interaction. This shifts the engineering burden from hoping the model gets it right to systematically proving it did.

The architecture prioritizes observability and fault tolerance. Each wave produces a verifiable artifact. If Wave 1 (generation) leaves unresolved compilation errors, Wave 2 (QA) resets the context, ingests the artifacts, and patches them without carrying over hallucinated state. Wave 4 and 5 introduce automated visual verification and live preview generation using Cloudflare Tunnels, allowing remote testing without exposing local ports. Wave 6 is a feedback daemon that listens for human intervention, triggers targeted refactors, and rebuilds automatically. This mirrors production SRE practices: isolate failure domains, enforce contract verification, and maintain a clear feedback loop.

# Implementation

The pipeline operates in six distinct waves. Wave 1 handles architecture and overnight generation. Wave 2 is a dedicated QA session that resets the context window, runs static analysis, and patches compilation errors. Waves 4 and 5 introduce automated visual verification and live preview generation. Wave 6 is a background daemon that monitors external inputs, isolates affected modules, and triggers incremental rebuilds.

The critical innovation is context isolation. Instead of forcing a single agent to span eight to ten files across a 256K window, we split execution into discrete sessions. Each session receives a minimal, deterministic prompt with explicit guardrails. The system never trusts textual confirmation; it verifies via CLI exit codes and file system state.

```python

---
> **Phase Mapping:** Phase 2 (Data Foundation & Automation)의 핵심인 'AI 기반 자율 개발 파이프라인' 구축 완료. Phase 3의 모듈화 앱 개발을 위한 재사용 가능한 인프라(Base Camp 확장)로 직결되는 마일스톤.