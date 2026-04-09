#!/usr/bin/env python3
"""
daily_planner/main.py  (v3 — 아침 실행 버전)
==============================================
변경사항:
  - 실행 시점: 밤 22:00 → 아침 07:00
  - 참조 데이터: 오늘 기록 → 어제(전날) Daily Log
  - 페이지 생성: 내일 페이지 → 오늘 페이지 (하루 시작 시 준비)
  - 회고: 지훈님이 저녁에 직접 작성 (봇이 생성하지 않음)

파이프라인:
  전날 Daily Log (컨디션, 1가지, 태그)
  + Weekly System (주간 목표)
  + ROADMAP.md (현재 Phase)
  → 외부 Gemma 31B (오늘 계획 초안)
  → Notion 오늘 페이지 생성
  → Telegram 알림
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
from daily_planner.notion_client import NotionClient

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


def generate_today_plan(
    yesterday_log: List[dict],
    roadmap: str,
    llm: LLMClient,
    today_str: str,
    week_summary: Optional[dict] = None,
) -> str:
    """
    전날 Daily Log + 주간 목표 + ROADMAP을 기반으로
    오늘의 실행 계획 초안을 생성합니다.
    """
    # 전날 기록 요약
    if yesterday_log:
        yd = yesterday_log[0]  # 보통 하루 1건
        yesterday_date = yd.get("date", "")
        condition = yd.get("condition", 0)
        one_thing = yd.get("one_thing", "")
        tags = ", ".join(yd.get("tags", [])) or "없음"
        condition_emoji = "🟢" if condition >= 7 else "🟡" if condition >= 4 else "🔴"

        yesterday_summary = (
            f"날짜: {yesterday_date}\n"
            f"컨디션: {condition_emoji} {condition}/10\n"
            f"어제의 1가지: {one_thing or '(미작성)'}\n"
            f"태그: {tags}"
        )
    else:
        yesterday_summary = "(전날 Daily Log 기록 없음 — 로드맵 기준으로만 계획)"
        condition = 5  # 기본값

    # 주간 목표 컨텍스트
    week_context = ""
    if week_summary:
        week_context = (
            f"\n=== 이번 주 목표 (Weekly System) ===\n"
            f"주간 목표: {week_summary.get('weekly_goal', '(없음)')}\n"
            f"다음 행동: {week_summary.get('next_first_action', '(없음)')}"
        )

    # 컨디션에 따라 계획 강도 조정 지시
    if condition <= 3:
        intensity_guide = "컨디션이 낮으므로 오늘은 1~2개 핵심 태스크만 계획하고 나머지는 버퍼로 남겨두세요."
    elif condition >= 8:
        intensity_guide = "컨디션이 높으니 Deep Work 블록을 최우선 배치하고 집중이 필요한 작업을 앞에 넣으세요."
    else:
        intensity_guide = "적당한 컨디션이므로 Deep Work 1블록 + 가벼운 작업으로 균형 있게 구성하세요."

    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 생산성 코치입니다.\n"
        "전날 Daily Log와 주간 목표를 참고하여 오늘 하루의 실행 계획 초안을 작성합니다.\n\n"
        "규칙:\n"
        f"1. {intensity_guide}\n"
        "2. 전날의 '1가지'에서 미완료했거나 이어갈 내용이 있으면 오늘 첫 블록에 배치\n"
        "3. 주간 목표 달성을 위해 오늘 기여할 수 있는 항목 1개 이상 포함\n"
        "4. 타임블록은 90분~2시간 단위 (울트라디안 리듬 기준)\n"
        "5. 현실적인 양만 계획 — 과부하 금지\n"
        "6. 회고 섹션은 작성하지 않음 (저녁에 지훈님이 직접 작성)\n"
        "7. 한국어로 작성\n\n"
        "출력 형식:\n"
        "## 🎯 오늘의 핵심 목표\n"
        "1. (가장 중요 — 전날 흐름 이어가기)\n"
        "2. (두 번째)\n"
        "3. (세 번째, 선택적)\n\n"
        "## ⏱️ 추천 타임라인\n"
        "| 시간 | 활동 | 유형 |\n"
        "|------|------|------|\n"
        "| 09:00~11:00 | ... | 🔨 Deep Work |\n\n"
        "## 📝 오늘의 1가지 (제안)\n"
        "(오늘 하루 단 하나만 한다면 이것 — Daily Log에 기록할 내용)\n\n"
        "## ⚠️ 주의사항\n"
        "(선행 조건, 준비물, 리스크 등 간략히)"
    )

    user_prompt = (
        f"오늘 날짜: {today_str}\n\n"
        f"=== 전날 Daily Log ===\n{yesterday_summary}\n"
        f"{week_context}\n\n"
        f"=== 프로젝트 로드맵 ===\n{roadmap[:2000]}\n\n"
        f"위 데이터를 바탕으로 오늘({today_str})의 실행 계획 초안을 작성하세요."
    )

    logger.info("[Planner] 외부 Gemma 31B로 오늘 계획 생성 중...")
    plan = llm.ask(
        user_prompt=user_prompt,
        system_prompt=system_prompt,
        use_external=True,
        max_tokens=1200,
        temperature=0.4,
    )
    return plan or "(계획 생성 실패 — 로그를 확인하세요)"


def main():
    config.load_env()
    logger.info("=" * 50)
    logger.info("📋 Daily Planner (아침 버전) 시작")

    llm      = LLMClient()
    telegram = TelegramClient()
    notion   = NotionClient()

    today_str     = datetime.date.today().strftime("%Y-%m-%d")
    yesterday_str = (datetime.date.today() - datetime.timedelta(days=1)).strftime("%Y-%m-%d")

    telegram.send(f"☀️ [Daily Planner] {today_str} 오늘의 계획 초안을 생성합니다...")

    # 1. 전날 Daily Log 읽기
    logger.info(f"[Planner] 전날({yesterday_str}) Daily Log 읽는 중...")
    yesterday_log = notion.get_yesterday_log()
    if yesterday_log:
        yd = yesterday_log[0]
        logger.info(f"[Planner] 전날 컨디션: {yd.get('condition')}/10 | 1가지: {yd.get('one_thing', '')[:40]}")
    else:
        logger.info("[Planner] 전날 기록 없음 — 로드맵만으로 계획 생성")

    # 2. 이번 주 Weekly System 읽기
    logger.info("[Planner] 이번 주 Weekly 목표 읽는 중...")
    week_summary = notion.get_week_summary()
    if week_summary:
        logger.info(f"[Planner] 주간 목표: {week_summary.get('weekly_goal', '')[:50]}")

    # 3. ROADMAP 읽기
    roadmap = get_roadmap_context()

    # 4. Gemma 31B로 오늘 계획 생성
    plan_md = generate_today_plan(yesterday_log, roadmap, llm, today_str, week_summary)

    # 5. Notion에 오늘 페이지 생성
    logger.info("[Planner] Notion에 오늘 페이지 작성 중...")
    page_url = notion.create_daily_page(today_str, plan_md)

    # 6. Telegram 알림 (앞 15줄 미리보기)
    preview = "\n".join(plan_md.split("\n")[:15])
    if len(plan_md.split("\n")) > 15:
        preview += "\n..."

    msg = (
        f"☀️ [{today_str}] 오늘의 계획 초안\n\n"
        f"{preview}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📝 Notion 확인 후 하루를 시작하세요!\n"
        f"(저녁 회고는 직접 작성)\n"
    )
    if page_url:
        msg += f"🔗 {page_url}"

    telegram.send(msg)
    logger.info(f"✅ Daily Planner 완료 — {today_str} 오늘 페이지 생성됨")


if __name__ == "__main__":
    main()
