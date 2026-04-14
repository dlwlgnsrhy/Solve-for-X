---
title: "Scaling Developer Productivity: Implementing a Dual-Agent AI Pipeline for Complex System Orchestration"
phase: "Phase 2"
date: "2026-04-15"
tags: ["sre", "architecture", "automation"]
published: false
---

# Scaling Developer Productivity: Implementing a Dual-Agent AI Pipeline for Complex System Orchestration

In the pursuit of building a complex ecosystem of applications—ranging from bio-data trackers to financial dashboards—the primary bottleneck is rarely the syntax of the code. Instead, it is the cognitive load of managing the architectural scope while simultaneously handling the minutiae of implementation.

When leveraging Large Language Models (LLMs) for software engineering, many developers fall into the "single-prompt trap": asking a single model to act as the PM, Architect, and Coder all at once. At scale, this leads to context window saturation, hallucinations, and the dreaded "code loss," where the model forgets critical constraints from the beginning of the conversation.

To solve this, I implemented a **Dual-Agent Pipeline**, a structural separation of concerns applied to AI-driven development.

### The Problem: The Context Collapse
As my project, *Solve-for-X*, expanded into a multi-app ecosystem (Life-Log, Career Vault, Imjong Care), the architectural requirements became too dense for a single local LLM to manage reliably. I was using a local `Gemma-31B` model on an A100 GPU. While powerful, the model struggled when asked to "build a full Flutter app with Clean Architecture" in one go; it would either skip the data layer or hallucinate API endpoints.

I needed a way to maintain high-level architectural integrity (The "What" and "Why") without sacrificing the precision of the implementation (The "How").

### The Approach: Dual-Agent Orchestration
I decided to treat the AI development process as a distributed system. I split the workflow into two distinct roles with a "Human-in-the-Loop" proxy:

1.  **The Architect (Antigravity - High-Spec API Model):** This agent handles the macroscopic view. Its job is to analyze the product requirements, define the system boundaries, and decompose the project into "Atomic PRs"—the smallest possible units of implementable work.
2.  **The Coder (Gemma-31B - Local Model):** This agent handles the microscopic view. It receives a highly specific, constrained specification from the Architect and executes the code. It doesn't need to know the 5-year roadmap; it only needs to know how to implement a `HealthRepository` using the `health` package in Flutter.
3.  **The Proxy (Human):** I act as the routing layer, passing the Architect's specifications to the Coder and feeding the Coder's errors back to the Architect for refinement.

### Implementation: From Macro-Prompts to Atomic Execution
To operationalize this, I developed a **Macro-Prompt Catalog**. Instead of vague requests, I created structured templates that the Architect uses to generate "execution packets" for the Coder.

For example, when building the `SFX Life-Log` app, the Architect doesn't just say "make a health app." It generates a specification covering:
*   **Infrastructure:** Specific `pubspec.yaml` dependencies and `AndroidManifest.xml` permissions (e.g., `READ_SLEEP_SESSIONS`).
*   **Data Layer:** Exact class names (`HealthRepository`) and the specific HTTP endpoint for the backend (`/api/health/sleep`).
*   **Presentation Layer:** The exact state management pattern (Riverpod) and UI components required.

```dart
// Example of the precision required in the Coder's specification:
// The Architect specifies the exact inheritance needed for Health Connect:
class MainActivity: FlutterFragmentActivity { 
  // This specific change is critical for Health Connect popups, 
  // a detail often missed by single-agent prompts.
}
```

By constraining the Coder to a specific "Atomic Task," I eliminated hallucinations. The local model no longer had to "guess" the architecture; it simply had to execute a well-defined blueprint.

### Lessons Learned: The SRE Perspective on AI
This experiment taught me that the most effective way to use AI in professional software engineering is not to seek a "magic prompt," but to build a **pipeline**.

**1. Decomposition is the Only Way to Scale**
Just as we break a monolith into microservices to manage complexity, we must break AI prompts into a pipeline of specialized agents to manage cognitive load.

**2. The Value of Local LLMs in the Loop**
Using a local model (Gemma-31B) for the "Coder" role provides an immense cost advantage and data privacy, while the API-based "Architect" provides the necessary reasoning power. This hybrid approach optimizes both cost and quality.

**3. Human-in-the-Loop is a Feature, Not a Bug**
While "full automation" sounds appealing, the human proxy serves as the critical validation layer. By reviewing the Architect's plan before it reaches the Coder, I can catch logical flaws early, preventing the "hallucination loop" where the AI spends an hour fixing a bug it created itself.

By treating my development workflow as a system to be engineered, I've transformed the process of building apps from a creative struggle into a predictable manufacturing process.

---
> **Phase Mapping:** 이 작업은 Phase 2(Data Foundation & Automation)의 완료 단계이자 Phase 3(Finance & Memory Modules)로 진입하는 가교 역할을 합니다. 특히, 단순한 기능 구현을 넘어 'Dual-Agent'라는 SRE 관점의 오케스트레이션 전략을 도입하여 개발 생산성을 시스템화했다는 점에서 기술적 깊이가 강조됩니다.