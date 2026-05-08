# [Engineering Series] Chapter 3. Eradicating AI Zombie Processes on My Mac
**Subtitle: Achieving a True "Clean Exit" with Session IDs and Process Lifecycle Management**

As mentioned at the end of Chapter 2, separating the Orchestrator (Hermes) and the Worker (OpenAgent) gave me logical control, and I thought all my problems were solved. However, the next morning, the roaring fan of my Mac and the 99% RAM consumption taught me a cold lesson about operating system realities.

Hermes had successfully detected an infinite error loop and terminated OpenAgent's main script. So why wasn't the memory freed up?

### The Fragments of AI Becoming Orphans

To understand the problem, you have to understand the process tree structure in POSIX environments (like Linux and macOS).

When OpenAgent runs terminal commands to test code (e.g., `npm run dev` or `flutter test`), multiple child subprocesses are spawned beneath the main Python script. 

If Hermes declares a timeout and simply kills the OpenAgent main script using a `kill` command, the main process dies. But the child processes that were already running—like the Webpack build server or Dart analyzer—do not automatically terminate. Instead, they become **Orphan Processes**. They are adopted by the root system process (`launchd` on macOS) and continue to run in the background forever, consuming RAM and CPU without any controlling terminal.

I called these "AI Zombie Processes." Every time an automation loop failed, a new batch of zombies piled up on my Mac.

### The Failed Approach: Hunting by Name (grep & pkill)

My first attempt at fixing this was brute force. I configured Hermes to run commands like `pkill -f node` or `pkill -f dart` right after killing OpenAgent.

The result was disastrous. It didn't just kill the servers spawned by the agent; **it ruthlessly murdered all my legitimate development servers for other projects I was actively working on.** Because my Mac was a multi-project environment (Imjong Care, Legacy Vault, etc.), killing processes by name was like walking through a minefield.

I needed a surgical way to target and eradicate only the processes spawned by the specific agent task.

### The Solution: Process Group IDs (PGID) and Sessions

Digging deep into the core mechanics of the operating system, I found the answer: **Session IDs and Process Groups**.

I modified the architecture so that when Hermes launches OpenAgent, it doesn't just run it as a standard subprocess. Instead, it calls `os.setsid()` (in Python) to assign the worker a **completely new process session**.

By doing this, OpenAgent and every single child process it spawns (Node, Dart, Python, etc.) share the exact same Process Group ID (PGID). It encapsulates the entire workload inside a logical bubble.

Now, when Hermes needs to abort OpenAgent, it doesn't bother looking for individual PIDs. Instead, it sends a termination signal to the entire process group:
`os.killpg(pgid, signal.SIGTERM)`

This single line of code was magic. Not only the main script, but every deeply nested headless browser or rogue daemon belonging to that session was perfectly annihilated in one swift stroke.

### A True Clean Exit

On top of wiping out the process group, I added cleanup hooks to delete temporary build files and release locked databases.

Now, my automation workflow operates like this:
1. OpenAgent gets stuck in an infinite loop.
2. Hermes detects the timeout.
3. Hermes sends a SIGTERM to the entire Process Group (PGID), instantly eradicating OpenAgent and all its zombie offspring.
4. Leftover temporary files in the workspace are purged.
5. Only after confirming this pristine state (a Clean Exit) does Hermes send a Telegram alert: "Task safely aborted."

My Mac now maintains optimal performance and zero memory leaks, even after running autonomous tasks for days on end. I was finally free from the horror of zombie processes.

However, once I secured system-level stability, I was immediately hit by a **network-level disaster**. The very channel I used to monitor the system—the Telegram API—started timing out, causing the entire Orchestrator to freeze in a Deadlock.

How I conquered asynchronous network failures and Telegram deadlocks will be covered in Chapter 4.
