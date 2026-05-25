#!/usr/bin/env python3
"""
unicorn_factory/factory_orchestrator.py
=======================================
1인 유니콘 자율 소프트웨어 공장의 관제탑(Orchestrator).
텔레그램 API getUpdates를 통해 실시간 명령어 입력을 수신 및 대기하고, 
지훈님의 /antigravity 지시를 감지하면 즉시 DB 대기열에 삽입한 후 
Agent Engine 워커를 비동기 백그라운드로 스폰(Spawn)하여 동시 다발적 코딩을 진행합니다.
"""

import os
import sys
import time
import argparse
import subprocess
import urllib.request
import urllib.parse
import json
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_REPO_ROOT / "scripts/unicorn_factory"))

from db_queue import DatabaseQueue
from service_registry import ServiceRegistry


class FactoryOrchestrator:
    def __init__(self):
        self.db = DatabaseQueue()
        self.registry = ServiceRegistry(_REPO_ROOT)
        self.tg_token = os.getenv("TELEGRAM_BOT_TOKEN")
        self.chat_id = os.getenv("TELEGRAM_CHAT_ID", "8493423236")
        self.offset = 0

        if not self.tg_token:
            print("[ORCH FATAL]: TELEGRAM_BOT_TOKEN environment variable is missing!", file=sys.stderr)
            sys.exit(1)

    def send_telegram_message(self, text):
        url = f"https://api.telegram.org/bot{self.tg_token}/sendMessage"
        payload = {
            "chat_id": self.chat_id,
            "text": text,
            "parse_mode": "Markdown"
        }
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode('utf-8'),
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                pass
        except Exception as e:
            print(f"[ORCH ERROR]: Failed to send message: {e}", file=sys.stderr)

    def start_orchestration(self, once=False):
        print("🤖 [Orchestrator ONLINE]: Starting Unicorn Software Factory Queue-Polling Gateway...")
        self.send_telegram_message("🤖 *[Unicorn Orchestrator ONLINE]*\n\n1인 유니콘 자율 소프트웨어 공장 관제탑이 데이터베이스 큐 모니터링 모드로 재기동되었습니다. 텔레그램 커맨더가 입력한 작업이 대기열에 등록되는 즉시 비동기 런타임 빌드가 트리거됩니다. 🛰️")
        
        while True:
            try:
                # 1. Get all jobs in QUEUED status
                queued_jobs = self.db.get_queued_jobs()
                for job in queued_jobs:
                    job_id = job["job_id"]
                    cmd_text = job["command_text"]
                    target_app_query = job["target_app"] or "sfx_memento_mori"
                    
                    # 2. Dynamic app matching
                    resolved_app = self.registry.get_app(cmd_text)
                    target_app_id = resolved_app["id"] if resolved_app else target_app_query
                    
                    print(f"[ORCH QUEUE]: Detected QUEUED job {job_id} -> \"{cmd_text}\"")
                    
                    # Prevent race conditions by updating state to RUNNING immediately before spawning
                    self.db.update_job_status(job_id, "RUNNING")
                    
                    # 3. Spawn Agent Engine as asynchronous background worker
                    try:
                        engine_script = str(_REPO_ROOT / "scripts/unicorn_factory/agent_engine.py")
                        print(f"[ORCH SPONDING]: Spawning Subprocess Agent Engine with Job_ID: {job_id}")
                        subprocess.Popen(
                            [sys.executable, engine_script, job_id],
                            start_new_session=True
                        )
                    except Exception as e:
                        print(f"[ORCH ERROR]: Failed to spawn AgentEngine: {e}", file=sys.stderr)
                        self.send_telegram_message(f"❌ *[오류]* SRE 에이전트 스폰 실패: {e}")
                        self.db.update_job_status(job_id, "FAILED", log_path=str(e))
                        
            except Exception as e:
                print(f"[ORCH WARN]: Queue polling encountered error: {e}", file=sys.stderr)
                
            if once:
                print("[ORCH INFO]: Single queue poll verification completed.")
                break
                
            time.sleep(1.0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true", help="Run once for polling verification")
    args = parser.parse_args()

    orchestrator = FactoryOrchestrator()
    orchestrator.start_orchestration(once=args.once)
