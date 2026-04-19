
import sys
import os
import datetime
import requests
from pathlib import Path

# 모듈 경로 추가
_AUTOMATIONS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"
sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.notion_client import NotionClient
from _shared import config

def reset_pages():
    config.load_env()
    notion = NotionClient()
    
    today_str = datetime.date.today().strftime("%Y-%m-%d")
    
    # 1. 일간 페이지 삭제 (Archived)
    today_page_id = notion.get_today_page_id()
    if today_page_id:
        print(f"Archiving daily page: {today_page_id}")
        requests.patch(
            f"https://api.notion.com/v1/pages/{today_page_id}",
            headers=notion._headers,
            json={"archived": True}
        )

    # 2. 주간 페이지 삭제
    # 이번 주 월요일 계산
    today = datetime.date.today()
    monday_date = today - datetime.timedelta(days=today.weekday())
    monday_str = monday_date.strftime("%Y-%m-%d")
    
    weekly_db_id = config.get("NOTION_WEEKLY_DATABASE_ID")
    if weekly_db_id:
        print(f"Checking for weekly page starting: {monday_str}")
        resp = requests.post(
            f"https://api.notion.com/v1/databases/{weekly_db_id}/query",
            headers=notion._headers,
            json={
                "filter": {
                    "property": "Week", # weekly_planner/main.py confirms property name is "Week"
                    "date": {"equals": monday_str}
                }
            }
        )
        if resp.status_code == 200:
            results = resp.json().get("results", [])
            for page in results:
                page_id = page["id"]
                print(f"Archiving weekly page: {page_id}")
                requests.patch(
                    f"https://api.notion.com/v1/pages/{page_id}",
                    headers=notion._headers,
                    json={"archived": True}
                )

    print("✅ Reset complete.")

if __name__ == "__main__":
    reset_pages()
