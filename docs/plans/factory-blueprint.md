# Level 3 Orchestration Blueprint (sx-factory)

## Overview
The Software Factory (sx-factory) operates on a three-tier hierarchical orchestration model designed for autonomous, modular production of high-quality software artifacts.

## Architecture Layers
1. **Orchestrator (Hermes Agent)**: The Brain. Receives high-level goals, decomposes them into executable tasks (Kanban), manages sub-agents, and oversees the production pipeline.
2. **Worker Sub-agents (Claude Code / OpenCode / Developer Agents)**: The Hands. Execute specific coding, testing, and deployment tasks within isolated environments/workdirs.
3. **Tooling Layer (MCP / Terminal / Browser)**: The Interface. Provides the necessary capability to interact with the OS, Web, and APIs.

## Production Workflow (The Pipeline)
1. **Requirement Intake**: User provides a goal $	o$ Orchestrator creates `plans/task-id.md`.
2. **Task Decomposition**: Orchestrator breaks plan into granular `todo` items in the Kanban board.
3. **Sub-agent Spawning**: For complex tasks, an orchestrator spawns a 'Worker' (e.s., Claude Code) with specific context and toolsets.
4. **Execution & Iteration**: Worker executes $	o$ produces artifacts $	o$ reports results via `whisper`.
5. **Verification & Integration**: Orchestrator validates output against the blueprint $	o$ merges into the main project.

## Standardized Artifacts
- **Plan (`plans/*.md`)**: Defines WHAT to do.
- **Spec (`specs/*.json`)**: Defines HOW it must look (schema).
    - `production_report`: The trace of what was done.
    - `module_spec`: Definition of a pluggable component.
- **Template (`templates/`)**: Boilerplate for new modules/apps.

