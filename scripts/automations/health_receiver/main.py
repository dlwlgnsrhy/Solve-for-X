#!/usr/bin/env python3
"""
health_receiver/main.py
========================
스마트폰(Tasker 등)에서 날아오는 수면/헬스 데이터를 수신받고
JSON으로 저장한 뒤, 비동기로 Daily Planner를 깨우는(Trigger) 서버.
"""

import sys
import logging
import datetime
import subprocess
import json
import os
from pathlib import Path
from fastapi import FastAPI, BackgroundTasks, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.alert_manager import AlertManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

REPO_PATH = Path(__file__).parent.parent.parent.parent
HEALTH_JSON_PATH = REPO_PATH / "docs" / "daily_health.json"


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("[Health Receiver] Server starting up...")
    HEALTH_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    yield
    logger.info("[Health Receiver] Server shutting down.")


app = FastAPI(
    title="Soluni Health Receiver Webhook Server",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SleepData(BaseModel):
    score: str = ""
    duration: str = ""
    title: str = ""
    text: str = ""


class DailyCheckinData(BaseModel):
    energyLevel: int = Field(default=3, ge=1, le=5, description="Energy level from 1 to 5")
    mood: str = Field(default="", description="Current mood")
    focusMode: str = Field(default="", description="Current focus mode")


def trigger_daily_planner():
    logger.info("[Webhook] Triggering Daily Planner (Event-Driven)...")
    try:
        daily_planner_script = Path(__file__).parent.parent / "daily_planner" / "main.py"
        
        if not daily_planner_script.exists():
            logger.warning("[Webhook] Daily planner script not found: %s", daily_planner_script)
            return
        
        venv_python = Path(__file__).parent.parent / "daily_planner" / "venv" / "bin" / "python3"
        
        python_cmd = str(venv_python) if venv_python.exists() else "python3"
        cmd = [python_cmd, str(daily_planner_script)]
        
        proc = subprocess.Popen(cmd, cwd=str(REPO_PATH), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            proc.wait(timeout=30)
            if proc.returncode == 0:
                logger.info("[Webhook] Daily Planner executed successfully.")
            else:
                _, stderr = proc.communicate()
                logger.error("[Webhook] Daily Planner failed with code %d: %s", proc.returncode, stderr.decode()[:200])
        except subprocess.TimeoutExpired:
            proc.kill()
            logger.error("[Webhook] Daily Planner timed out after 30s")
    except Exception as e:
        logger.error("[Webhook] Failed to trigger Daily Planner: %s", e)
        try:
            AlertManager().send_critical_alert(
                "🚨 [Health Receiver 에러]",
                f"Daily Planner 트리거 기동 실패: {e}",
            )
        except Exception:
            pass


@app.post("/api/health/sleep")
async def receive_sleep_data(request: Request, data: dict, background_tasks: BackgroundTasks):
    logger.info(f"[Webhook] Raw 데이터 수신: {data}")
    
    raw_str = f"{data.get('score', '')} {data.get('duration', '')} {data.get('title', '')} {data.get('text', '')}"
    
    import re
    score_val = 70
    duration_str = "측정불가"
    
    if str(data.get("score")).isdigit():
        score_val = int(data.get("score"))
    else:
        m = re.search(r'(\d{2,3})\s*점', raw_str)
        if m:
            score_val = int(m.group(1))
            
    hm = re.search(r'(\d+)\s*시간\s*(\d+)?\s*분?', raw_str)
    if hm:
        duration_str = f"{hm.group(1)}시간 {hm.group(2)+'분' if hm.group(2) else ''}".strip()
    
    logger.info(f"[Webhook] 파싱 완료: 점수({score_val}점), 시간({duration_str})")
    
    today_str = datetime.date.today().strftime("%Y-%m-%d")
    health_record = {
        "date": today_str,
        "sleep_score": score_val,
        "sleep_duration": duration_str,
        "timestamp": datetime.datetime.now().isoformat(),
        "raw_data": data
    }
    
    try:
        HEALTH_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(HEALTH_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(health_record, f, ensure_ascii=False, indent=2)
            
        logger.info(f"[Webhook] {HEALTH_JSON_PATH} 에 저장 완료.")
        
        background_tasks.add_task(trigger_daily_planner)
        
        return {"status": "success", "message": f"Data saved for {today_str} and planner triggered."}
    except Exception as e:
        logger.error(f"[Webhook] JSON 저장 실패: {e}")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "message": str(e)},
        )


@app.post("/api/health/daily-checkin")
async def receive_daily_checkin(data: DailyCheckinData, background_tasks: BackgroundTasks):
    logger.info(f"[DailyCheckin] 수신: energyLevel={data.energyLevel}, mood={data.mood}, focusMode={data.focusMode}")

    try:
        today_str = datetime.date.today().strftime("%Y-%m-%d")
        checkin_record = {
            "date": today_str,
            "energyLevel": data.energyLevel,
            "mood": data.mood,
            "focusMode": data.focusMode,
            "timestamp": datetime.datetime.now().isoformat(),
        }

        HEALTH_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(HEALTH_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(checkin_record, f, ensure_ascii=False, indent=2)

        background_tasks.add_task(trigger_daily_planner)

        return {
            "status": "success",
            "message": "Daily check-in received and planner triggered.",
            "data": {
                "energyLevel": data.energyLevel,
                "mood": data.mood,
                "focusMode": data.focusMode,
            },
        }
    except Exception as e:
        logger.error(f"[DailyCheckin] 처리 오류: {e}")
        return JSONResponse(
            status_code=500,
            content={"status": "error", "message": f"Internal server error: {str(e)}"},
        )


# 404/405 handler — prevent uvicorn default from leaking as 502
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={"detail": "Not Found — check the endpoint path"},
    )


@app.exception_handler(405)
async def method_not_allowed_handler(request: Request, exc):
    return JSONResponse(
        status_code=405,
        content={"detail": "Method Not Allowed — check the HTTP method"},
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=False,
        log_level="info",
        timeout_graceful_shutdown=10,
    )
