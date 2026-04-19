
import sys
import os
import json
from pathlib import Path

# 모듈 경로 추가
_AUTOMATIONS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"
sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.notion_client import NotionClient

def test_nesting():
    print("=== Notion Nesting Limit Test ===")
    
    # 5단계 중첩 마크다운 (Notion API는 2단계까지만 지원)
    nested_md = """
# Heading 1
- Level 1
  - Level 2
    - Level 3 (Should be flattened to Level 2)
      - Level 4 (Should be flattened to Level 2)
        - Level 5
- Back to Level 1
    """.strip()
    
    blocks = NotionClient._markdown_to_blocks(nested_md)
    # print(json.dumps(blocks, indent=2, ensure_ascii=False))
    
    def get_max_depth(blocks, current_depth=0):
        if not blocks:
            return current_depth
        max_d = current_depth
        for b in blocks:
            b_type = b["type"]
            children = b.get(b_type, {}).get("children", [])
            if children:
                max_d = max(max_d, get_max_depth(children, current_depth + 1))
        return max_d

    depth = get_max_depth(blocks)
    print(f"Max Nesting Depth in JSON: {depth}")
    
    if depth <= 2:
        print("✅ SUCCESS: Nesting depth is within limit (Max 2).")
    else:
        print(f"❌ FAILURE: Nesting depth {depth} exceeds limit 2.")

    # 구조 확인
    # Level 1 (index 1 in blocks)
    level1 = blocks[1]
    level2_list = level1["bulleted_list_item"]["children"]
    print(f"Level 1 has {len(level2_list)} children (Level 2).")
    
    level2 = level2_list[0]
    level3_list = level2["bulleted_list_item"].get("children", [])
    print(f"Level 2 has {len(level3_list)} children (Max allowed).")
    
    if len(level3_list) > 0:
        level3 = level3_list[0]
        # Level 3의 children이 없어야 함 (평탄화되어 Level 3 자리에 Level 4 등이 형제로 들어감)
        level4_check = level3["bulleted_list_item"].get("children", [])
        print(f"Level 3 has {len(level4_check)} children (Level 4 check).")
        if not level4_check:
            print("✅ SUCCESS: Level 4 was flattened into Level 3's sibling list (or equivalent).")
        else:
            print("❌ FAILURE: Level 4 still nested under Level 3.")

if __name__ == "__main__":
    test_nesting()
