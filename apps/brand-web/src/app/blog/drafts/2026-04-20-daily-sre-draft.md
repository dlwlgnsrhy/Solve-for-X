---
title: "Building Resilient Automation Pipelines: When Scripts Meet Production Reality"
phase: "Phase 1.5"
date: "2026-04-20"
tags: ["sre", "architecture", "automation"]
published: false
---

# Building Resilient Automation Pipelines: When Scripts Meet Production Reality

Autonomous systems inevitably collide with external constraints. When building an AI-driven automation pipeline for daily knowledge curation, documentation sync, and infrastructure monitoring, the initial prototype functioned in isolation but fractured under production conditions. Three critical failure modes emerged: the Notion API’s strict two-level nesting limit caused silent data loss and 400 errors; weekend data scarcity led to zero-hit filtering despite active LLM pipelines; and infrastructure fragility manifested as 502 Bad Gateway crashes and Telegram spam loops due to missing dependency checks and absent idempotency guards. These were not traditional bugs. They were architectural mismatches between prototype assumptions and production realities.

The solution required shifting from a script-centric mindset to a service-oriented architecture. Every automation daemon needed to treat external APIs as unreliable partners, enforce strict state boundaries, and adapt to environmental variance. Rather than patching symptoms, I restructured the pipeline around four SRE principles: defensive parsing, adaptive scheduling, lazy resource loading, and idempotent execution. The objective was not merely to make the system work, but to make it observable, resilient, and self-correcting.

The most complex challenge was reconciling Markdown’s arbitrary nesting depth with Notion’s hard limit of two child levels. A naive recursive parser would either crash or truncate content. I implemented a depth-aware flattening algorithm that tracks stack depth and explicitly blocks nesting beyond index 2. When the limit is reached, deeper elements are promoted to the current level’s sibling list. Crucially, the parser validates block types before pushing to the stack, rejecting non-nestable containers like `heading_1`, `quote`, or `callout` to prevent structural corruption.

```python
MAX_DEPTH = 3  # Root(0) -> Level 1 -> Level 2
if len(stack) >= MAX_DEPTH:
    parent_list = stack[-1][1]
    parent_list.append(block)
else:
    parent_block = stack[-1][2]
    if parent_block and parent_block["type"] not in ALLOWED_NEST_TYPES:
        root_blocks.append(block)
        stack = [(-1, root_blocks, None)]
    else:
        parent_list.append(block)
        children_list = block[block["type"]].setdefault("children", [])
        if children_list is not None:
            stack.append((indent, children_list, block))
```

For the news curation daemon, static 24-hour collection windows proved brittle during weekends when developer activity drops. I introduced adaptive scheduling that expands the collection window to 72 hours on Saturdays and Sundays. Combined with persona-driven system prompts for the local LLM (Qwen

---
> **Phase Mapping:** Phase 1.5 (SRE 자동화 및 동적 연동) → Phase 2 (데이터 기반/자동화 인프라) 전환기. Notion API 제약 처리, LLM 필터링 파이프라인 고도화, 데몬 안정성 강화가 자동화 레이어의 프로덕션 격상을 의미함.