#!/usr/bin/env python3
"""
debug_notion_blocks.py
======================
노션 오늘 페이지의 블록 구조를 상세히 출력합니다.
파서 디버깅용.
"""

import sys
import json
from pathlib import Path

_AUTOMATIONS_DIR = str(Path(__file__).parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.notion_client import NotionClient

config.load_env()
notion = NotionClient()

page_id = notion.get_today_page_id()
if not page_id:
    print("❌ 오늘 페이지 없음")
    sys.exit(1)

print(f"✅ 페이지 ID: {page_id}\n")
blocks = notion.get_page_blocks(page_id)
print(f"총 {len(blocks)}개 블록\n")

for i, block in enumerate(blocks):
    btype = block.get("type", "?")
    data = block.get(btype, {})
    rich_text = data.get("rich_text", [])
    text = "".join(t.get("plain_text", "") for t in rich_text)
    checked = data.get("checked", None)
    print(f"[{i}] type={btype:<25} checked={str(checked):<6} text='{text[:60]}'")
