#!/usr/bin/env python3
"""
telegram_commander/main.py
===========================
텔레그램 커맨드 핸들러 — 당신의 명령을 받아 에이전트 파이프라인을 실행합니다.

지원 커맨드:
  /start   → 노션 오늘 계획 읽기 → 실행 시작
  /status  → 현재 진행 상황 확인
  /report  → 즉시 리포트 생성
  /done    → 오늘 마무리 + 최종 리포트
  /feedback [내용] → 피드백 반영 후 작업 조정

실행 방법:
  python main.py          # 폴링 모드 (로컬 테스트)
  python main.py --once   # 메시지 한 번만 확인 후 종료 (launchd용)
"""

import sys
import logging
import argparse
import datetime
import subprocess
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
# 상태 관리 (오늘 실행된 태스크 추적)
# ─────────────────────────────────────────────────────────────────────

def load_state() -> dict:
    import json
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {"date": "", "tasks": [], "completed": [], "feedback_log": []}


def save_state(state: dict):
    import json
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2))


def reset_state_if_new_day(state: dict) -> dict:
    today = datetime.date.today().isoformat()
    if state.get("date") != today:
        state = {"date": today, "tasks": [], "completed": [], "feedback_log": []}
        save_state(state)
    return state


# ─────────────────────────────────────────────────────────────────────
# 노션 계획 파싱
# ─────────────────────────────────────────────────────────────────────

def parse_tasks_from_notion(notion: NotionClient) -> list[str]:
    """노션 오늘 페이지에서 할 일 블록을 파싱합니다."""
    page_id = notion.get_today_page_id()
    if not page_id:
        return []

    blocks = notion.get_page_blocks(page_id)
    tasks = []
    for block in blocks:
        block_type = block.get("type", "")
        if block_type == "to_do":
            rich_text = block.get("to_do", {}).get("rich_text", [])
            text = "".join(t.get("plain_text", "") for t in rich_text).strip()
            if text:
                tasks.append(text)
        elif block_type == "bulleted_list_item":
            rich_text = block.get("bulleted_list_item", {}).get("rich_text", [])
            text = "".join(t.get("plain_text", "") for t in rich_text).strip()
            if text and text.startswith("[ ]"):
                tasks.append(text[3:].strip())
    return tasks


# ─────────────────────────────────────────────────────────────────────
# 커맨드 핸들러
# ─────────────────────────────────────────────────────────────────────

def handle_start(telegram: TelegramClient, notion: NotionClient, llm: LLMClient, state: dict):
    """
    /start — 노션 오늘 계획 읽기 → 태스크 파싱 → 실행 시작 알림
    """
    today = datetime.date.today().strftime("%Y-%m-%d")
    telegram.send(f"🔍 [{today}] 노션 오늘 계획을 읽고 있습니다...")

    # 노션에서 오늘 페이지 확인
    page_id = notion.get_today_page_id()
    if not page_id:
        telegram.send(
            f"⚠️ 노션에 오늘({today}) 계획 페이지가 없습니다.\n"
            "노션에 오늘 계획을 먼저 작성해주세요."
        )
        return

    tasks = parse_tasks_from_notion(notion)
    week_summary = notion.get_week_summary()

    # 상태 저장
    state["tasks"] = tasks
    state["completed"] = []
    save_state(state)

    # LLM으로 오늘 실행 계획 분석
    week_goal = week_summary.get("weekly_goal", "") if week_summary else ""
    tasks_text = "\n".join(f"- {t}" for t in tasks) if tasks else "(할 일 없음)"

    system_prompt = (
        "당신은 1인 개발자의 생산성 코치입니다.\n"
        "오늘의 할 일 목록을 보고 에이전트가 자율 실행할 수 있는 항목과 "
        "사람이 직접 해야 할 항목을 분류해주세요.\n\n"
        "출력 형식:\n"
        "🤖 에이전트 자율 실행:\n- [항목]\n\n"
        "👤 직접 처리 필요:\n- [항목]\n\n"
        "💡 오늘의 핵심 조언 (1줄):"
    )
    user_prompt = (
        f"오늘 날짜: {today}\n"
        f"주간 목표: {week_goal or '(없음)'}\n\n"
        f"오늘의 할 일:\n{tasks_text}"
    )

    analysis = llm.ask(user_prompt, system_prompt, use_external=True, max_tokens=800)

    msg = (
        f"✅ [{today}] 오늘 계획 확인 완료!\n\n"
        f"📋 할 일 ({len(tasks)}개):\n{tasks_text}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{analysis or '(분석 없음)'}\n\n"
        f"🚀 에이전트 작업 시작합니다!"
    )
    telegram.send_chunked(msg)
    logger.info(f"[Commander] /start 완료 — {len(tasks)}개 태스크 확인")


def handle_status(telegram: TelegramClient, state: dict):
    """
    /status — 현재 진행 상황 리포트
    """
    tasks = state.get("tasks", [])
    completed = state.get("completed", [])
    pending = [t for t in tasks if t not in completed]

    msg = (
        f"📊 현재 진행 상황\n\n"
        f"✅ 완료 ({len(completed)}개):\n"
    )
    for t in completed:
        msg += f"  • {t}\n"
    msg += f"\n⏳ 진행중/대기 ({len(pending)}개):\n"
    for t in pending:
        msg += f"  • {t}\n"

    telegram.send(msg)


def handle_report(telegram: TelegramClient, notion: NotionClient, llm: LLMClient, state: dict):
    """
    /report — 오늘 완료된 작업 즉시 리포트 + 전문가 피드백
    """
    today = datetime.date.today().strftime("%Y-%m-%d")
    telegram.send(f"📝 [{today}] 리포트 생성 중...")

    # Git 커밋 수집
    git_commits = _get_git_commits()
    tasks = state.get("tasks", [])
    completed = state.get("completed", [])
    tasks_text = "\n".join(f"- {t}" for t in tasks) if tasks else "(없음)"
    completed_text = "\n".join(f"- ✅ {t}" for t in completed) if completed else "(없음)"

    system_prompt = (
        "당신은 1인 개발자의 SRE + 프로덕트 매니저 역할의 전문가 코치입니다.\n"
        "오늘 완료된 작업과 Git 커밋을 분석하여 전문적인 피드백을 제공하세요.\n\n"
        "출력 형식:\n"
        "## 📊 오늘의 성과 요약\n"
        "(완료 작업 + 커밋 기반 2-3줄 요약)\n\n"
        "## 🎯 전문가 피드백\n"
        "1. 잘한 점:\n"
        "2. 개선 제안:\n"
        "3. 내일 우선순위:\n\n"
        "## 🤖 에이전트가 처리 가능한 후속 작업:\n"
        "- (자율 실행 가능한 항목 목록)"
    )
    user_prompt = (
        f"오늘 날짜: {today}\n\n"
        f"오늘의 계획:\n{tasks_text}\n\n"
        f"완료된 항목:\n{completed_text}\n\n"
        f"Git 커밋:\n{git_commits[:1500]}"
    )

    feedback = llm.ask(user_prompt, system_prompt, use_external=True, max_tokens=1200)

    msg = (
        f"📋 [{today}] 일일 리포트\n\n"
        f"{feedback or '(리포트 생성 실패)'}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"💬 피드백이 있으면 /feedback [내용] 으로 전송해주세요."
    )
    telegram.send_chunked(msg)

    # 노션에도 리포트 추가
    page_id = notion.get_today_page_id()
    if page_id and feedback:
        notion.append_markdown_to_page(
            page_id,
            f"\n---\n## 🤖 에이전트 리포트 ({today})\n\n{feedback}",
            check_duplicate="에이전트 리포트"
        )

    logger.info("[Commander] /report 완료")


def handle_done(telegram: TelegramClient, notion: NotionClient, llm: LLMClient, state: dict):
    """
    /done — 오늘 마무리 + 최종 리포트 + 내일 준비 항목 제안
    """
    today = datetime.date.today().strftime("%Y-%m-%d")
    telegram.send(f"🌙 [{today}] 오늘 마무리 리포트 생성 중...")

    git_commits = _get_git_commits()
    tasks = state.get("tasks", [])
    completed = state.get("completed", [])
    feedback_log = state.get("feedback_log", [])

    system_prompt = (
        "당신은 1인 개발자의 생산성 코치 겸 SRE 전문가입니다.\n"
        "하루를 마무리하며 오늘 전체를 돌아보고 내일을 준비하는 리포트를 작성하세요.\n\n"
        "출력 형식:\n"
        "## 🌙 오늘 마무리 리포트\n\n"
        "### ✅ 오늘의 성과\n"
        "(2-3줄 핵심 요약)\n\n"
        "### 💡 코치의 총평\n"
        "(전문적이고 솔직한 피드백 2-3줄)\n\n"
        "### 🚀 내일 첫 번째 행동\n"
        "(내일 가장 먼저 해야 할 것 1가지)\n\n"
        "### 🤖 에이전트가 오늘 밤 처리할 것\n"
        "- (야간 자율 실행 항목)"
    )
    tasks_text = "\n".join(f"- {t}" for t in tasks) if tasks else "(없음)"
    completed_text = "\n".join(f"- ✅ {t}" for t in completed) if completed else "(없음)"
    feedback_text = "\n".join(f"- {f}" for f in feedback_log) if feedback_log else "(없음)"

    user_prompt = (
        f"오늘 날짜: {today}\n\n"
        f"계획:\n{tasks_text}\n\n"
        f"완료:\n{completed_text}\n\n"
        f"오늘 내가 준 피드백:\n{feedback_text}\n\n"
        f"Git 커밋:\n{git_commits[:1500]}"
    )

    final_report = llm.ask(user_prompt, system_prompt, use_external=True, max_tokens=1200)

    msg = (
        f"🌙 [{today}] 오늘 완료!\n\n"
        f"{final_report or '(리포트 생성 실패)'}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"수고하셨습니다! 내일도 좋은 하루 되세요 🙏"
    )
    telegram.send_chunked(msg)

    # 노션에 최종 리포트 추가
    page_id = notion.get_today_page_id()
    if page_id and final_report:
        notion.append_markdown_to_page(
            page_id,
            f"\n---\n## 🌙 마무리 리포트 ({today})\n\n{final_report}",
            check_duplicate="마무리 리포트"
        )

    # 상태 초기화 준비 (내일을 위해)
    state["feedback_log"] = []
    save_state(state)
    logger.info("[Commander] /done 완료")


def handle_feedback(telegram: TelegramClient, llm: LLMClient, state: dict, feedback_text: str):
    """
    /feedback [내용] — 피드백 수신 후 작업 조정 및 실행
    """
    if not feedback_text.strip():
        telegram.send("⚠️ 피드백 내용을 입력해주세요.\n예) /feedback 카카오 로그인 먼저 해줘")
        return

    today = datetime.date.today().strftime("%Y-%m-%d")
    telegram.send(f"💬 피드백 수신: '{feedback_text}'\n분석 중...")

    # 피드백 로그에 저장
    state.setdefault("feedback_log", []).append(f"[{today}] {feedback_text}")
    save_state(state)

    tasks = state.get("tasks", [])
    tasks_text = "\n".join(f"- {t}" for t in tasks) if tasks else "(없음)"

    system_prompt = (
        "당신은 개발자의 지시를 받아 즉시 실행 계획을 수립하는 에이전트입니다.\n"
        "피드백을 분석하여 즉시 실행 가능한 것과 사람이 결정해야 할 것을 분리하세요.\n\n"
        "출력 형식:\n"
        "## 📥 피드백 이해\n"
        "(피드백 핵심 1줄 요약)\n\n"
        "## 🤖 즉시 실행 (에이전트):\n"
        "- [실행할 것]\n\n"
        "## 👤 확인 필요 (당신):\n"
        "- [결정이 필요한 것]\n\n"
        "## ⏱ 예상 소요:\n"
        "(몇 분 / 몇 시간)"
    )
    user_prompt = (
        f"현재 태스크 목록:\n{tasks_text}\n\n"
        f"받은 피드백: {feedback_text}"
    )

    action_plan = llm.ask(user_prompt, system_prompt, use_external=True, max_tokens=600)

    msg = (
        f"✅ 피드백 반영 완료\n\n"
        f"{action_plan or '(분석 실패)'}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"🚀 에이전트 실행 시작합니다!"
    )
    telegram.send_chunked(msg)
    logger.info(f"[Commander] /feedback 처리 완료: {feedback_text[:50]}")


# ─────────────────────────────────────────────────────────────────────
# 유틸
# ─────────────────────────────────────────────────────────────────────

def _get_git_commits() -> str:
    """오늘 05:00 이후 git 커밋 목록 반환"""
    try:
        since = datetime.datetime.now().strftime("%Y-%m-%d 05:00:00")
        result = subprocess.run(
            ["git", "-C", str(REPO_PATH), "log", f"--since={since}",
             "--oneline", "--no-merges"],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip() or "(오늘 커밋 없음)"
    except Exception as e:
        logger.error(f"[Git] 커밋 조회 실패: {e}")
        return "(커밋 내역 조회 불가)"


def get_updates(token: str, offset: int = 0) -> list:
    """텔레그램 업데이트 폴링"""
    import requests
    try:
        resp = requests.get(
            f"https://api.telegram.org/bot{token}/getUpdates",
            params={"offset": offset, "timeout": 30},
            timeout=35
        )
        resp.raise_for_status()
        return resp.json().get("result", [])
    except Exception as e:
        logger.error(f"[Telegram] 폴링 실패: {e}")
        return []


# ─────────────────────────────────────────────────────────────────────
# 메인
# ─────────────────────────────────────────────────────────────────────

def process_message(text: str, telegram: TelegramClient,
                    notion: NotionClient, llm: LLMClient, state: dict):
    """메시지를 파싱해 적절한 핸들러 실행"""
    text = text.strip()
    logger.info(f"[Commander] 수신: {text}")

    if text == "/start":
        handle_start(telegram, notion, llm, state)
    elif text == "/status":
        handle_status(telegram, state)
    elif text == "/report":
        handle_report(telegram, notion, llm, state)
    elif text == "/done":
        handle_done(telegram, notion, llm, state)
    elif text.startswith("/feedback"):
        feedback_text = text[len("/feedback"):].strip()
        handle_feedback(telegram, llm, state, feedback_text)
    else:
        telegram.send(
            "🤖 지원 커맨드:\n"
            "/start — 오늘 계획 읽고 시작\n"
            "/status — 진행 상황 확인\n"
            "/report — 즉시 리포트\n"
            "/done — 오늘 마무리\n"
            "/feedback [내용] — 피드백 전달"
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true",
                        help="메시지 한 번만 확인 후 종료 (launchd용)")
    args = parser.parse_args()

    config.load_env()
    telegram = TelegramClient()
    notion   = NotionClient()
    llm      = LLMClient()

    state = load_state()
    state = reset_state_if_new_day(state)

    token = config.require("TELEGRAM_BOT_TOKEN")

    if args.once:
        # launchd 모드: 한 번만 미처리 메시지 처리
        updates = get_updates(token)
        for update in updates:
            msg = update.get("message", {})
            text = msg.get("text", "")
            if text:
                process_message(text, telegram, notion, llm, state)
        return

    # 폴링 모드 (로컬 테스트용)
    logger.info("🤖 Telegram Commander 시작 (폴링 모드)")
    telegram.send("🤖 에이전트 커맨더 온라인입니다!\n/start 로 오늘을 시작하세요.")
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
