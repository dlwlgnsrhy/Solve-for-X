#!/usr/bin/env python3
"""
telegram_commander/main.py
===========================
텔레그램 커맨드 핸들러 — 관제탑(Orchestrator) 역할
지훈님의 컨펌(Confirm)을 받은 후 진짜 에이전트(Worker)를 실행하는 구조입니다.

지원 커맨드:
  /start   → 노션 오늘 계획 읽기 → 실행 계획 브리핑 생성 → 컨펌 대기
  /confirm → 계획 승인 → 실제 작업자(Worker) 백그라운드 실행
  /feedback [내용] → 피드백 반영 후 계획 수정 → 다시 컨펌 대기
  /status  → 현재 진행 상황 확인
  /report  → 즉시 리포트 생성
"""

import sys
import logging
import argparse
import datetime
import subprocess
import importlib.util
from pathlib import Path

_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient
from _shared.notion_client import NotionClient

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

REPO_PATH = Path(__file__).parent.parent.parent.parent
STATE_FILE = Path(__file__).parent / ".state.json"

# ─────────────────────────────────────────────────────────────────────
# 상태 관리 (상태 머신 도입: idle -> pending_confirmation -> running)
# ─────────────────────────────────────────────────────────────────────

def load_state() -> dict:
    import json
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {"date": "", "status": "idle", "tasks": [], "completed": [], "feedback_log": [], "current_plan": ""}

def save_state(state: dict):
    import json
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2))

def reset_state_if_new_day(state: dict) -> dict:
    today = datetime.date.today().isoformat()
    if state.get("date") != today:
        state = {"date": today, "status": "idle", "tasks": [], "completed": [], "feedback_log": [], "current_plan": ""}
        save_state(state)
    return state

# ─────────────────────────────────────────────────────────────────────
# 노션 & 브리핑 재사용
# ─────────────────────────────────────────────────────────────────────

def fetch_all_blocks(notion: NotionClient, block_id: str, depth: int = 0) -> list:
    """블록을 재귀적으로 읽어 자식 블록까지 포함한 전체 리스트 반환"""
    blocks = notion.get_page_blocks(block_id)
    result = []
    for block in blocks:
        result.append(block)
        if block.get("has_children") and depth < 3:
            child_id = block.get("id", "")
            if child_id:
                children = fetch_all_blocks(notion, child_id, depth + 1)
                result.extend(children)
    return result

def parse_tasks_from_notion(notion: NotionClient) -> list[str]:
    page_id = notion.get_today_page_id()
    if not page_id: return []
    
    # 최상위 블록만 가져오던 로직을 자식 블록(재귀) 탐색으로 변경
    all_blocks = fetch_all_blocks(notion, page_id)
    
    tasks = []
    for block in all_blocks:
        block_type = block.get("type", "")
        if block_type == "to_do":
            text = "".join(t.get("plain_text", "") for t in block.get("to_do", {}).get("rich_text", [])).strip()
            if text: tasks.append(text)
        elif block_type == "bulleted_list_item":
            text = "".join(t.get("plain_text", "") for t in block.get("bulleted_list_item", {}).get("rich_text", [])).strip()
            if text and (text.startswith("[ ]") or text.startswith("[x]") or text.startswith("[X]")):
                tasks.append(text[3:].strip())
    return tasks

def _get_morning_briefing(tasks: list[str], notion: NotionClient, llm: LLMClient, today_str: str) -> str:
    # daily_planner의 로직을 그대로 사용 (단일 진실 공급원)
    planner_path = Path(__file__).parent.parent / "daily_planner" / "main.py"
    spec = importlib.util.spec_from_file_location("planner", planner_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    
    week_summary = notion.get_week_summary()
    roadmap_path = REPO_PATH / "ROADMAP.md"
    roadmap = roadmap_path.read_text(encoding="utf-8")[:1000] if roadmap_path.exists() else ""
    
    return mod.generate_morning_briefing(tasks, week_summary, roadmap, llm, today_str)

# ─────────────────────────────────────────────────────────────────────
# 커맨드 핸들러
# ─────────────────────────────────────────────────────────────────────

def handle_start(telegram: TelegramClient, notion: NotionClient, llm: LLMClient, state: dict):
    today = datetime.date.today().strftime("%Y-%m-%d")
    telegram.send(f"🔍 [{today}] 노션 오늘 계획을 읽고 파싱합니다...")

    page_id = notion.get_today_page_id()
    if not page_id:
        telegram.send(f"⚠️ 노션에 오늘({today}) 계획 페이지가 없습니다.")
        return

    tasks = parse_tasks_from_notion(notion)
    if not tasks:
        telegram.send("⚠️ 오늘 계획된 할 일이 없습니다. 노션에 체크박스([ ]) 형태로 작성해주세요.")
        return

    briefing = _get_morning_briefing(tasks, notion, llm, today)

    state["tasks"] = tasks
    state["current_plan"] = briefing
    state["status"] = "pending_confirmation"  # 컨펌 대기 상태로 변경!
    save_state(state)

    tasks_text = "\n".join(f"  • {t}" for t in tasks)
    msg = (
        f"✅ [{today}] 오늘 계획 확인 완료!\n\n"
        f"📋 할 일 ({len(tasks)}개):\n{tasks_text}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{briefing}\n\n"
        f"⚠️ **[승인 대기 중]**\n"
        f"위 계획대로 작업을 시작할까요?\n"
        f"👉 /confirm : 에이전트 작업 즉시 시작\n"
        f"👉 /feedback [수정할 내용] : 계획 수정 후 다시 검토"
    )
    telegram.send_chunked(msg)

def handle_confirm(telegram: TelegramClient, state: dict):
    if state.get("status") != "pending_confirmation":
        telegram.send("⚠️ 현재 승인 대기 중인 작업 계획이 없습니다. /start 로 계획을 먼저 세워주세요.")
        return
    
    current_plan = state.get("current_plan", "")
    
    # "## 🤖 에이전트 자율 실행:" 아래 텍스트 추출
    import re
    agent_tasks = ""
    match = re.search(r'## 🤖 에이전트 자율 실행:(.*?)(?=## 👤|## 💡|$)', current_plan, re.DOTALL)
    if match:
        extracted = match.group(1).strip()
        if extracted and "(없음)" not in extracted:
            agent_tasks = extracted

    if not agent_tasks:
        telegram.send("⚠️ 에이전트 자율 실행으로 분류된 작업이 없습니다. 작업 상태만 [실행 중]으로 변경합니다.")
        state["status"] = "running"
        save_state(state)
        return

    state["status"] = "running"
    save_state(state)
    
    telegram.send(
        "🚀 **[실행 시작]** 승인되었습니다!\n\n"
        "실제 작업자(Hermes)를 백그라운드에서 호출합니다...\n"
        "(작업 상태는 state.db를 통해 모니터링됩니다.)"
    )
    
    try:
        # Hermes 실행 (백그라운드 독립 프로세스로)
        prompt = f"다음 작업을 수행해:\n{agent_tasks}"
        hermes_bin = "/Users/apple/.local/bin/hermes"
        
        log_file = open("/tmp/hermes_worker.log", "w")
        subprocess.Popen(
            [hermes_bin, "chat", "-q", prompt, "--yolo", "--max-turns", "15"],
            cwd=str(REPO_PATH),
            stdout=log_file,
            stderr=subprocess.STDOUT,
            start_new_session=True
        )
        logger.info(f"[Commander] Hermes 작업자 프로세스 트리거 완료 (태스크: {agent_tasks[:30]}...)")
    except Exception as e:
        logger.error(f"[Commander] Hermes 실행 실패: {e}")
        telegram.send(f"❌ Hermes 프로세스 실행에 실패했습니다: {e}")

def handle_feedback(telegram: TelegramClient, llm: LLMClient, state: dict, feedback_text: str):
    if not feedback_text.strip():
        telegram.send("⚠️ 피드백 내용을 입력해주세요. 예) /feedback 첫번째 항목은 빼고 진행해")
        return

    today = datetime.date.today().strftime("%Y-%m-%d")
    state.setdefault("feedback_log", []).append(f"[{today}] {feedback_text}")
    
    status = state.get("status", "idle")
    current_plan = state.get("current_plan", "")
    
    if status == "pending_confirmation":
        telegram.send(f"💬 피드백 반영 중...\n'{feedback_text}'")
        # 승인 전 계획 수정
        system_prompt = (
            "당신은 개발자의 생산성 코치입니다. 사용자의 피드백을 엄격하게 반영하여 기존 계획 브리핑을 전면 수정하세요.\n"
            "사용자가 '~만 에이전트 작업으로 진행해'라고 지시하면, 기존의 다른 에이전트 작업들은 모두 삭제하고 오직 지시받은 항목만 '🤖 에이전트 자율 실행'에 남겨야 합니다.\n"
            "단순 추가가 아니라 피드백의 의도를 파악하여 불필요한 항목은 가차없이 제거하세요.\n\n"
            "추론 과정을 작성하더라도, 최종 출력 전에는 반드시 '===OUTPUT_START==='를 작성하고 그 아래에 결과만 출력하세요.\n\n"
            "===OUTPUT_START===\n"
            "## 🤖 에이전트 자율 실행:\n- [항목]\n\n"
            "## 👤 직접 처리 필요:\n- [항목]\n\n"
            "## 💡 오늘의 핵심 조언 (1줄):\n> [조언]"
        )
        user_prompt = f"기존 계획:\n{current_plan}\n\n사용자 피드백:\n{feedback_text}"
        
        try:
            # 3-cycle retry & telegram status update callback 적용
            new_plan = llm.ask(
                user_prompt, 
                system_prompt, 
                use_external=True, 
                max_tokens=2500,
                status_callback=telegram.send
            )
            
            state["current_plan"] = new_plan
            save_state(state)
            telegram.send(
                f"🔄 계획이 수정되었습니다.\n\n━━━━━━━━━━━━━━━━━━━━\n{new_plan}\n\n"
                f"⚠️ **[승인 대기 중]**\n"
                f"이대로 진행할까요? /confirm 또는 /feedback [추가수정]"
            )
        except Exception as e:
            # 3사이클 모두 실패 시 에러 던짐
            # llm_client 내에서 에러 메시지를 이미 callback으로 보냈을 수 있지만 만약을 위해 로깅
            logger.error(f"[Commander] 피드백 파싱 실패: {e}")
            
    elif status == "running":
        # 실행 도중 지시 변경
        telegram.send("⚙️ 현재 에이전트가 작업 중입니다. 진행 중인 워커(Worker) 프로세스에 피드백을 전달했습니다. (기능 구현 예정)")
    else:
        telegram.send("⚠️ 현재 진행 중인 계획이 없습니다. /start를 먼저 해주세요.")

def handle_status(telegram: TelegramClient, state: dict):
    status = state.get("status", "idle")
    tasks = state.get("tasks", [])
    
    if status == "idle":
        telegram.send("💤 현재 대기 중입니다. /start로 하루를 시작하세요.")
    elif status == "pending_confirmation":
        telegram.send("⚠️ 계획이 수립되었으며, 지훈님의 **/confirm** 승인을 기다리고 있습니다.")
    elif status == "running":
        telegram.send(f"🚀 에이전트가 백그라운드에서 열심히 작업 중입니다! (할 일: {len(tasks)}개)")

# ─────────────────────────────────────────────────────────────────────
# 메인 루프
# ─────────────────────────────────────────────────────────────────────

def get_updates(token: str, offset: int = 0) -> list:
    import requests
    import time
    try:
        resp = requests.get(
            f"https://api.telegram.org/bot{token}/getUpdates",
            params={"offset": offset, "timeout": 30},
            timeout=35
        )
        resp.raise_for_status()
        return resp.json().get("result", [])
    except requests.exceptions.Timeout:
        return []
    except Exception as e:
        logger.error(f"[Telegram] 폴링 실패: {e}")
        time.sleep(3)  # 네트워크 단절 시 무한 루프 폭주 방지
        return []

def process_message(text: str, telegram: TelegramClient, notion: NotionClient, llm: LLMClient, state: dict):
    text = text.strip()
    logger.info(f"[Commander] 수신: {text}")

    if text == "/start":
        handle_start(telegram, notion, llm, state)
    elif text == "/confirm":
        handle_confirm(telegram, state)
    elif text.startswith("/feedback"):
        handle_feedback(telegram, llm, state, text[len("/feedback"):].strip())
    elif text == "/status":
        handle_status(telegram, state)
    else:
        telegram.send(
            "🤖 **Commander 지원 커맨드**\n"
            "/start — 오늘 계획 세우기\n"
            "/confirm — 계획 승인 및 에이전트 실제 실행\n"
            "/feedback [내용] — 계획 수정 및 지시\n"
            "/status — 상태 확인"
        )

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    config.load_env()
    token = config.require("TELEGRAM_BOT_TOKEN")
    
    telegram = TelegramClient()
    notion = NotionClient()
    llm = LLMClient()
    
    # 상태 복원
    state = load_state()
    state = reset_state_if_new_day(state)
    
    # 워커(Hermes) 모니터링 데몬 시작
    from worker_monitor import start_monitor
    start_monitor(telegram)

    if args.once:
        for update in get_updates(token):
            msg = update.get("message", {})
            text = msg.get("text", "")
            if text: process_message(text, telegram, notion, llm, state)
        return

    logger.info("🤖 Telegram Commander 온라인 (Orchestrator Mode)")
    telegram.send("🤖 **에이전트 관제탑(Commander)** 재시작 완료!\n노션 작성 후 /start 로 브리핑을 받고 /confirm 으로 실행하세요.")
    
    offset = 0
    while True:
        updates = get_updates(token, offset)
        for update in updates:
            offset = update["update_id"] + 1
            msg = update.get("message", {})
            text = msg.get("text", "")
            if text:
                process_message(text, telegram, notion, llm, state)

if __name__ == "__main__":
    main()
