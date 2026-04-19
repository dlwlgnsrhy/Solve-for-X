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
  → 외부 Qwen3.6 35B (오늘 계획 초안)
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
        yd = yesterday_log[0]
        yesterday_date = yd.get("date", "")
        
        # 값이 없거나 예외인 경우 50점(보통)으로 처리
        raw_condition = yd.get("condition")
        try:
            condition = int(raw_condition) if raw_condition is not None else 50
        except ValueError:
            condition = 50
            
        one_thing = yd.get("one_thing", "")
        tags = ", ".join(yd.get("tags", [])) or "없음"
        
        # 100점 만점 기준 이모지
        condition_emoji = "🟢" if condition >= 70 else "🟡" if condition >= 40 else "🔴"

        yesterday_summary = (
            f"날짜: {yesterday_date}\n"
            f"컨디션: {condition_emoji} {condition}/100\n"
            f"어제의 1가지: {one_thing or '(미작성)'}\n"
            f"태그: {tags}"
        )
    else:
        yesterday_summary = "(전날 Daily Log 기록 없음 — 기본 컨디션(50점)으로 계획)"
        condition = 50  # 기본값

    # 컨디션(100점 만점)에 따라 계획 강도 조정 지시
    if condition <= 30:
        intensity_guide = f"컨디션이 낮음({condition}점)이므로 오늘은 1~2개 핵심 태스크만 계획하고 나머지는 버퍼로 남겨두세요."
    elif condition >= 80:
        intensity_guide = f"컨디션이 높음({condition}점)이므로 Deep Work 블록을 최우선 배치하고 집중이 필요한 작업을 앞에 넣으세요."
    else:
        intensity_guide = f"적당한 컨디션({condition}점)이므로 Deep Work 1블록 + 가벼운 작업으로 균형 있게 구성하세요."

    # 주간 목표 컨텍스트
    week_context = ""
    if week_summary:
        week_context = (
            f"\n=== 이번 주 목표 (Weekly System) ===\n"
            f"주간 목표: {week_summary.get('weekly_goal', '(없음)')}\n"
            f"다음 행동: {week_summary.get('next_first_action', '(없음)')}"
        )

    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 스마트한 생산성 코치입니다.\n"
        "어제 기록과 주간 목표를 종합하여 오늘 하루의 실행 계획 초안을 작성합니다.\n\n"
        "규칙:\n"
        f"1. {intensity_guide}\n"
        "2. 전날의 '1가지'에서 미완료했거나 이어갈 내용이 있으면 오늘 첫 블록에 배치\n"
        "3. 주간 목표 달성을 위해 오늘 기여할 수 있는 항목 1개 이상 포함\n"
        "4. 오직 아래 지정된 템플릿 구조와 마크다운 형식만 사용하여 출력하세요. 불필요한 인사말이나 부연 설명은 절대 금지합니다.\n\n"
        "출력 형식 (이 구조를 그대로 복사해서 사용하세요):\n"
        "- 오늘의 할 일 Top 3\n"
        "    - [ ] \n"
        "    - [ ] \n"
        "    - [ ] \n"
        "- 오늘 지키고 싶은 원칙 1가지:\n"
        "- 회고\n"
        "    - 배운 것:\n"
        "    - 감사한 것:\n"
        "    - 개선할 것 1가지:"
    )

    user_prompt = (
        f"오늘 날짜: {today_str}\n\n"
        f"=== 전날 Daily Log ===\n{yesterday_summary}\n"
        f"{week_context}\n\n"
        f"=== 프로젝트 로드맵 ===\n{roadmap[:2000]}\n\n"
        f"위 데이터를 바탕으로 오늘({today_str})의 실행 계획 초안을 작성하세요."
    )

    logger.info(f"[Planner] 외부 Qwen3.6 35B로 오늘 계획 생성 중...")
    plan = None
    try:
        plan = llm.ask(
            user_prompt=user_prompt,
            system_prompt=system_prompt,
            use_external=True,
            max_tokens=1200,
            temperature=0.4,
        )
    except Exception as e:
        logger.error(f"[Planner] 외부 계획 생성 중 예외 발생: {e}")

    if not plan:
        logger.warning("[Planner] 외부 LLM 3회 실패 -> 로컬 Qwen 14B로 Fallback 시도")
        try:
            plan = llm.ask(
                user_prompt=user_prompt,
                system_prompt=system_prompt,
                use_external=False,
                max_tokens=1200,
                temperature=0.4,
            )
            if plan:
                plan += "\n\n> ⚠️ **Fallback Notice**: 외부 파이프라인 (Qwen3.6 35B) 통신 무응답으로 인해, 로컬 서버 (Qwen 14B)로 자동 전환(Fallback)되어 생성된 계획입니다."
        except Exception as e:
            logger.error(f"[Planner] 로컬 계획 생성 중 예외 발생: {e}")

    # 계획 리턴 시 현재 컨디션도 함께 넘김 (이후 Notion 속성 업데이트를 위해)
    return plan or "(계획 생성 실패 — 로그를 확인하세요)", condition


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


def generate_evening_retrospective(
    git_commits: str,
    llm: LLMClient,
    today_str: str,
) -> str:
    """
    오늘의 커밋 등을 바탕으로 저녁 회고 제안을 작성합니다.
    """
    system_prompt = (
        "당신은 1인 개발자 레거시 설계자의 생산성 코치입니다.\n"
        "오늘 진행된 작업 내역(Git 커밋 등)을 보고, 지훈님이 저녁 회고를 쉽게 작성할 수 있도록\n"
        "오늘의 성과 요약과 성찰을 위한 질문을 제공합니다.\n\n"
        "출력 형식:\n"
        "## 🌅 오늘의 작업 요약\n"
        "- (커밋 기반 주요 작업 1~3줄 요약)\n\n"
        "## 💡 코치의 회고 제안 (성찰 질문)\n"
        "1. (잘한 점, 혹은 더 깊이 생각해볼 질문)\n"
        "2. (내일 개선하면 좋을 부분)"
    )

    user_prompt = (
        f"오늘 날짜: {today_str}\n\n"
        f"=== 오늘 작업 내역 (Git Commits) ===\n{git_commits[:2000]}\n\n"
        f"위 데이터를 바탕으로 오늘 하루를 마무리하는 회고 및 성찰 제안을 작성해 주세요."
    )

    logger.info("[Planner] 외부 Qwen3.6 35B로 저녁 회고 제안 생성 중...")
    retro = None
    try:
        retro = llm.ask(
            user_prompt=user_prompt,
            system_prompt=system_prompt,
            use_external=True,
            max_tokens=800,
            temperature=0.4,
        )
    except Exception as e:
        logger.error(f"[Planner] 외부 회고 생성 중 예외 발생: {e}")

    if not retro:
        logger.warning("[Planner] 외부 LLM 3회 실패 -> 로컬 Qwen 14B로 회고 Fallback 시도")
        try:
            retro = llm.ask(
                user_prompt=user_prompt,
                system_prompt=system_prompt,
                use_external=False,
                max_tokens=800,
                temperature=0.4,
            )
            if retro:
                retro += "\n\n> ⚠️ **Fallback Notice**: 외부 파이프라인 무응답으로 인해, 로컬 서버(Qwen 14B)를 사용하여 강제 생성된 회고입니다."
        except Exception as e:
            logger.error(f"[Planner] 로컬 회고 생성 중 예외 발생: {e}")
        
    return retro or "(회고 제안 생성 실패 — 로그를 확인하세요)"


def run_morning_routine(notion: NotionClient, llm: LLMClient, telegram: TelegramClient, today_str: str):
    logger.info("🌅 [아침 루틴] 오늘의 계획 생성 시작")
    
    # 중복 실행 방지
    if notion.get_today_page_id():
        logger.info(f"⏭️ 이미 오늘({today_str})의 계획 페이지가 Notion에 존재합니다. 중복 생성을 막기 위해 종료합니다.")
        return

    telegram.send(f"☀️ [Daily Planner] {today_str} 오늘의 계획 초안을 생성합니다...")

    yesterday_str = (datetime.date.today() - datetime.timedelta(days=1)).strftime("%Y-%m-%d")
    logger.info(f"[Planner] 전날({yesterday_str}) Daily Log 읽는 중...")
    yesterday_log = notion.get_yesterday_log()
    
    if yesterday_log:
        yd = yesterday_log[0]
        logger.info(f"[Planner] 전날 컨디션: {yd.get('condition')}/10 | 1가지: {yd.get('one_thing', '')[:40]}")
    else:
        logger.info("[Planner] 전날 기록 없음 — 로드맵만으로 계획 생성")

    logger.info("[Planner] 이번 주 Weekly 목표 읽는 중...")
    week_summary = notion.get_week_summary()

    roadmap = get_roadmap_context()
    plan_md, condition_score = generate_today_plan(yesterday_log, roadmap, llm, today_str, week_summary)

    if "(계획 생성 실패" in plan_md:
        logger.error("[Planner] LLM 계획 생성 실패. 알림 발송 후 종료.")
        send_alert(telegram, "🚨 [Daily Planner 아침 장애]", "LLM(Qwen3.6 35B) 연결 또는 토큰 오류로 인해 계획 초안을 생성하지 못했습니다. 노트북 상태나 네트워크를 확인해주세요.")
        return

    logger.info(f"[Planner] Notion에 오늘 페이지 작성 중... (점수 기록: {condition_score})")
    
    # 템플릿과 노션_client를 고도화하여 condition_score 를 저장할 수도 있습니다
    # 우선은 기존 포멧 대로 create_daily_page 인자로 넘겨 속성 업데이트를 꾀합니다
    page_url = notion.create_daily_page(today_str, plan_md, condition_score)
    if not page_url:
        logger.error("[Planner] Notion 페이지 생성 실패. 알림 발송 후 종료.")
        send_alert(telegram, "🚨 [Daily Planner 아침 장애]", "Notion API 통신 실패 또는 권한 문제로 인해 페이지를 생성하지 못했습니다.")
        return

    preview = "\n".join(plan_md.split("\n")[:15])
    if len(plan_md.split("\n")) > 15:
        preview += "\n..."

    msg = (
        f"☀️ [{today_str}] 오늘의 계획 초안\n\n"
        f"{preview}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📝 Notion 확인 후 하루를 시작하세요!\n"
    )
    if page_url:
        msg += f"🔗 {page_url}"

    telegram.send(msg)
    logger.info(f"✅ Daily Planner (아침 루틴) 완료")


def run_evening_routine(notion: NotionClient, llm: LLMClient, telegram: TelegramClient, today_str: str):
    logger.info("🌆 [저녁 루틴] 오늘 성과 정리 및 회고 제안 시작")
    
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
        f"🌙 [{today_str}] 저녁 회고 제안\n\n"
        f"{preview}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"📝 Notion 페이지에 추가되었습니다. 직접 회고를 완료해보세요!\n"
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
