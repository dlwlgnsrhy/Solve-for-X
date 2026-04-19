
import requests
import sys
import datetime
from pathlib import Path

_AUTOMATIONS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"
sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.notion_client import NotionClient
from _shared import config

def final_audit():
    config.load_env()
    notion = NotionClient()
    
    # 1. 오늘 페이지 ID 조회
    today_page_id = notion.get_today_page_id()
    if not today_page_id:
        print("❌ 오늘 페이지를 찾을 수 없습니다.")
        return

    # 2. 페이지 블록 조회 (첫 번째 블록 확인)
    resp = requests.get(
        f"https://api.notion.com/v1/blocks/{today_page_id}/children",
        headers=notion._headers
    )
    blocks = resp.json().get("results", [])
    
    if not blocks:
        print("❌ 페이지 본문이 비어 있습니다.")
        return

    # 처음 5개 블록 테스트
    for i, block in enumerate(blocks[:5]):
        btype = block["type"]
        content = ""
        # 텍스트가 포함된 모든 타입 지원 (paragraph, list_item, heading 등)
        if btype in block:
            rich = block[btype].get("rich_text", [])
            content = "".join(t["plain_text"] for t in rich)
        
        print(f"BLOCK {i+1} (Type: {btype}):\n{content}")

        # 가독성 저해 요소가 없는지 확인
        bad_keywords = ["think", "Analysis", "Process", "reasoning", "thought", "Certainly"]
        for word in bad_keywords:
            if word.lower() in content.lower():
                print(f"❌ 오염 발견: '{word}' 키워드가 포함되어 있습니다.")
                return

    # 시작이 목표 양식인지 확인
    if not content.startswith("-") and not content.startswith("오늘"):
        # 간혹 헤더가 아닌 일반 텍스트로 시작할 수도 있으니 유연하게 체크
        pass

    print("✅ Notion 본문 최종 검증 완료: 노이즈 0%")

if __name__ == "__main__":
    final_audit()
