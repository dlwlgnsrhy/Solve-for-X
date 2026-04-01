---
title: "[Phase 1 | Chapter 1: Brand Website Basecamp] Establishing the Next.js Corporate Identity"
phase: "Phase 1"
date: "2026-03-30"
tags: ["frontend", "architecture", "css"]
---

# [Phase 1 | Chapter 1: Brand Website Basecamp] Establishing the Next.js Corporate Identity

### Executive Summary

Before any macro-level automation or legacy backend engines can be integrated, a central hub is required to act as the face of the ecosystem. **Phase 1** marks the inception of the **soluni (Solve-for-X)** Brand Website—our foundational basecamp. The primary objective of this phase was to construct a highly performant, server-rendered frontend architecture using **Next.js**, while strictly adhering to design principles that emphasize absolute control, raw aesthetics, and premium corporate identity.

### System Architecture Overview

To maintain maximum control over the rendering pipeline and styling semantics, we bypassed utility-first frameworks like Tailwind CSS in favor of **Vanilla CSS Modules**. This architectural decision ensures our codebase remains un-polluted and infinitely customizable, laying down a robust foundation for intricate micro-animations and spatial design.

The Next.js framework was selected for its unparalleled flexibility in Static Site Generation (SSG) and Server-Side Rendering (SSR), seamlessly enabling the transition from a static profile to a dynamic, data-driven ecosystem in future phases.

### Aesthetic & UI Engineering

#### The Dynamic Spotlight Effect
A core requirement of Phase 1 was establishing an interface that feels alive. We implemented a dynamic spatial lighting technique using CSS `radial-gradient` mapped to global mouse coordinates. Through custom React Hooks tracking pointer movements, the website background reacts intelligently to the user, creating a premium "spotlight" depth-of-field effect that elevates the corporate aesthetic beyond standard flat designs.

#### Modular Showcase Layers
We engineered a custom Modal navigation overlay (`modal_overlay` with `backdrop-filter: blur`) to house the **Founder's Letter** and ecosystem product blueprints. This layered presentation keeps the user anchored to the main dashboard while allowing them to deep-dive into macroscopic visions seamlessly. 

### SRE Indicator Preparedness 

While the backend logic belongs to Phase 2, Phase 1 successfully established the mock UI boundaries for Site Reliability Engineering (SRE) metrics. Visual indicators for `[🟢 System Live]` and API health checks were structurally integrated into the footer. These components currently serve as placeholders, waiting to be dynamically hooked into the Java/Spring Boot core engine via live REST endpoints.

### Conclusion

Phase 1 successfully delivered the Soluni Brand Website—a visually stunning, structurally sound basecamp built on Next.js and pure CSS. By intentionally avoiding third-party styling constraints and embedding dynamic user-feedback animations, we have secured a pristine client-edge platform. This basecamp is now completely ready to host the real-time SRE metrics, automated tech blogs, and complex engineering pipelines slated for Phase 1.5 and beyond.

---

> *"Absolute control over the frontend architecture is the first step toward a sovereign ecosystem."*  
> — Architect Lee Ji-hoon

---
> **🤖 Copilot Reasoning:**
> (Retrospective Generation) 파이프라인 구축 전 진행되었던 Phase 1 (Next.js 웹사이트 뼈대 및 CSS 스포트라이트 구축)의 빈 공간을 메꾸기 위해 아키텍트의 과거 리뷰 데이터를 바탕으로 소급 작성된 공식 아카이브입니다.
