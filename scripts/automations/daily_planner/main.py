#!/usr/bin/env python3
"""
daily_planner/main.py
======================
매일 22:00 실행 — Notion 일간 템플릿을 읽고,
미완료 태스크 + ROADMAP 우선순위를 기반으로
외부 Gemma 31B가 내일의 계획 초안을 생성합니다.

파이프라인:
  Notion API (오늘 기록 읽기)
  → ROADMAP.md (현재 Phase)
  → 외부 Gemma 31B (내일 계획 초안)
  → Notion API (내일 페이지에 작성)
  → Telegram 알림
"""

import sys
import logging
import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from _shared import config
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient
from .notion_client import NotionClient

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

REPO_PATH = str(Path(__file__).parent.parent.parent.parent)


def get_roadmap_context() -> str:
    roadmap_path = Path(REPO_PATH) / "ROADMAP.md"
    if roadmap_path.exists():
        return roadmap_path.read_text(encoding="utf-8")[:3000]
    return "(ROADMAP.md를 찾을 수 없습니다)"


def generate_plan(
    today_tasks: list[dict],
    roadmap: str,
    llm: LLMClient,
    target_date: str,
) -> str:
    today_str = datetime.date.today().strftime("%Y-%m-%d")
    tomorrow_str = target_date

    incomplete = [t for t in today_tasks if not t.get("done", False)]
    complete = [t for t in today_tasks if t.get("done", False)]

    today_summary = ""
    if complete:
        today_summary += f"완료된 태스크 ({len(complete)}건):\n"
        today_summary += "\n".join(f"  ✅ {t['title']}" for t in complete)
    if incomplete:
        today_summary += f"\n미완료 태스크 ({len(incomplete)}건):\n"
        today_summary += "\n".join(f"  ⬜ {t['title']}" for t in incomplete)

    if not today_summary:
        today_summary = "(오늘 기록된 태스크 없음)"

    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 생산성 코치입니다.\n"
        "목표는 내일의 계획 초안을 작성하는 것입니다.\n\n"
        "규칙:\n"
        "1. 미완료 태스크와 ROADMAP Phase 우선순위를 조합하여 내일의 집중 목표 3개를 선정\n"
        "2. 딥 워크(Deep Work) 블록을 최우선으로 배치 (가장 집중력 높은 오전 시간)\n"
        "3. 각 타임블록은 90분~2시간 단위 (뇌의 ultradian rhythm 고려)\n"
        "4. 현실적으로 달성 가능한 양만 계획 (과부하 금지)\n"
        "5. 한국어로 작성\n\n"
        "출력 형식 (마크다운):\n"
        "## 🎯 내일의 핵심 목표\n"
        "1. (가장 중요한 것)\n"
        "2. (두 번째)\n"
        "3. (세 번째)\n\n"
        "## ⏱️ 추천 타임라인\n"
        "| 시간 | 활동 | 유형 |\n"
        "|------|------|------|\n"
        "| 09:00~11:00 | ... | 🔨 Deep Work |\n"
        "...\n\n"
        "## 📝 메모\n"
        "(계획과 관련된 주의사항이나 팁)"
    )

    user_prompt = (
        f"오늘 날짜: {today_str}\n"
        f"내일 날짜: {tomorrow_str}\n\n"
        f"=== 오늘의 Notion 기록 ===\n{today_summary}\n\n"
        f"=== 프로젝트 로드맵 ===\n{roadmap[:2000]}\n\n"
        f"위 데이터를 바탕으로 내일({tomorrow_str})의 실행 계획 초안을 작성하세요."
    )

    logger.info("[Planner] 외부 Gemma 31B로 내일 계획 생성 중...")
    plan = llm.ask(
        user_prompt=user_prompt,
        system_prompt=system_prompt,
        use_external=True,
        max_tokens=1000,
        temperature=0.4,
    )
    return plan or "(계획 생성 실패)"


def main():
    config.load_env()
    logger.info("=" * 50)
    logger.info("📋 Daily Planner 시작")

    llm = LLMClient()
    telegram = TelegramClient()
    notion = NotionClient()

    tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")

    telegram.send("📋 [Daily Planner] 내일의 계획 초안을 생성합니다...")

    # 1. 오늘 Notion 기록 읽기
    logger.info("[Planner] 오늘의 Notion 일간 기록 읽는 중...")
    today_tasks = notion.get_today_tasks()
    logger.info(f"[Planner] {len(today_tasks)}건의 태스크 발견")

    # 2. ROADMAP 읽기
    roadmap = get_roadmap_context()

    # 3. 계획 생성
    plan_md = generate_plan(today_tasks, roadmap, llm, tomorrow)

    # 4. Notion에 내일 페이지 작성
    logger.info("[Planner] Notion에 내일 페이지 작성 중...")
    page_url = notion.create_daily_page(tomorrow, plan_md)

    # 5. Telegram 알림
    preview = plan_md[:600]
    msg = (
        f"📋 [내일 계획 초안] {tomorrow}\n\n"
        f"{preview}...\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📝 Notion에 작성되었습니다. 수정 후 내일을 시작하세요!\n"
    )
    if page_url and page_url != "URL_NOT_AVAILABLE":
        msg += f"🔗 {page_url}"

    telegram.send(msg)
    logger.info("✅ Daily Planner 완료")


if __name__ == "__main__":
    main()
