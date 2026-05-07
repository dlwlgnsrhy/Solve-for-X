# [Engineering Series] Chapter 2. Refactoring the Architecture: The Brain (Hermes) and the Hands (OpenAgent)
**Subtitle: Strictly Separating the Commander from the Coder**

As explored in Chapter 1, the monolithic approach of telling a single agent to "handle everything" resulted in a nightmare of infinite loops and zombie processes. When the agent got stuck on a trivial coding error or a missing dependency, the main process orchestrating the entire workflow would crash alongside it, taking the entire automation pipeline down.

I could no longer let my MacBook Pro suffer under the weight of runaway background scripts. I realized that achieving true "Prompt-Driven Development" required a fundamental restructuring of the architecture. I needed to move away from a fragile, monolithic "Agent" and build a robust, fault-tolerant "System."

The core principle behind this redesign was simple but profound: Strict Separation of Concerns.

---

### Separating the Brain from the Hands: Hermes and OpenAgent

Think of a traditional human development team. A Project Manager manages the schedule, handles client communication, and defines the scope. A Junior Developer writes the actual code and runs the tests. If the junior developer writes a syntax error and fails to compile the application, the PM does not suffer a heart attack. 

However, in my initial automation setup, both of these roles were tightly coupled within a single Python script. If the code generation logic failed, the Telegram communication loop died with it. 

To solve this, I cleanly divided the architecture into two distinct, isolated entities.

**1. The Orchestrator: Hermes (The Brain)**
Hermes acts as the overarching manager of the workflow. Crucially, Hermes does not write application code, nor does it directly execute build commands like `flutter run` or `npm run build`. Instead, it manages state, prioritizes tasks, handles timeout limits, and communicates with me via the Telegram API. 

Its most critical function is SRE (Site Reliability Engineering) supervision. Hermes watches the worker agent from an isolated process. If the worker causes an issue, gets stuck in a loop, or exceeds its allotted time, Hermes ruthlessly terminates the worker process to protect the host system.

**2. The Intelligent Worker: OpenAgent (The Hands)**
OpenAgent is a highly specialized worker designed strictly to generate code and scaffold architectures within a heavily controlled, sandboxed environment. It receives highly specific, constrained mission tickets from Hermes. For example: "Implement Riverpod state management for the home screen of the Imjong Care app based on the attached architecture document." 

OpenAgent's sole responsibility is to read the target files, write the necessary Dart or Python code, run local unit tests, and report a binary "Success" or "Failure" back to Hermes.

By isolating them, even if OpenAgent falls into a recursive loop trying to fix a YAML parsing error, Hermes remains perfectly healthy. It simply observes the failure, kills the OpenAgent subprocess, and pings me on Telegram with the error log.

### Unified Under a Single Giant Model: Qwen 35B

After separating the roles, I immediately faced a new bottleneck: the fragmentation of intelligence. 

Previously, to save on local VRAM and API costs, I used a lightweight model for the orchestrator and a heavier model for coding tasks. This created a severe disconnect. Hermes would issue high-level architectural instructions that the lower-level worker agent simply failed to comprehend, leading to hallucinated code and broken implementations.

I made the bold decision to unify the "brains" of all agents under a single, massive intelligence. The solution was the `Qwen3.6-35B-A3B-FP8` model.

By overhauling the system-wide `.env.shared` configurations and routing all LLM requests through a single local proxy endpoint on port `30008`, I integrated the architecture completely. Now, whether Hermes is planning a complex deployment pipeline or OpenAgent is writing a specific Flutter widget, they share the exact same powerful reasoning capabilities of the 35B parameter model. 

With one massive intelligence handling both the high-level instruction and the low-level execution, the pipeline flowed seamlessly without context loss. It felt as if a single, highly competent senior developer were thinking and moving across the entire codebase.

### The Autonomous System in Action

With this new architecture, when a bug occurs on my Mac, the workflow executes flawlessly:

1. Trigger: I casually send a Telegram message from my phone: "Fix the layout overflow bug on the Legacy Vault settings screen."
2. Planning (Hermes): Hermes receives the webhook, analyzes the request, plans which specific files need modification, and issues a structured task ticket to OpenAgent.
3. Execution (OpenAgent): OpenAgent spins up, reads the targeted Dart files, writes the layout fix, and runs local `flutter analyze`.
4. Supervision: What happens if OpenAgent misunderstands the Flutter constraints and fails the analysis three times in a row? Hermes, monitoring the iteration count from the outside, intervenes. It forces a "Clean Exit" on OpenAgent, shutting down its workspace, and sends me a Telegram message containing the failure logs, asking for my human intervention.

This was the pivotal moment the "out-of-control black box" finally evolved into a "predictable, hands-off development team."

I thought I had won. The first time Hermes successfully detected an infinite loop, printed "Process Terminated," and sent me a Telegram alert, I went to sleep feeling like an SRE genius. 

But the next morning, my Mac was completely unresponsive. The fan was roaring. 

I checked the Activity Monitor. Hermes had successfully killed the main Python script of OpenAgent, yes. But the child processes that OpenAgent had spawned—the Webpack development servers, the hanging Dart analyzers, the rogue Node.js instances—were completely decoupled from the main process. They had become orphans. Hermes had cut off the head, but the body was still thrashing in the background, silently eating away at my Mac's memory.

Logical termination was not enough; I needed an OS-level "Clean Exit."

To solve this, I had to dive into the dark arts of operating systems: process trees, POSIX signals, and Session IDs. In Chapter 3, I will show you exactly how we hunted down these unkillable "AI zombie processes" and brought absolute SRE stability to the local environment.
