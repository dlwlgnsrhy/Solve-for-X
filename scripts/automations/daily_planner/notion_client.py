"""
daily_planner/notion_client.py
================================
Notion API 래퍼 — 토큰/DB ID는 .env.shared에서만 읽습니다.

사전 준비 (지훈님 직접 진행):
  1. https://www.notion.so/my-integrations 에서 Integration 생성
  2. API Key를 .env.shared의 NOTION_API_KEY에 기입
  3. 일간 템플릿 Database의 공유 설정에서 Integration 접근 허용
  4. Database ID를 .env.shared의 NOTION_DAILY_DATABASE_ID에 기입
"""

import logging
import datetime
import requests
from .. _shared import config

logger = logging.getLogger(__name__)

NOTION_API_VERSION = "2022-06-28"
NOTION_BASE_URL = "https://api.notion.com/v1"


class NotionClient:
    def __init__(self):
        config.load_env()
        self._api_key = config.require("NOTION_API_KEY")
        self._daily_db_id = config.require("NOTION_DAILY_DATABASE_ID")
        self._headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Notion-Version": NOTION_API_VERSION,
            "Content-Type": "application/json",
        }

    # ------------------------------------------------------------------
    def get_today_tasks(self) -> list[dict]:
        """
        오늘 날짜의 일간 페이지에서 태스크 목록을 가져옵니다.
        Database 구조: 날짜(Date) 속성 + 체크박스(Checkbox) 속성 가정
        """
        today = datetime.date.today().isoformat()
        try:
            resp = requests.post(
                f"{NOTION_BASE_URL}/databases/{self._daily_db_id}/query",
                headers=self._headers,
                json={
                    "filter": {
                        "property": "Date",
                        "date": {"equals": today},
                    }
                },
                timeout=15,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])

            tasks = []
            for page in results:
                props = page.get("properties", {})
                # 제목 추출 (Name 또는 Title 속성)
                title_prop = props.get("Name") or props.get("Title") or props.get("태스크") or {}
                title_list = title_prop.get("title", [])
                title = "".join(t.get("plain_text", "") for t in title_list)

                # 완료 여부 추출 (Done 또는 완료 체크박스)
                done_prop = props.get("Done") or props.get("완료") or props.get("Checkbox") or {}
                done = done_prop.get("checkbox", False)

                if title:
                    tasks.append({"title": title, "done": done})

            logger.info(f"[Notion] 오늘 태스크 {len(tasks)}건 조회 완료")
            return tasks

        except Exception as e:
            logger.error(f"[Notion] 오늘 태스크 조회 실패: {e}")
            return []

    # ------------------------------------------------------------------
    def create_daily_page(self, date_str: str, plan_markdown: str) -> str:
        """
        Notion Database에 내일 날짜의 새 페이지를 생성하고
        계획 초안을 본문에 작성합니다.
        """
        try:
            # 마크다운을 Notion 블록으로 변환 (간단 변환)
            blocks = self._markdown_to_blocks(plan_markdown)

            payload = {
                "parent": {"database_id": self._daily_db_id},
                "properties": {
                    "Name": {
                        "title": [
                            {"text": {"content": f"📋 {date_str} 일간 계획"}}
                        ]
                    },
                    "Date": {
                        "date": {"start": date_str}
                    },
                },
                "children": blocks,
            }

            resp = requests.post(
                f"{NOTION_BASE_URL}/pages",
                headers=self._headers,
                json=payload,
                timeout=20,
            )
            resp.raise_for_status()
            page_url = resp.json().get("url", "URL_NOT_AVAILABLE")
            logger.info(f"[Notion] 내일 페이지 생성 완료: {page_url}")
            return page_url

        except Exception as e:
            logger.error(f"[Notion] 페이지 생성 실패: {e}")
            return ""

    # ------------------------------------------------------------------
    @staticmethod
    def _markdown_to_blocks(markdown: str) -> list[dict]:
        """
        마크다운 텍스트를 Notion 블록 리스트로 변환합니다.
        (heading2, heading3, paragraph, bulleted_list_item 지원)
        """
        blocks = []
        for line in markdown.split("\n"):
            stripped = line.strip()
            if not stripped:
                continue

            if stripped.startswith("## "):
                blocks.append({
                    "object": "block",
                    "type": "heading_2",
                    "heading_2": {
                        "rich_text": [{"type": "text", "text": {"content": stripped[3:]}}]
                    },
                })
            elif stripped.startswith("### "):
                blocks.append({
                    "object": "block",
                    "type": "heading_3",
                    "heading_3": {
                        "rich_text": [{"type": "text", "text": {"content": stripped[4:]}}]
                    },
                })
            elif stripped.startswith("- ") or stripped.startswith("* "):
                blocks.append({
                    "object": "block",
                    "type": "bulleted_list_item",
                    "bulleted_list_item": {
                        "rich_text": [{"type": "text", "text": {"content": stripped[2:]}}]
                    },
                })
            elif stripped.startswith("|"):
                # 테이블 행은 paragraph로 처리 (Notion 테이블 API는 복잡)
                blocks.append({
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": {
                        "rich_text": [{"type": "text", "text": {"content": stripped}}]
                    },
                })
            else:
                blocks.append({
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": {
                        "rich_text": [{"type": "text", "text": {"content": stripped}}]
                    },
                })

        return blocks[:100]  # Notion API 한 번에 최대 100 블록
