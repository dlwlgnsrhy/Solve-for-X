#!/usr/bin/env python3
"""
daily_planner/main.py  (v4 — 새 위임 정책 반영)
================================================
핵심 철학 전환:
  [이전] 에이전트가 계획 생성 → 당신이 읽음
  [현재] 당신이 노션에 계획 작성 → 에이전트가 읽고 실행

아침 파이프라인 (07:00):
  당신이 노션에 오늘 계획 작성
  → /start 텔레그램 커맨드 전송
  → 에이전트가 노션 계획 읽기 + 실행 브리핑
  → 텔레그램으로 "작업 시작합니다" 보고

저녁 파이프라인 (18:00):
  에이전트가 오늘 완료 작업 자동 집계
  → 전문가 피드백 + 개선 제안 생성
  → 노션 + 텔레그램으로 리포트 발송
  → 당신이 /feedback 으로 지시하면 즉시 실행
"""

import sys
import logging
import datetime
from pathlib import Path
from typing import List, Optional

_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient
from _shared.notion_client import NotionClient
from _shared.alert_manager import AlertManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

REPO_PATH = Path(__file__).parent.parent.parent.parent


def get_roadmap_context() -> str:
    roadmap_path = REPO_PATH / "ROADMAP.md"
    if roadmap_path.exists():
        return roadmap_path.read_text(encoding="utf-8")[:3000]
    return "(ROADMAP.md를 찾을 수 없습니다)"


def get_delegation_context() -> str:
    """CORE/DELEGATION.md 에서 위임 정책을 읽어옵니다."""
    delegation_path = REPO_PATH / "CORE" / "DELEGATION.md"
    if delegation_path.exists():
        return delegation_path.read_text(encoding="utf-8")[:2000]
    return "(DELEGATION.md 없음)"


def parse_tasks_from_notion_blocks(blocks: list) -> list[str]:
    """노션 블록에서 할 일 항목만 파싱합니다."""
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
            if text.startswith("[ ]"):
                tasks.append(text[3:].strip())
    return tasks


def generate_morning_briefing(
    tasks: list[str],
    week_summary: Optional[dict],
    roadmap: str,
    llm: LLMClient,
    today_str: str,
) -> str:
    """
    [새 철학] 당신이 작성한 노션 계획을 읽고
    에이전트 실행 브리핑 + 전략 조언을 생성합니다.
    계획을 '만들지' 않고 '읽고 분석'합니다.
    """
    tasks_text = "\n".join(f"- {t}" for t in tasks) if tasks else "(할 일 없음 — 노션에 계획을 작성해주세요)"
    week_goal = week_summary.get("weekly_goal", "") if week_summary else ""

    system_prompt = (
        "당신은 1인 개발자의 생산성 코치 겸 에이전트 실행 담당자입니다.\n"
        "추론 과정은 생략하고 결과만 출력하세요.\n"
        "개발자가 직접 작성한 오늘의 계획을 분석하여:\n"
        "1. 에이전트가 자율 실행할 수 있는 항목 분류\n"
        "2. 개발자가 직접 해야 할 항목 분류\n"
        "3. 전략적 조언 1줄\n\n"
        "출력 형식:\n"
        "## 🤖 에이전트 자율 실행:\n"
        "- [항목]\n\n"
        "## 👤 직접 처리 필요:\n"
        "- [항목]\n\n"
        "## 💡 오늘의 핵심 조언 (1줄):\n"
        "> [조언]"
    )
    user_prompt = (
        f"오늘 날짜: {today_str}\n"
        f"주간 목표: {week_goal or '(없음)'}\n\n"
        f"=== 개발자가 작성한 오늘의 계획 ===\n{tasks_text}\n\n"
        f"=== 로드맵 컨텍스트 ===\n{roadmap[:1000]}"
    )

    logger.info("[Planner] 아침 브리핑 생성 중 (노션 계획 분석)...")
    result = llm.ask(user_prompt, system_prompt, use_external=True, max_tokens=800, temperature=0.3)
    if not result:
        result = llm.ask(user_prompt, system_prompt, use_external=False, max_tokens=800, temperature=0.3)
    return result or "(브리핑 생성 실패)"


def get_git_commits_today() -> str:
    """오늘 수행한 git 커밋들을 가져옵니다."""
    import subprocess
    try:
        # 오늘 05:00 이후 커밋
        since_time = datetime.datetime.now().strftime("%Y-%m-%d 05:00:00")
        result = subprocess.run(
            ["git", "-C", str(REPO_PATH), "log", f"--since={since_time}", "--oneline", "--no-merges"],
            capture_output=True, text=True, check=True
        )
        commits = result.stdout.strip()
        return commits if commits else "(오늘의 커밋 없음)"
    except Exception as e:
        logger.error(f"[Git] 커밋 조회 실패: {e}")
        return "(커밋 내역을 가져올 수 없습니다)"





def run_morning_routine(notion: NotionClient, llm: LLMClient, telegram: TelegramClient, today_str: str):
    """
    [새 철학] 아침 루틴:
    - 에이전트가 계획을 만들지 않음
    - 당신이 노션에 작성한 계획을 읽고 실행 브리핑 제공
    - /start 커맨드와 동일한 역할 (자동 실행 버전)
    """
    logger.info("🌅 [아침 루틴] 노션 오늘 계획 읽기 시작")
    telegram.send(f"☀️ [{today_str}] 노션 오늘 계획을 확인합니다...")

    page_id = notion.get_today_page_id()
    if not page_id:
        msg = (
            f"⚠️ [{today_str}] 노션에 오늘 계획 페이지가 없습니다.\n\n"
            f"📝 노션에 오늘 계획을 먼저 작성해주세요.\n"
            f"작성 후 텔레그램에 /start 를 전송하면 에이전트가 시작합니다."
        )
        telegram.send(msg)
        return

    blocks = notion.get_page_blocks(page_id)
    tasks = parse_tasks_from_notion_blocks(blocks)
    week_summary = notion.get_week_summary()
    roadmap = get_roadmap_context()

    briefing = generate_morning_briefing(tasks, week_summary, roadmap, llm, today_str)

    tasks_text = "\n".join(f"  • {t}" for t in tasks) if tasks else "  (할 일 없음)"
    msg = (
        f"☀️ [{today_str}] 오늘 계획 확인 완료!\n\n"
        f"📋 할 일 ({len(tasks)}개):\n{tasks_text}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{briefing}\n\n"
        f"🚀 에이전트 작업 시작합니다!"
    )
    telegram.send_chunked(msg)
    logger.info(f"✅ [아침 루틴] 완료 — {len(tasks)}개 태스크 확인")


def run_evening_routine(notion: NotionClient, llm: LLMClient, telegram: TelegramClient, today_str: str):
    """
    [새 철학] 저녁 루틴:
    - 에이전트가 오늘 완료 작업을 자동 집계 (당신이 기록하지 않음)
    - 전문가 피드백 + 개선 제안 자동 생성
    - 노션 + 텔레그램으로 리포트 발송
    - 당신은 /feedback 으로 지시만 하면 됨
    """
    logger.info("🌆 [저녁 루틴] 에이전트 자동 리포트 생성 시작")
    
    page_id = notion.get_today_page_id()
    if not page_id:
        logger.warning("[Planner] 오늘 날짜의 Notion 페이지를 찾을 수 없습니다. 회고를 추가할 수 없습니다.")
        send_alert(telegram, "🌙 [Daily Planner 저녁 장애]", f"{today_str} 오늘 페이지가 없어 회고를 추가하지 못했습니다.")
        return

    logger.info("[Planner] 오늘 수행한 Git 커밋 조회 중...")
    git_commits = get_git_commits_today()
    logger.info(f"[Git] {len(git_commits.splitlines())}줄의 커밋 발견 (있는 경우)")

    retro_md = generate_evening_retrospective(git_commits, llm, today_str)

    if "(회고 제안 생성 실패" in retro_md:
        logger.error("[Planner] LLM 회고 생성 실패. 알림 발송 후 종료.")
        send_alert(telegram, "🚨 [Daily Planner 저녁 장애]", "LLM(Qwen3.6 35B) 연결 오류로 인해 회고 제안을 생성하지 못했습니다. 네트워크를 확인해주세요.")
        return

    logger.info(f"[Planner] Notion 오늘 페이지({page_id})에 회고 제안 추가 중...")
    
    # 중복 확인을 위해 먼저 블록 목록 체크
    existing_blocks = notion.get_page_blocks(page_id)
    is_duplicate = False
    for b in existing_blocks:
        block_type = b.get("type", "")
        if block_type in b:
            rich_text = b[block_type].get("rich_text", [])
            plain_text = "".join(t.get("plain_text", "") for t in rich_text)
            if "오늘의 작업 요약" in plain_text:
                is_duplicate = True
                break
    
    if is_duplicate:
        logger.info("[Planner] 이미 회고 제안이 추가되어 있습니다. 텔레그램 전송을 생략합니다.")
        return

    success = notion.append_markdown_to_page(page_id, retro_md)
    if not success:
        logger.error("[Planner] Notion 회고 본문 추가 실패. 알림 발송 후 종료.")
        send_alert(telegram, "🚨 [Daily Planner 저녁 장애]", "Notion API 통신 실패로 오늘 생성된 페이지에 회고 내용을 추가하지 못했습니다.")
        return

    preview = "\n".join(retro_md.split("\n")[:15])
    if len(retro_md.split("\n")) > 15:
        preview += "\n..."

    msg = (
        f"🌙 [{today_str}] 에이전트 저녁 리포트\n\n"
        f"{preview}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"💬 피드백이나 추가 지시가 있으면:\n"
        f"/feedback [내용] 으로 전송해주세요.\n"
        f"예) /feedback 카카오 로그인 내일 먼저 해줘\n"
        f"\n/done 으로 오늘을 마무리할 수 있습니다."
    )
    
    telegram.send(msg)
    logger.info(f"✅ Daily Planner (저녁 루틴) 완료")


def send_alert(telegram: Optional[TelegramClient], title: str, message: str):
    """치명적 장애 발생 시 AlertManager를 통해 통합 알림을 발송합니다."""
    AlertManager().send_critical_alert(title, message)


def main():
    try:
        config.load_env()
        logger.info("=" * 50)
        logger.info("📋 Daily Planner 시작")

        llm      = LLMClient()
        telegram = TelegramClient()
        notion   = NotionClient()

        today_str = datetime.date.today().strftime("%Y-%m-%d")
        current_hour = datetime.datetime.now().hour

        if current_hour < 12:
            run_morning_routine(notion, llm, telegram, today_str)
        else:
            run_evening_routine(notion, llm, telegram, today_str)

    except Exception as e:
        err_msg = str(e)[:300]
        logger.error(f"[Planner] 예기치 않은 시스템 치명적 오류 발생:\n{e}", exc_info=True)
        # telegram 객체가 선언되기 전에 에러가 났을 수 있으므로 locals() 확인
        tg_client = locals().get('telegram')
        send_alert(
            tg_client,
            "🚨 [Daily Planner 시스템 장애]",
            f"예기치 않은 치명적 오류가 발생했습니다.\n서버 상태나 코드를 확인해주세요.\n\n요약: {err_msg}"
        )

if __name__ == "__main__":
    main()
