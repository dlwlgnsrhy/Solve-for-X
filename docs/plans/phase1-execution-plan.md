# Phase 1 Execution Plan: [sx-factory] Standardizing Design & Blueprint

## 1. Objective
Define the precise technical specifications and structural standards for the `sx-factory` orchestration model to ensure autonomous agents (Workers) can execute tasks without ambiguity.

## 2. Core Deliverables
- [ ] **Standardized Task Schema (JSON/Markdown)**: Definition of how a "Requirement" becomes a "Plan".
- [ ] **Production Report Schema (`whisper-01`)**: A standardized way for workers to report success/failure, metrics, and artifacts.
- [ ] **Module Specification Standard (`factory-03` integration)**: How a pluggable feature (e.g., Auth, Payment) is described so the `ModuleInjector` can process it.
- [ ] **Orchestration Protocol**: Rules for how Hermes Agent decomposes goals into Kanban items and spawns sub-agents.

## 3. Detailed Workstream

### Step 1: The "Input" Standard (Requirement -> Plan)
- Define mandatory fields in `plans/*.md`:
    - `id`, `goal`, `constraints`, `success_criteria`, `dependencies`.
- Create a template for `plan_v1.md`.

### Step 2: The "Process" Standard (Worker Execution)
- Define the `production_report` schema:
    - `timestamp`, `worker_id`, `task_id`, `status` (success/fail), `artifacts` (file paths), `logs_summary`.
- Establish the "3-cycle QA" requirement as a standard part of every report.

### Step 3: The "Output" Standard (Module Assembly)
- Define `module_spec.json`:
    - `name`, `version`, `dependencies` (pubspec), `assets` (pubspec), `source_files` (lib/...), `post_install_script`.

## 4. Success Criteria
- A Worker agent can read a `plan/*.md` and generate a `production_report` that follows the new schema perfectly.
- The `ModuleInjector` can ingest a `module_spec.json` and produce a valid, compilable Flutter project.
