#!/usr/bin/env python3
"""
weekly_planner/main.py
==============================================
실행 시점: 매주 월요일 아침 04:30
참조 데이터: 지난주 Daily Log 전체 (추후 연동)
페이지 생성: Notion Weekly System 페이지 생성
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

def generate_weekly_plan(
    last_week_logs: List[dict],
    llm: LLMClient,
    monday_str: str,
) -> str:
    """
    지난 주 Daily Log 종합본을 바탕으로 이번 주 계획 초안 작성
    """
    log_summary = "=== 지난 주 Daily Logs ===\n"
    if not last_week_logs:
        log_summary += "(기록 없음)\n"
    else:
        for log in last_week_logs:
            d = log.get("date", "")
            c = log.get("condition", 0)
            t = log.get("one_thing", "")
            log_summary += f"- {d} | 컨디션:{c}/10 | 1가지:{t}\n"

    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 주간 생산성 코치입니다.\n"
        "추론 과정(Thinking process)은 최대한 짧게 핵심만 하세요.\n"
        "지난 주의 일일 기록을 참고하여 이번 주의 전략과 계획을 제안합니다.\n\n"
        "출력 구조:\n"
        "1. ## 📊 Last Week Intelligence (지난주 데이터 브리핑)\n"
        "   - 지난 7일간의 컨디션 추이, 1가지 성취율, 커밋 활동성 등을 데이터 기반으로 요약 브리핑\n"
        "2. ## 🎯 Strategy Proposals (이번 주 전략 제안)\n"
        "   - 로드맵과 지난주 성과를 고려한 3가지 경로(Option A/B/C) 제안\n"
        "3. ## 📝 Weekly System (지훈님의 최종 확정본)\n"
        "   - 아래 템플릿 구조를 출력하되, [주간 리뷰] 섹션은 지난주 데이터를 기반으로 AI가 미리 초안을 작성해두세요.\n\n"
        "규칙:\n"
        "1. 오직 지정된 구조와 마크다운 형식만 사용하여 출력하세요. 불필요한 사족은 금지합니다.\n\n"
        "템플릿 구조:\n"
        "### 이번 주 계획\n"
        "- 이번 주 핵심 목표 3가지\n"
        "    - [ ]  \n"
        "--- \n"
        "### 이번 주 루틴 (체크리스트)\n"
        "- [ ] 운동\n"
        "--- \n"
        "### 주간 리뷰\n"
        "- 잘된 것 3가지: (AI가 지난주 데이터 기반으로 미리 제안)\n"
        "- 아쉬운 것 1가지: (AI 제안)\n"
        "- 다음 주에 바꿀 것 1가지: (AI 제안)\n"
    )

    user_prompt = (
        f"이번 주 월요일 날짜: {monday_str}\n\n"
        f"{log_summary}\n\n"
        f"위 데이터를 바탕으로 이번 주({monday_str} 시작)의 주간 계획 초안을 작성하세요."
    )

    logger.info(f"[WeeklyPlanner] 외부 LLM(Qwen3.6 27B)으로 주간 계획 생성 중...")
    try:
        plan = llm.ask(
            user_prompt=user_prompt,
            system_prompt=system_prompt,
            use_external=True,
            max_tokens=3500,
            temperature=0.4,
        )
    except Exception as e:
        logger.error(f"[WeeklyPlanner] 계획 생성 중 예외 발생: {e}")
        plan = None
        
    return plan or "(주간 계획 생성 실패 — 로그를 확인하세요)"

def send_alert(title: str, message: str):
    """치명적 장애 발생 시 AlertManager를 통해 통합 알림을 발송합니다."""
    AlertManager().send_critical_alert(title, message)

def main():
    try:
        config.load_env()
        logger.info("=" * 50)
        logger.info("📅 Weekly Planner (주간 계획 생성기) 시작")

        llm      = LLMClient()
        telegram = TelegramClient()
        notion   = NotionClient()

        today = datetime.date.today()
        monday_date = today - datetime.timedelta(days=today.weekday())
        monday_str = monday_date.strftime("%Y-%m-%d")
        
        # 달력 기준 주차 계산 (매월 1일이 포함된 주를 1주차로 계산)
        first_day = monday_date.replace(day=1)
        week_num = (monday_date.day + first_day.weekday() - 1) // 7 + 1
        page_title = f"{monday_date.month}월 {week_num}주차"

        logger.info(f"🌅 이번 주 계획 생성 시작 ({page_title})")
        telegram.send(f"📅 [Weekly Planner] '{page_title}' 주간 계획 초안을 생성합니다...")

        logger.info("[WeeklyPlanner] 지난 주 Daily Log 데이터 조회 중...")
        last_week_logs = notion.get_last_week_logs()

        plan_md = generate_weekly_plan(last_week_logs, llm, monday_str)

        if "(주간 계획 생성 실패" in plan_md:
            logger.error("[WeeklyPlanner] LLM 계획 생성 실패. 알림 발송 후 종료.")
            send_alert("🚨 [Weekly Planner 에러]", "LLM(Qwen3.6 27B) 연결 실패로 주간 문서 초안을 생성하지 못했습니다.")
            return

        logger.info(f"[WeeklyPlanner] Notion에 '{page_title}' 주간 페이지 작성 중...")
        page_url = notion.create_weekly_page(monday_str, plan_md, page_title)
        if not page_url:
            logger.error("[WeeklyPlanner] Notion 주간 페이지 생성 실패. 알림 발송 후 종료.")
            send_alert("🚨 [Weekly Planner 에러]", "Notion API 통신 실패 또는 권한 문제로 인해 주간 페이지를 생성하지 못했습니다.")
            return

        msg = (
            f"📅 [{monday_str}] 이번 주 계획 초안 생성 완료\n\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"📝 Notion 확인 후 멋진 한 주를 시작하세요!\n"
            f"🔗 {page_url}"
        )
        telegram.send(msg)
        logger.info(f"✅ Weekly Planner 루틴 완료")

    except Exception as e:
        err_msg = str(e)[:300]
        logger.error(f"[WeeklyPlanner] 예기치 않은 시스템 치명적 오류 발생:\n{e}", exc_info=True)
        send_alert(
            "🚨 [Weekly Planner 시스템 장애]",
            f"예기치 않은 치명적 오류가 발생했습니다.\n서버 상태나 코드를 확인해주세요.\n\n요약: {err_msg}"
        )

if __name__ == "__main__":
    main()
