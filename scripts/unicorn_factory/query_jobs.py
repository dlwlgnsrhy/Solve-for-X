#!/usr/bin/env python3
import sys
import os
import json
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_REPO_ROOT / "scripts/unicorn_factory"))

from db_queue import DatabaseQueue

def main():
    db = DatabaseQueue()
    
    # Ensure standard SQLite table if not exist
    if not db.is_postgres:
        cursor = db.conn.cursor()
        cursor.execute("CREATE TABLE IF NOT EXISTS agent_jobs (job_id TEXT PRIMARY KEY, command_text TEXT NOT NULL, target_app TEXT, status TEXT DEFAULT 'QUEUED', log_file_path TEXT, walkthrough_md TEXT, screenshot_path TEXT, created_at TEXT, updated_at TEXT);")
        db.conn.commit()
        cursor.close()

    if len(sys.argv) > 1 and sys.argv[1] == "--register":
        # Register a new job
        if len(sys.argv) < 3:
            print(json.dumps({"status": "ERROR", "error": "Missing command text"}))
            return
        command_text = sys.argv[2]
        target_app = sys.argv[3] if len(sys.argv) > 3 else "sfx_memento_mori"
        
        job_id = db.register_job(command_text, target_app)
        
        # Spawn agent_engine.py as background worker
        try:
            import subprocess
            engine_script = str(_REPO_ROOT / "scripts/unicorn_factory/agent_engine.py")
            subprocess.Popen(
                [sys.executable, engine_script, job_id],
                start_new_session=True
            )
            print(json.dumps({"status": "SUCCESS", "job_id": job_id}))
        except Exception as e:
            print(json.dumps({"status": "ERROR", "error": f"Failed to spawn worker: {e}"}))
    else:
        # Query all jobs
        cursor = db.conn.cursor()
        if db.is_postgres:
            cursor.execute("SELECT job_id, command_text, target_app, status, log_file_path, walkthrough_md, screenshot_path, created_at, updated_at FROM sfx_core.agent_jobs ORDER BY created_at DESC;")
        else:
            cursor.execute("SELECT job_id, command_text, target_app, status, log_file_path, walkthrough_md, screenshot_path, created_at, updated_at FROM agent_jobs ORDER BY datetime(created_at) DESC;")
        
        rows = cursor.fetchall()
        jobs = []
        for r in rows:
            jobs.append({
                "job_id": str(r[0]),
                "command_text": r[1],
                "target_app": r[2],
                "status": r[3],
                "log_file_path": r[4],
                "walkthrough_md": r[5],
                "screenshot_path": r[6],
                "created_at": r[7],
                "updated_at": r[8]
            })
        cursor.close()
        print(json.dumps(jobs, indent=2))

if __name__ == "__main__":
    main()
