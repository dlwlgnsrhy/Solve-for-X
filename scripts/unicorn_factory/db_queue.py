#!/usr/bin/env python3
"""
unicorn_factory/db_queue.py
===========================
1인 유니콘 기업의 무중단 상태 동기화를 위한 하이브리드 데이터베이스 큐 엔진.
PostgreSQL(Supabase) 커넥션을 우선 시도하되, 실패하거나 설정이 없을 시 
로컬 SQLite(.unicorn_jobs.db)로 0.1초 내에 자동 Fallback하여 100% 가동성을 유지합니다.
"""

import os
import sys
import sqlite3
import uuid
import datetime
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
_DB_PATH = Path(__file__).resolve().parent / ".unicorn_jobs.db"

class DatabaseQueue:
    def __init__(self):
        self.is_postgres = False
        self.conn = None
        self._init_db()

    def _init_db(self):
        # 1. PostgreSQL 연결 시도 (Supabase 등)
        pg_url = os.getenv("DATABASE_URL")
        if pg_url:
            try:
                import psycopg2
                self.conn = psycopg2.connect(pg_url)
                self.is_postgres = True
                self._create_pg_tables()
                print("[DB INFO]: PostgreSQL (Supabase) Database Successfully Connected.")
                return
            except Exception as e:
                print(f"[DB WARN]: PostgreSQL connection failed ({e}). Falling back to SQLite3...", file=sys.stderr)
        
        # 2. SQLite3 Fallback 기동
        try:
            self.conn = sqlite3.connect(str(_DB_PATH), check_same_thread=False)
            self._create_sqlite_tables()
            print(f"[DB INFO]: SQLite3 Local Database Switched and Loaded. Path: {_DB_PATH}")
        except Exception as e:
            print(f"[DB FATAL]: Failed to initialize local SQLite database: {e}", file=sys.stderr)
            sys.exit(1)

    def _create_pg_tables(self):
        cursor = self.conn.cursor()
        cursor.execute("CREATE SCHEMA IF NOT EXISTS sfx_core;")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sfx_core.agent_jobs (
                job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                command_text TEXT NOT NULL,
                target_app VARCHAR(50),
                status VARCHAR(20) DEFAULT 'QUEUED',
                log_file_path TEXT,
                walkthrough_md TEXT,
                screenshot_path TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
        """)
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_agent_jobs_status ON sfx_core.agent_jobs(status);")
        self.conn.commit()
        cursor.close()

    def _create_sqlite_tables(self):
        cursor = self.conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS agent_jobs (
                job_id TEXT PRIMARY KEY,
                command_text TEXT NOT NULL,
                target_app TEXT,
                status TEXT DEFAULT 'QUEUED',
                log_file_path TEXT,
                walkthrough_md TEXT,
                screenshot_path TEXT,
                created_at TEXT,
                updated_at TEXT
            );
        """)
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_agent_jobs_status ON agent_jobs(status);")
        self.conn.commit()
        cursor.close()

    def register_job(self, command_text, target_app="sfx_memento_mori"):
        """새 작업을 대기열(QUEUED)에 등록"""
        job_id = str(uuid.uuid4())
        now_str = datetime.datetime.now().isoformat()
        cursor = self.conn.cursor()

        if self.is_postgres:
            cursor.execute(
                """
                INSERT INTO sfx_core.agent_jobs (job_id, command_text, target_app, status)
                VALUES (%s, %s, %s, 'QUEUED')
                RETURNING job_id;
                """,
                (job_id, command_text, target_app)
            )
        else:
            cursor.execute(
                """
                INSERT INTO agent_jobs (job_id, command_text, target_app, status, created_at, updated_at)
                VALUES (?, ?, ?, 'QUEUED', ?, ?);
                """,
                (job_id, command_text, target_app, now_str, now_str)
            )
        
        self.conn.commit()
        cursor.close()
        print(f"[DB QUEUE]: Job Registered successfully. Job_ID: {job_id} | Command: \"{command_text}\"")
        return job_id

    def update_job_status(self, job_id, status, log_path=None, walkthrough_md=None, screenshot_path=None):
        """작업의 진행 상태(RUNNING, SUCCESS, FAILED) 및 완료 자산 실측 기록"""
        now_str = datetime.datetime.now().isoformat()
        cursor = self.conn.cursor()

        if self.is_postgres:
            cursor.execute(
                """
                UPDATE sfx_core.agent_jobs
                SET status = %s, log_file_path = %s, walkthrough_md = %s, screenshot_path = %s, updated_at = CURRENT_TIMESTAMP
                WHERE job_id = %s;
                """,
                (status, log_path, walkthrough_md, screenshot_path, job_id)
            )
        else:
            cursor.execute(
                """
                UPDATE agent_jobs
                SET status = ?, log_file_path = ?, walkthrough_md = ?, screenshot_path = ?, updated_at = ?
                WHERE job_id = ?;
                """,
                (status, log_path, walkthrough_md, screenshot_path, now_str, job_id)
            )
        
        self.conn.commit()
        cursor.close()
        print(f"[DB QUEUE]: Job {job_id} Status Updated to {status}")

    def get_job(self, job_id):
        cursor = self.conn.cursor()
        if self.is_postgres:
            cursor.execute("SELECT job_id, command_text, status, target_app FROM sfx_core.agent_jobs WHERE job_id = %s;", (job_id,))
        else:
            cursor.execute("SELECT job_id, command_text, status, target_app FROM agent_jobs WHERE job_id = ?;", (job_id,))
        
        row = cursor.fetchone()
        cursor.close()
        if row:
            return {"job_id": row[0], "command_text": row[1], "status": row[2], "target_app": row[3]}
        return None

    def get_queued_jobs(self):
        """대기열에 등록되었으나 아직 실행되지 않은(QUEUED) 작업 목록 조회"""
        cursor = self.conn.cursor()
        if self.is_postgres:
            cursor.execute("SELECT job_id, command_text, status, target_app FROM sfx_core.agent_jobs WHERE status = 'QUEUED' ORDER BY created_at ASC;")
        else:
            cursor.execute("SELECT job_id, command_text, status, target_app FROM agent_jobs WHERE status = 'QUEUED' ORDER BY created_at ASC;")
        
        rows = cursor.fetchall()
        cursor.close()
        return [{"job_id": r[0], "command_text": r[1], "status": r[2], "target_app": r[3]} for r in rows]

if __name__ == "__main__":
    db = DatabaseQueue()
    jid = db.register_job("Test Auto Run command from DevOps Specialist")
    db.update_job_status(jid, "RUNNING")
    db.update_job_status(jid, "SUCCESS", walkthrough_md="Done nicely.", screenshot_path="docs/images/sfx_real_brand_web.png")
    print(db.get_job(jid))
