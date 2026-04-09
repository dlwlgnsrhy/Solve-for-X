#!/usr/bin/env python3
"""
daily_planner/main.py  (v2 — 버그 수정)
=========================================
# 수정사항:
  - `from .notion_client import NotionClient` 상대 import 제거
    → sys.path 방식으로 교체, python main.py 직접 실행과 -m 모듈 실행 모두 지원
  - list[dict] 타입힌트 → List[dict] (Python 3.8 호환)
  - Telegram 미리보기 메시지 길이 안전 처리 추가

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
from typing import List, Optional

# automations/ 디렉토리를 sys.path에 추가 — _shared 모듈 접근
_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient
# 상대 import 제거 — sys.path 방식으로 직접 import
from daily_planner.notion_client import NotionClient

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# 레포 루트: automations/../../../  = Solve-for-X/
REPO_PATH = Path(__file__).parent.parent.parent.parent


def get_roadmap_context() -> str:
    roadmap_path = REPO_PATH / "ROADMAP.md"
    if roadmap_path.exists():
        return roadmap_path.read_text(encoding="utf-8")[:3000]
    return "(ROADMAP.md를 찾을 수 없습니다)"


def generate_plan(
    today_tasks: List[dict],
    roadmap: str,
    llm: LLMClient,
    target_date: str,
    week_summary: Optional[dict] = None,
) -> str:
    today_str = datetime.date.today().strftime("%Y-%m-%d")

    # 오늘 Daily Log 요약 구성
    today_lines = []
    for t in today_tasks:
        condition = t.get("condition", 0)
        one_thing = t.get("one_thing", "")
        tags = ", ".join(t.get("tags", [])) or "없음"
        condition_emoji = "🟢" if condition >= 7 else "🟡" if condition >= 4 else "🔴"

        today_lines.append(
            f"  컨디션: {condition_emoji} {condition}/10\n"
            f"  오늘의 1가지: {one_thing or '(미작성)'}\n"
            f"  태그: {tags}"
        )
    today_summary = "\n".join(today_lines) if today_lines else "(오늘 Daily Log 기록 없음)"

    # 주간 목표 컨텍스트
    week_context = ""
    if week_summary:
        week_context = (
            f"\n=== 이번 주 목표 (Weekly System) ===\n"
            f"주간 목표: {week_summary.get('weekly_goal', '(없음)')}\n"
            f"다음 주 첫 행동: {week_summary.get('next_first_action', '(없음)')}"
        )

    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 생산성 코치입니다.\n"
        "오늘의 컨디션, Daily Log 기록, 주간 목표, ROADMAP Phase를 종합해서\n"
        "내일의 실행 계획 초안을 작성합니다.\n\n"
        "규칙:\n"
        "1. 컨디션이 낮으면(≤4) 내일 계획을 가볍게, 높으면(≥8) 딥 워크 우선 배치\n"
        "2. 오늘의 1가지에서 이어갈 내용이 있으면 내일 첫 блок에 반영\n"
        "3. 주간 목표에서 아직 안 된 것 우선\n"
        "4. 타임블록은 90분~2시간 단위 (울트라디안 리듬 기준)\n"
        "5. 현실적인 양만 계획 — 과부하 금지\n"
        "6. 한국어로 작성 (회고 섹션 제외)\n\n"
        "출력 형식:\n"
        "## 🎯 내일의 핵심 목표\n"
        "1. (가장 중요)\n"
        "2. (두 번째)\n"
        "3. (세 번째)\n\n"
        "## ⏱️ 추천 타임라인\n"
        "| 시간 | 활동 | 유형 |\n"
        "|------|------|------|\n"
        "| 09:00~11:00 | ... | 🔨 Deep Work |\n\n"
        "## 📝 주의사항 & 팁\n"
        "(실행 시 주의점, 선행 조건)"
    )

    user_prompt = (
        f"오늘 날짜: {today_str}\n"
        f"내일 날짜: {target_date}\n\n"
        f"=== 오늘의 Daily Log ===\n{today_summary}\n"
        f"{week_context}\n\n"
        f"=== 프로젝트 로드맵 ===\n{roadmap[:2000]}\n\n"
        f"위 데이터를 바탕으로 내일({target_date})의 실행 계획 초안을 작성하세요."
    )

    logger.info("[Planner] 외부 Gemma 31B로 내일 계획 생성 중...")
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
    logger.info("📋 Daily Planner 시작")

    llm      = LLMClient()
    telegram = TelegramClient()
    notion   = NotionClient()

    tomorrow = (datetime.date.today() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")

    telegram.send("📋 [Daily Planner] 내일의 계획 초안을 생성합니다...")

    # 1. 오늘 Notion Daily Log 읽기
    logger.info("[Planner] 오늘의 Daily Log 읽는 중...")
    today_tasks = notion.get_today_tasks()
    logger.info(f"[Planner] 오늘 기록 {len(today_tasks)}건 발견")

    # 2. 이번 주 Weekly System 읽기 (컨텍스트 보강)
    logger.info("[Planner] 이번 주 Weekly 목표 읽는 중...")
    week_summary = notion.get_week_summary()
    if week_summary:
        logger.info(f"[Planner] 주간 목표: {week_summary.get('weekly_goal', '')[:50]}")
    else:
        logger.info("[Planner] 주간 기록 없음 — Daily Log만으로 계획 생성")

    # 3. ROADMAP 읽기
    roadmap = get_roadmap_context()

    # 4. Gemma 31B로 계획 생성
    plan_md = generate_plan(today_tasks, roadmap, llm, tomorrow, week_summary)

    # 5. Notion에 내일 페이지 작성
    logger.info("[Planner] Notion에 내일 페이지 작성 중...")
    page_url = notion.create_daily_page(tomorrow, plan_md)

    # 6. Telegram 알림
    preview_lines = plan_md.split("\n")[:15]
    preview = "\n".join(preview_lines)
    if len(plan_md.split("\n")) > 15:
        preview += "\n..."

    msg = (
        f"📋 [내일 계획 초안] {tomorrow}\n\n"
        f"{preview}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📝 Notion에 작성되었습니다. 수정 후 내일을 시작하세요!\n"
    )
    if page_url:
        msg += f"🔗 {page_url}"

    telegram.send(msg)
    logger.info("✅ Daily Planner 완료")



if __name__ == "__main__":
    main()
