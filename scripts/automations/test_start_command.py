#!/usr/bin/env python3
"""
test_start_command.py
======================
/start 커맨드 전체 파이프라인 테스트

테스트 순서:
  1. Notion 오늘 페이지 존재 확인
  2. 할 일 블록 파싱
  3. LLM 아침 브리핑 생성
  4. 텔레그램 전송 (실제 전송 or 프린트만)

실행:
  python3 test_start_command.py          # 텔레그램 실제 전송
  python3 test_start_command.py --dry    # 텔레그램 전송 없이 출력만
"""

import sys
import argparse
import datetime
from pathlib import Path

# 모듈 경로
_AUTOMATIONS_DIR = str(Path(__file__).parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.notion_client import NotionClient
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient

REPO_PATH = Path(__file__).parent.parent.parent


def section(title: str):
    print(f"\n{'═'*50}")
    print(f"  {title}")
    print('═'*50)


def fetch_all_blocks(notion: NotionClient, block_id: str, depth: int = 0) -> list:
    """블록을 재귀적으로 읽어 자식 블록까지 포함한 전체 리스트 반환"""
    import requests
    blocks = notion.get_page_blocks(block_id)
    result = []
    for block in blocks:
        result.append(block)
        # 자식 블록이 있으면 재귀 탐색 (최대 3단계)
        if block.get("has_children") and depth < 3:
            child_id = block.get("id", "")
            if child_id:
                children = fetch_all_blocks(notion, child_id, depth + 1)
                result.extend(children)
    return result


def parse_tasks_from_blocks(blocks: list) -> list[str]:
    """to_do 블록과 bulleted_list_item([ ]) 에서 태스크 파싱"""
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
            # [ ] 또는 [x] 패턴 처리
            if text.startswith("[ ]"):
                tasks.append(text[3:].strip())
            elif text.startswith("[x]") or text.startswith("[X]"):
                tasks.append(text[3:].strip())
    return tasks


def generate_briefing(tasks: list[str], llm: LLMClient, today_str: str) -> str:
    """daily_planner의 generate_morning_briefing을 직접 호출합니다."""
    # daily_planner 모듈 경로 추가
    import importlib.util
    planner_path = Path(__file__).parent / "daily_planner" / "main.py"
    spec = importlib.util.spec_from_file_location("daily_planner_main", planner_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    roadmap_path = REPO_PATH / "ROADMAP.md"
    roadmap = roadmap_path.read_text(encoding="utf-8")[:1000] if roadmap_path.exists() else ""

    print("  💬 LLM 호출 중 (외부 → 로컬 → simple fallback)...")
    result = mod.generate_morning_briefing(
        tasks=tasks,
        week_summary=None,
        roadmap=roadmap,
        llm=llm,
        today_str=today_str,
    )
    return result



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry", action="store_true", help="텔레그램 전송 없이 출력만")
    args = parser.parse_args()

    config.load_env()
    today_str = datetime.date.today().strftime("%Y-%m-%d")

    print(f"\n🚀 /start 커맨드 파이프라인 테스트")
    print(f"   날짜: {today_str}")
    print(f"   모드: {'DRY RUN (전송 없음)' if args.dry else '실제 전송'}")

    # ── 1. Notion 오늘 페이지 확인 ──
    section("1️⃣  Notion 오늘 페이지 확인")
    notion = NotionClient()
    page_id = notion.get_today_page_id()

    if not page_id:
        print(f"  ❌ 오늘({today_str}) 페이지가 없습니다.")
        print("  👉 노션에 오늘 날짜로 페이지를 먼저 만들어주세요.")
        sys.exit(1)

    print(f"  ✅ 페이지 발견: {page_id}")

    # ── 2. 블록 읽기 & 태스크 파싱 ──
    section("2️⃣  할 일 블록 파싱 (자식 블록 포함 재귀 탐색)")
    all_blocks = fetch_all_blocks(notion, page_id)
    print(f"  총 블록 수 (자식 포함): {len(all_blocks)}개")

    from collections import Counter
    block_types = [b.get("type", "?") for b in all_blocks]
    for btype, cnt in Counter(block_types).items():
        print(f"    - {btype}: {cnt}개")

    tasks = parse_tasks_from_blocks(all_blocks)

    if tasks:
        print(f"\n  ✅ 파싱된 할 일 ({len(tasks)}개):")
        for i, t in enumerate(tasks, 1):
            print(f"    {i}. {t}")
    else:
        print("  ⚠️  파싱된 할 일이 없습니다.")
        print("  👉 노션 페이지에 '할 일' 블록([ ] 체크박스) 형식으로 작성되어 있는지 확인하세요.")

    # ── 3. LLM 브리핑 생성 ──
    section("3️⃣  LLM 아침 브리핑 생성")
    llm = LLMClient()
    briefing = generate_briefing(tasks, llm, today_str)
    print("\n  📋 생성된 브리핑:")
    print("-" * 40)
    print(briefing)
    print("-" * 40)

    # ── 4. 최종 메시지 조합 ──
    section("4️⃣  텔레그램 메시지")
    tasks_text = "\n".join(f"  • {t}" for t in tasks) if tasks else "  (할 일 없음)"
    final_msg = (
        f"☀️ [{today_str}] 오늘 계획 확인 완료!\n\n"
        f"📋 할 일 ({len(tasks)}개):\n{tasks_text}\n\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"{briefing}\n\n"
        f"🚀 에이전트 작업 시작합니다!"
    )
    print(final_msg)

    if not args.dry:
        section("5️⃣  텔레그램 실제 전송")
        telegram = TelegramClient()
        # 4096자 제한으로 분할 전송
        chunk_size = 4000
        for i in range(0, len(final_msg), chunk_size):
            ok = telegram.send(final_msg[i:i+chunk_size])
            print(f"  {'✅ 전송 성공' if ok else '❌ 전송 실패'}")
    else:
        print("\n  ℹ️  DRY RUN — 텔레그램 전송 생략")

    print(f"\n{'═'*50}")
    print("  🎉 테스트 완료!")
    print('═'*50)


if __name__ == "__main__":
    main()
