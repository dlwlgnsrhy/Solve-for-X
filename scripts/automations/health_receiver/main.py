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
from pathlib import Path
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.alert_manager import AlertManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

REPO_PATH = Path(__file__).parent.parent.parent.parent
HEALTH_JSON_PATH = REPO_PATH / "docs" / "daily_health.json"

app = FastAPI(title="Soluni Health Receiver Webhook Server")

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
    energyLevel: int = 3
    mood: str = ""
    focusMode: str = ""

def trigger_daily_planner():
    logger.info("[Webhook] Triggering Daily Planner (Event-Driven)...")
    try:
        daily_planner_script = Path(__file__).parent.parent / "daily_planner" / "main.py"
        venv_python = Path(__file__).parent.parent / "daily_planner" / "venv" / "bin" / "python3"
        
        cmd = [str(venv_python) if venv_python.exists() else "python3", str(daily_planner_script)]
        
        # 서브프로세스로 넘겨버리고 본 프로세스는 응답만 바로 반환
        subprocess.Popen(cmd, cwd=str(REPO_PATH), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logger.info("[Webhook] Daily Planner background execution started.")
    except Exception as e:
        logger.error(f"[Webhook] Failed to trigger Daily Planner: {e}")
        AlertManager().send_critical_alert("🚨 [Health Receiver 에러]", f"Daily Planner 트리거 기동 실패: {e}")

@app.post("/api/health/sleep")
def receive_sleep_data(data: dict, background_tasks: BackgroundTasks):
    logger.info(f"[Webhook] Raw 데이터 수신: {data}")
    
    # MacroDroid에서 어떤 형태로든 데이터를 넘겼을 때 유연하게 파싱
    raw_str = f"{data.get('score', '')} {data.get('duration', '')} {data.get('title', '')} {data.get('text', '')}"
    
    import re
    score_val = 70
    duration_str = "측정불가"
    
    # 1) 명시적으로 score 키에 숫자가 들어온 경우
    if str(data.get("score")).isdigit():
        score_val = int(data.get("score"))
    else:
        # 2) 텍스트 어딘가에 "93점" 같은 패턴이 있는지 찾기
        m = re.search(r'(\d{2,3})\s*점', raw_str)
        if m:
            score_val = int(m.group(1))
            
    # 시간(예: 7시간 26분) 파싱
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
        
        # 저장 완료 후 백그라운드에서 플래너 실행
        background_tasks.add_task(trigger_daily_planner)
        
        return {"status": "success", "message": f"Data saved for {today_str} and planner triggered."}
    except Exception as e:
        logger.error(f"[Webhook] JSON 저장 실패: {e}")
        AlertManager().send_critical_alert("🚨 [Health Receiver 에러]", f"JSON 저장 실패: {e}")
        return {"status": "error", "message": str(e)}


@app.post("/api/health/daily-checkin")
def receive_daily_checkin(data: DailyCheckinData, background_tasks: BackgroundTasks):
    """Receive daily check-in data from the Flutter app and trigger the daily planner."""
    logger.info(f"[DailyCheckin] 수신: energyLevel={data.energyLevel}, mood={data.mood}, focusMode={data.focusMode}")
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


if __name__ == "__main__":
    import uvicorn
    # 직접 실행 시 포트 8080. 모든 인터페이스(0.0.0.0) 개방.
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=False)
