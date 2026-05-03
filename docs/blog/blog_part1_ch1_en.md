# [Engineering Series] Chapter 1. The Hidden Trap of "Just Code It For Me"
**Subtitle: The Disasters an Autonomous AI Agent Caused on My Mac**

"Here’s the app spec. Use Clean Architecture, write the code, and build it for me. I'm going to sleep, so just notify me on Telegram when it's deployed."

Over the past year or two, with the explosive growth of Large Language Models (LLMs) and the Autonomous Agent ecosystem, many developers have entertained this sweet, almost intoxicating fantasy. I was no exception. I had embarked on a massive personal endeavor: the "Solve-for-X" (SFX) project. My goal was to solo-develop a suite of three life-cycle applications—Imjong Care, Memento Mori, and Legacy Vault—all encompassing a profound philosophy: 'Living Well = Dying Well'. 

Building three production-ready apps alone is a daunting task. Naturally, I looked to AI for salvation. My goal was clear: to assemble a 'fully autonomous, hands-off development team.' I set up a powerful local LLM (`Qwen3.6-35B-A3B-FP8`) running through a local proxy on port `30008`. I wrote scripts to give the AI agent terminal access, file system permissions, and the ability to execute code. The dream was an AI developer that relentlessly writes code, fixes bugs, and runs CI/CD pipelines locally on my Mac while I focus on the high-level architecture and philosophy.

However, the reality I faced when I eagerly launched my Python agent scripts was far from elegant automation; it was pure, unadulterated chaos.

---

### 🚨 Disaster 1. The Swamp of Infinite Loops

The fundamental premise of an autonomous agent is self-correction. You grant it the authority to execute terminal commands, read error logs, and modify code on its own. The problem arises when the AI occasionally hallucinates, loses its context window, or misunderstands a complex framework's error message.

I remember asking the agent to scaffold a new feature using Flutter and Riverpod. 
*   The agent attempted to install a package with a slightly incorrect name, or perhaps one that conflicted with my current Dart SDK. (`flutter pub add hallucinated_riverpod_plugin`)
*   Naturally, the terminal threw a dependency error.
*   The agent read the error log, assumed "Ah, I must need to clear the cache," and ran `flutter clean`. Then it tried installing it again.
*   It failed again. This time it decided to manually edit the `pubspec.yaml`, introducing a syntax error.
*   The next command threw a YAML parsing error. The agent then tried to fix the YAML error but forgot the original dependency issue.

Because there was no hard limit on its iterations, this cycle of "Execute -> Fail -> Hallucinate a fix -> Execute" repeated hundreds of times in the background. When I turned my monitor back on the next morning, the terminal was scrolling endlessly. The context window had maxed out, and my LLM proxy API was crying under the weight of thousands of redundant, useless token requests. The agent wasn't coding; it was trapped in a digital purgatory of its own making.

### 🧟 Disaster 2. AI Zombie Processes Devouring Memory

In order to write and test code autonomously, the agent inevitably has to spin up development servers, background scripts, or database instances. But what happens if a test script hangs, or if the agent process itself crashes due to an unhandled exception?

In a naive implementation, the main Python agent process dies, **but the child subprocesses it spawned (Node servers, Python daemons, Flutter run instances) become orphaned.** They detach and remain running silently in the background of macOS.

I learned this the hard way. I had let my 'Daily Planner' and 'Code Scaffolding' automations run via `launchd` on my Mac. A few days later, I noticed my MacBook Pro's fan screaming like an airplane taking off, and the chassis was burning hot. I opened the Activity Monitor and was horrified. 

Dozens of mysterious `node`, `python3`, and `dart` daemons were devouring 99% of my Mac's RAM and CPU. The agent had repeatedly crashed and restarted over the weekend, leaving behind a graveyard of active, headless processes. I spent an hour manually running `ps aux | grep node` and issuing `kill -9` commands. I started calling these "AI Zombie Processes."

### 🕳️ Disaster 3. The Out-of-Control Black Box and Telegram Deadlocks

To regain control and prevent my Mac from melting, I built a 'Feedback Bridge' using the Telegram API (`telegram_commander`). The idea was simple and elegant: the agent would run in the background, but if it encountered a bug or needed to make a critical architectural decision, it would send me a message on Telegram. It would then pause and wait for my approval before proceeding.

But the asynchronous network environment turned out to be another layer of hell.

*   The agent encounters an issue and tries to send a Telegram message containing a very long error log.
*   The Telegram API rejects the message because it exceeds the character limit, or a brief network blip causes a timeout.
*   Because my networking code lacked robust try-catch blocks and retry mechanisms, the HTTP request simply hung.
*   The agent, waiting synchronously for the network request to resolve, falls into an infinite waiting state (Deadlock).

Meanwhile, I am sitting at a cafe, checking my phone. Receiving no messages on Telegram, I mistakenly assume, "Wow, the agent is so smart, it's compiling everything perfectly without needing my help!" 

In reality, the entire orchestration pipeline had frozen at line 42 of a script, staring blankly into an uncontrollable black box state. Nothing was being built.

---

### 💡 Conclusion: AI Doesn't Just Need 'Intelligence', It Needs a 'Leash' (SRE)

After `kill -9`-ing countless zombie processes, writing shell scripts to clean up orphaned ports, and rewriting my Telegram API wrappers to handle timeouts, I came to a painful but vital realization.

> "The true technical challenge in building a fully autonomous development system isn't 'how smart your LLM is.' It's building the **Site Reliability Engineering (SRE) infrastructure** to control a runaway AI, recover gracefully from failures, and cleanly manage process lifecycles."

A simple prompt saying "take care of it" was nowhere near enough to build a production-level pipeline. I realized I needed robust orchestration. I needed:
1. **Process Lifecycle Management**: A way to assign Session IDs to agent tasks so I could instantly terminate an entire tree of processes if something went wrong.
2. **Network Resilience**: Exponential backoffs and retries for Telegram messaging.
3. **Turn Limits**: Hard caps on how many times an agent can loop before forcing a "Clean Exit" and reporting failure.

Therefore, instead of relying on a single, massive, intelligent-but-uncontrollable Python script, I decided to strictly separate the architecture. I created the **'Brain'** (to control state, timeouts, and orchestration) and the **'Hands and Feet'** (to execute constrained coding tasks).

This pivotal realization birthed the **Hermes (Orchestrator)** and **OpenAgent (Worker)** architecture—the robust system that finally tamed the AI and brought peace to my Mac. *(To be continued in Chapter 2...)*
