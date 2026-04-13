---
title: "From Cron Jobs to Event-Driven Automation: Integrating Biometric Data into a Productivity Pipeline"
phase: "Phase 2"
date: "2026-04-14"
tags: ["sre", "architecture", "automation"]
published: false
---

# From Cron Jobs to Event-Driven Automation: Integrating Biometric Data into a Productivity Pipeline

Most productivity automation follows a predictable, linear pattern: a cron job triggers a script at 5:00 AM, which fetches data from an API and populates a dashboard. While functional, this approach is "blind." It assumes that every morning is the same, regardless of whether the user slept four hours or eight.

In a high-performance engineering environment, we don't rely on static schedules for critical systems; we rely on events. I decided to apply this same SRE principle to my personal productivity engine. I transitioned my daily planning system from a time-based trigger to an event-driven architecture triggered by real-world biometric data from my Samsung Health smart ring.

### The Problem: The Fallacy of the Static Schedule

My existing `daily_planner` operated on a hard-coded schedule (05:00). It used an LLM to generate a daily plan based on previous logs and a roadmap. However, it lacked a critical variable: **human condition**.

Planning a "Deep Work" intensive day when your sleep score is 40/100 is a recipe for burnout and failure. Conversely, under-scheduling on a day when you are fully recovered is a waste of peak cognitive capacity. To solve this, I needed a system that could:
1. Ingest real-time health metrics asynchronously.
2. Use these metrics as a trigger to initiate the planning process.
3. Dynamically adjust the "intensity" of the generated plan based on biometric scores.

### The Approach: Event-Driven Biometric Integration

The solution was to decouple the planning trigger from the system clock and attach it to a data event.

**The Architecture:**
1. **The Edge Trigger:** A mobile automation tool (MacroDroid) monitors Samsung Health notifications. When the sleep report is generated, it fires a webhook.
2. **The Ingestion Layer:** A FastAPI-based `health_receiver` acts as the webhook endpoint, parsing raw text into a structured `daily_health.json` schema.
3. **The Event Dispatcher:** Upon successful ingestion, the receiver asynchronously triggers the `daily_planner` via a subprocess, eliminating the need for a morning cron job.
4. **The Intelligence Layer:** The LLM prompt is modified to accept the sleep score, applying a conditional logic gate to determine the day's workload intensity.

### Implementation

The core of the transition lies in the `health_receiver` and the updated prompt logic in the `daily_planner`.

**1. The Webhook Receiver**
I implemented a lightweight FastAPI server to handle the incoming biometric payload. The critical part here is the use of `subprocess.Popen` to trigger the planner in the background, ensuring the webhook responds instantly to the mobile client.

```python
@app.post("/api/health/sleep")
async def receive_sleep_data(data: SleepData, background_tasks: BackgroundTasks):
    # 1. Parse and store biometric data
    save_health_data(data) 
    
    # 2. Trigger the planner asynchronously (Event-Driven)
    subprocess.Popen([venv_python, daily_planner_script], cwd=str(REPO_PATH))
    
    return {"status": "success", "message": "Daily Planner triggered"}
```

**2. Dynamic Intensity Logic**
Instead of a generic prompt, I introduced a scoring matrix that maps the 100-point sleep scale to specific operational modes:

*   **Score < 60 (Recovery Mode):** Focus on one core task; prioritize rest and defensive planning.
*   **Score 60–85 (Balanced Mode):** Standard distribution of Deep Work and administrative tasks.
*   **Score > 85 (Peak Mode):** Aggressively increase Deep Work blocks and tackle high-complexity challenges.

```python
if condition_score < 60:
    intensity_guide = f"Sleep score is {condition_score}. System is depleted. Plan defensively with 1 core task."
elif condition_score >= 85:
    intensity_guide = f"Sleep score is {condition_score}. Peak condition. Maximize Deep Work blocks."
```

### Lessons Learned

**1. Decoupling is the Key to Reliability**
By moving from a `launchd` calendar interval to a webhook, I removed the risk of the script running before the health data was available. The system now waits for the data to exist before attempting to process it.

**2. The Value of "Human-in-the-Loop" Data**
Integrating biometric data transformed the LLM from a simple text generator into a context-aware coach. The system no longer just tells me *what* to do, but *how much* I am capable of doing today.

**3. Handling Asynchronous Failures**
Moving to an event-driven model introduced a new failure point: the webhook could fail. To mitigate this, I implemented an `AlertManager` that sends a critical Telegram notification if the `health_receiver` fails to trigger the planner, ensuring that I am never left without a plan for the day.

This architecture proves that SRE principles—observability, event-driven triggers, and automated recovery—are just as powerful for managing a human life as they are for managing a fleet of microservices.

---
> **Phase Mapping:** 본 작업은 Phase 2(Data Foundation & Automation)의 고도화 단계에 해당합니다. 단순한 스케줄링 기반의 자동화를 넘어, 외부 생체 데이터(삼성 헬스)를 트리거로 사용하는 '이벤트 기반 아키텍처(Event-Driven Architecture)'로 전환함으로써 시스템의 지능적 반응성을 높이고 데이터 기반의 개인화된 생산성 관리를 구현했습니다.