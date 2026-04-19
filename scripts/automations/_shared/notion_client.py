"""
daily_planner/notion_client.py
================================
Notion API 래퍼 — 토큰/DB ID는 .env.shared에서만 읽습니다.

# 버그 수정 (v2):
  - `from .. _shared import config` 문법 오류 수정
    → sys.path 접근 방식으로 교체 (상대 import 의존성 제거)
  - 속성명 환경변수화 (NOTION_TITLE_PROP, NOTION_DATE_PROP, NOTION_DONE_PROP)
    → 사용자 Notion DB 구조에 맞게 .env.shared에서 재정의 가능

사전 준비 (지훈님 직접 진행):
  1. https://www.notion.so/my-integrations 에서 Integration 생성
  2. API Key를 .env.shared의 NOTION_API_KEY에 기입
  3. 일간 템플릿 Database의 공유 설정에서 Integration 접근 허용
  4. Database ID를 .env.shared의 NOTION_DAILY_DATABASE_ID에 기입
"""

import sys
import logging
import datetime
import requests
from pathlib import Path
from typing import Optional

from . import config

logger = logging.getLogger(__name__)

NOTION_API_VERSION = "2022-06-28"
NOTION_BASE_URL = "https://api.notion.com/v1"


class NotionClient:
    def __init__(self):
        config.load_env()
        self._api_key     = config.require("NOTION_API_KEY")
        self._daily_db_id = config.require("NOTION_DAILY_DATABASE_ID")

        # Notion DB 속성명 — 사용자 환경에 맞게 .env.shared에서 재정의 가능
        self._prop_title = config.get("NOTION_TITLE_PROP", "Name")
        self._prop_date  = config.get("NOTION_DATE_PROP",  "Date")
        self._prop_done  = config.get("NOTION_DONE_PROP",  "Done")

        self._headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Notion-Version": NOTION_API_VERSION,
            "Content-Type": "application/json",
        }

    # ------------------------------------------------------------------
    def get_yesterday_log(self) -> list:
        """
        어제 날짜의 Daily Log 기록을 가져옵니다.
        아침에 실행하여 전날 기록을 바탕으로 오늘 계획을 세우는 용도입니다.

        Daily Log DB 구조:
          - Name      : title
          - Date      : date
          - Condition : number (컨디션 점수 1~10)
          - 오늘의 1가지 : rich_text (전날의 핵심 목표)
          - 태그      : multi_select
        """
        yesterday = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
        try:
            resp = requests.post(
                f"{NOTION_BASE_URL}/databases/{self._daily_db_id}/query",
                headers=self._headers,
                json={
                    "filter": {
                        "property": self._prop_date,
                        "date": {"equals": yesterday},
                    }
                },
                timeout=15,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])

            records = []
            for page in results:
                props = page.get("properties", {})

                title_raw = props.get(self._prop_title, {}).get("title", [])
                title = "".join(t.get("plain_text", "") for t in title_raw)

                condition = props.get("Condition", {}).get("number") or 0

                one_thing_raw = props.get("오늘의 1가지", {}).get("rich_text", [])
                one_thing = "".join(t.get("plain_text", "") for t in one_thing_raw)

                tags_raw = props.get("태그", {}).get("multi_select", [])
                tags = [t.get("name", "") for t in tags_raw]

                records.append({
                    "date": yesterday,
                    "title": title or "(제목 없음)",
                    "condition": condition,
                    "one_thing": one_thing,
                    "tags": tags,
                    "page_url": page.get("url", ""),
                })

            logger.info(f"[Notion] 어제({yesterday}) Daily Log {len(records)}건 조회 완료")
            return records

        except Exception as e:
            logger.error(f"[Notion] 어제 기록 조회 실패: {e}")
            return []

    # ------------------------------------------------------------------
    def get_last_week_logs(self) -> list:
        """
        지난 7일간의 Daily Log 기록을 가져옵니다.
        Weekly Planner에서 한 주간의 요약을 위해 사용합니다.
        """
        today = datetime.date.today()
        # 지난 7일 (월~일)
        start_date = (today - datetime.timedelta(days=7)).isoformat()
        end_date = (today - datetime.timedelta(days=1)).isoformat()
        
        try:
            resp = requests.post(
                f"{NOTION_BASE_URL}/databases/{self._daily_db_id}/query",
                headers=self._headers,
                json={
                    "filter": {
                        "and": [
                            {
                                "property": self._prop_date,
                                "date": {"on_or_after": start_date}
                            },
                            {
                                "property": self._prop_date,
                                "date": {"on_or_before": end_date}
                            }
                        ]
                    },
                    "sorts": [
                        {
                            "property": self._prop_date,
                            "direction": "ascending"
                        }
                    ]
                },
                timeout=15,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])

            records = []
            for page in results:
                props = page.get("properties", {})
                title_raw = props.get(self._prop_title, {}).get("title", [])
                title = "".join(t.get("plain_text", "") for t in title_raw)
                
                date_props = props.get(self._prop_date, {}).get("date", {})
                page_date = date_props.get("start", "") if date_props else ""

                condition = props.get("Condition", {}).get("number") or 0

                one_thing_raw = props.get("오늘의 1가지", {}).get("rich_text", [])
                one_thing = "".join(t.get("plain_text", "") for t in one_thing_raw)

                tags_raw = props.get("태그", {}).get("multi_select", [])
                tags = [t.get("name", "") for t in tags_raw]

                records.append({
                    "date": page_date,
                    "title": title or "(제목 없음)",
                    "condition": condition,
                    "one_thing": one_thing,
                    "tags": tags,
                })

            logger.info(f"[Notion] 지난 주({start_date}~{end_date}) Daily Log {len(records)}건 조회 완료")
            return records

        except Exception as e:
            logger.error(f"[Notion] 지난 주 기록 조회 실패: {e}")
            return []

    # ------------------------------------------------------------------
    def get_today_page_id(self) -> str:
        """오늘 날짜로 생성된 Daily Log 페이지 ID를 반환합니다."""
        today = datetime.date.today().isoformat()
        try:
            resp = requests.post(
                f"{NOTION_BASE_URL}/databases/{self._daily_db_id}/query",
                headers=self._headers,
                json={
                    "filter": {
                        "property": self._prop_date,
                        "date": {"equals": today},
                    }
                },
                timeout=15,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])
            if results:
                return results[0].get("id", "")
            return ""
        except Exception as e:
            logger.error(f"[Notion] 오늘 페이지 조회 실패: {e}")
            return ""

    # ------------------------------------------------------------------
    def get_week_summary(self) -> Optional[dict]:
        """
        이번 주 Weekly System 기록을 가져옵니다.
        LLM이 주간 목표 컨텍스트를 참조할 수 있도록 합니다.

        Weekly System DB 구조:
          - 이름       : title
          - Week       : date (주간 시작일)
          - 주간 목표   : rich_text
          - 잘된 것     : rich_text
          - 개선 1      : rich_text
          - 다음 주 첫 행동 : rich_text
        """
        weekly_db_id = config.get("NOTION_WEEKLY_DATABASE_ID")
        if not weekly_db_id or weekly_db_id.startswith("<"):
            return None

        # 이번 주 월요일 찾기
        today = datetime.date.today()
        monday = today - datetime.timedelta(days=today.weekday())

        try:
            resp = requests.post(
                f"{NOTION_BASE_URL}/databases/{weekly_db_id}/query",
                headers=self._headers,
                json={
                    "filter": {
                        "property": "Week",
                        "date": {"on_or_after": monday.isoformat()},
                    },
                    "page_size": 1,
                },
                timeout=15,
            )
            resp.raise_for_status()
            results = resp.json().get("results", [])
            if not results:
                return None

            page = results[0]
            props = page.get("properties", {})

            def get_text(key):
                return "".join(
                    t.get("plain_text", "")
                    for t in props.get(key, {}).get("rich_text", [])
                )

            title_raw = props.get("이름", {}).get("title", [])
            title = "".join(t.get("plain_text", "") for t in title_raw)

            return {
                "title": title,
                "weekly_goal": get_text("주간 목표"),
                "good_things": get_text("잘된 것 "),
                "improvements": get_text("개선 1"),
                "next_first_action": get_text("다음 주 첫 행동"),
            }

        except Exception as e:
            logger.warning(f"[Notion] 주간 기록 조회 실패 (무시하고 계속): {e}")
            return None


    # ------------------------------------------------------------------
    def create_daily_page(self, date_str: str, plan_markdown: str) -> str:
        """
        Notion Database에 날짜별 새 페이지를 생성하고
        계획 초안을 본문에 작성합니다.
        
        반환값: 생성된 페이지 URL (실패 시 빈 문자열)
        """
        try:
            blocks = self._markdown_to_blocks(plan_markdown)

            payload = {
                "parent": {"database_id": self._daily_db_id},
                "properties": {
                    self._prop_title: {
                        "title": [
                            {"text": {"content": f"📋 {date_str} 일간 계획 (초안)"}}
                        ]
                    },
                    self._prop_date: {
                        "date": {"start": date_str}
                    }
                },
                "children": blocks[:100],  # Notion API: 1회 최대 100 블록
            }

            resp = requests.post(
                f"{NOTION_BASE_URL}/pages",
                headers=self._headers,
                json=payload,
                timeout=20,
            )
            resp.raise_for_status()
            page_data = resp.json()
            page_url = page_data.get("url", "")
            logger.info(f"[Notion] 오늘 페이지 생성 완료: {page_url}")
            return page_url

        except requests.exceptions.HTTPError as e:
            logger.error(f"[Notion] 페이지 생성 HTTP 오류 {e.response.status_code}: {e.response.text[:300]}")
            return ""
        except Exception as e:
            logger.error(f"[Notion] 페이지 생성 실패: {e}")
            return ""

    # ------------------------------------------------------------------
    def create_weekly_page(self, monday_str: str, plan_markdown: str, title_str: str) -> str:
        """
        Notion Weekly Database에 새로운 주간 페이지를 생성하고
        계획 초안을 본문에 작성합니다.
        """
        weekly_db_id = config.get("NOTION_WEEKLY_DATABASE_ID")
        if not weekly_db_id:
            logger.error("[Notion] NOTION_WEEKLY_DATABASE_ID가 설정되지 않았습니다.")
            return ""

        try:
            blocks = self._markdown_to_blocks(plan_markdown)

            payload = {
                "parent": {"database_id": weekly_db_id},
                "properties": {
                    "이름": {
                        "title": [
                            {"text": {"content": title_str}}
                        ]
                    },
                    "Week": {
                        "date": {"start": monday_str}
                    },
                },
                "children": blocks[:100],
            }

            resp = requests.post(
                f"{NOTION_BASE_URL}/pages",
                headers=self._headers,
                json=payload,
                timeout=20,
            )
            resp.raise_for_status()
            page_url = resp.json().get("url", "")
            logger.info(f"[Notion] 주간 페이지 생성 완료: {page_url}")
            return page_url

        except Exception as e:
            logger.error(f"[Notion] 주간 페이지 생성 실패: {e}")
            return ""

    # ------------------------------------------------------------------
    def append_markdown_to_page(self, page_id: str, markdown: str, check_duplicate: Optional[str] = None) -> bool:
        """
        기존 Notion 페이지에 마크다운 내용을 블록으로 추가합니다.
        check_duplicate: 해당 문자열이 이미 페이지 본문에 포함되어 있으면 추가하지 않습니다.
        """
        try:
            if check_duplicate:
                existing_blocks = self.get_page_blocks(page_id)
                for b in existing_blocks:
                    block_type = b.get("type", "")
                    if block_type in b:
                        rich_text = b[block_type].get("rich_text", [])
                        plain_text = "".join(t.get("plain_text", "") for t in rich_text)
                        if check_duplicate in plain_text:
                            logger.info(f"[Notion] 중복 내용 발견('{check_duplicate}'). 추가를 건너뜁니다.")
                            return True

            blocks = self._markdown_to_blocks(markdown)
            if not blocks:
                return True
                
            resp = requests.patch(
                f"{NOTION_BASE_URL}/blocks/{page_id}/children",
                headers=self._headers,
                json={"children": blocks[:100]}, # 최대 100개
                timeout=20,
            )
            resp.raise_for_status()
            logger.info(f"[Notion] 페이지({page_id})에 내용 추가 완료")
            return True
        except requests.exceptions.HTTPError as e:
            logger.error(f"[Notion] 페이지 내용 추가 HTTP 오류 {e.response.status_code}: {e.response.text[:300]}")
            return False
        except Exception as e:
            logger.error(f"[Notion] 페이지 내용 추가 실패: {e}")
            return False

    def get_page_blocks(self, page_id: str) -> list:
        """페이지의 최상위 블록 리스트를 가져옵니다."""
        try:
            resp = requests.get(
                f"{NOTION_BASE_URL}/blocks/{page_id}/children",
                headers=self._headers,
                timeout=15,
            )
            resp.raise_for_status()
            return resp.json().get("results", [])
        except Exception as e:
            logger.error(f"[Notion] 블록 조회 실패: {e}")
            return []

    # ------------------------------------------------------------------
    @staticmethod
    def _markdown_to_blocks(markdown: str) -> list:
        """
        마크다운 텍스트를 Notion 블록 리스트로 변환합니다.
        지원: heading_1/2/3, bulleted_list, numbered_list, to_do, divider, paragraph
        들여쓰기(Indent)에 따라 하위 블록(children)으로 중첩 처리합니다.
        """
        root_blocks = []
        stack = [(-1, root_blocks, None)] # (indent, block_list, parent_block)

        for line in markdown.split("\n"):
            if not line.strip():
                continue

            stripped = line.lstrip()
            indent = len(line) - len(stripped)
            content = stripped[:2000]

            # 블록 타입 판별
            if stripped.startswith("# "):
                block = _block("heading_1", content[2:].strip())
            elif stripped.startswith("## "):
                block = _block("heading_2", content[3:].strip())
            elif stripped.startswith("### "):
                block = _block("heading_3", content[4:].strip())
            elif stripped == "---":
                block = {"object": "block", "type": "divider", "divider": {}}
            elif stripped.startswith("- [ ] "):
                block = _block("to_do", content[6:].strip())
                block["to_do"]["checked"] = False
            elif stripped.startswith("- [x] ") or stripped.startswith("- [X] "):
                block = _block("to_do", content[6:].strip())
                block["to_do"]["checked"] = True
            elif stripped.startswith("- ") or stripped.startswith("* "):
                block = _block("bulleted_list_item", content[2:].strip())
            elif len(stripped) >= 3 and stripped[0].isdigit() and stripped[1] in ".)" and stripped[2] == " ":
                block = _block("numbered_list_item", content[3:].strip())
            elif stripped.startswith(">"):
                block = _block("quote", content.lstrip("> ").strip())
            elif stripped.startswith("|") and not stripped.startswith("|---"):
                block = _block("paragraph", content)
            elif stripped.startswith("```") or stripped.startswith("|---"):
                continue  # ignore fences and table separators
            else:
                block = _block("paragraph", content)

            # 스택을 사용해 들여쓰기 레벨 맞추기
            while len(stack) > 1 and indent <= stack[-1][0]:
                stack.pop()

            # Notion 제약: 단일 요청 시 중첩 깊이 자식(Depth 2)까지만 허용
            # Root(0) -> Level 1 -> Level 2까지만 stack에 추가 허용
            MAX_DEPTH = 3 # stack size 3 (indices 0, 1, 2)
            if len(stack) >= MAX_DEPTH:
                # 더 이상 깊게 들어갈 수 없으므로 현재 레벨의 리스트에 추가
                parent_list = stack[-1][1]
                parent_list.append(block)
            else:
                parent_list = stack[-1][1]
                parent_block = stack[-1][2]
                
                # Notion 제약: heading 등은 children을 가질 수 없는 경우가 있으나
                # list_item과 to_do, paragraph 등은 가능.
                if parent_block and parent_block["type"] not in ["bulleted_list_item", "numbered_list_item", "to_do", "paragraph"]:
                    # 부모가 하위 요소를 가질 수 없는 블록이면 그냥 최상단에 추가
                    root_blocks.append(block)
                    stack = [(-1, root_blocks, None)]
                    stack.append((indent, block.setdefault(block["type"], {}).setdefault("children", []), block))
                else:
                    parent_list.append(block)
                    # 현재 블록을 스택에 추가 (하위 요소를 가질 수 있도록)
                    children_list = block[block["type"]].setdefault("children", []) if block["type"] not in ["divider", "heading_1", "heading_2", "heading_3", "quote", "callout"] else None
                    if children_list is not None:
                        stack.append((indent, children_list, block))

        # 후처리: 빈 children 배열 제거 로직
        def clean_children(blocks):
            for b in blocks:
                t = b.get("type")
                if t and t in b:
                    if "children" in b[t]:
                        if not b[t]["children"]:
                            del b[t]["children"]
                        else:
                            clean_children(b[t]["children"])
        
        clean_children(root_blocks)
        return root_blocks

def _block(block_type: str, text: str) -> dict:
    """Notion 블록 딕셔너리를 생성하는 헬퍼."""
    return {
        "object": "block",
        "type": block_type,
        block_type: {
            "rich_text": [
                {
                    "type": "text",
                    "text": {"content": text[:2000]},
                }
            ]
        },
    }
