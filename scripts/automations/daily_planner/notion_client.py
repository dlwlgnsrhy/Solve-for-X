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

# 상대 import 대신 sys.path로 공통 모듈 접근 (실행 방식 무관하게 동작)
sys.path.insert(0, str(Path(__file__).parent.parent))
from _shared import config

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
        Notion Database에 내일 날짜의 새 페이지를 생성하고
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
                    },
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
    def append_markdown_to_page(self, page_id: str, markdown: str) -> bool:
        """기존 Notion 페이지에 마크다운 내용을 블록으로 추가합니다."""
        try:
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

    # ------------------------------------------------------------------
    @staticmethod
    def _markdown_to_blocks(markdown: str) -> list:
        """
        마크다운 텍스트를 Notion 블록 리스트로 변환합니다.
        지원: heading_1/2/3, bulleted_list, numbered_list, divider, paragraph

        제한사항:
          - 테이블(|...|)은 Notion 블록 API와 구조가 달라 paragraph로 처리
          - 중첩 리스트는 단일 레벨로 평탄화
          - 2000자 초과 라인은 앞부분만 사용 (Notion 블록 텍스트 제한)
        """
        blocks = []
        numbered_counter = 0

        for line in markdown.split("\n"):
            stripped = line.strip()

            if not stripped:
                numbered_counter = 0  # 빈 줄에서 번호 리스트 카운터 리셋
                continue

            # Notion rich_text content 최대 2000자 제한
            content = stripped[:2000]

            if stripped.startswith("# "):
                numbered_counter = 0
                blocks.append(_block("heading_1", content[2:]))
            elif stripped.startswith("## "):
                numbered_counter = 0
                blocks.append(_block("heading_2", content[3:]))
            elif stripped.startswith("### "):
                numbered_counter = 0
                blocks.append(_block("heading_3", content[4:]))
            elif stripped == "---":
                numbered_counter = 0
                blocks.append({"object": "block", "type": "divider", "divider": {}})
            elif stripped.startswith("- ") or stripped.startswith("* "):
                numbered_counter = 0
                blocks.append(_block("bulleted_list_item", content[2:]))
            elif len(stripped) >= 3 and stripped[0].isdigit() and stripped[1] in ".)" and stripped[2] == " ":
                # 번호 목록 (1. 또는 1))
                numbered_counter += 1
                blocks.append(_block("numbered_list_item", content[3:]))
            elif stripped.startswith("|"):
                # 마크다운 테이블 → paragraph (Notion 테이블 블록은 별도 API 필요)
                numbered_counter = 0
                if not stripped.startswith("|---"):  # 구분선 제외
                    blocks.append(_block("paragraph", content))
            elif stripped.startswith(">"):
                # 인용문
                numbered_counter = 0
                blocks.append(_block("quote", content.lstrip("> ").strip()))
            elif stripped.startswith("```"):
                # 코드블록 시작/끝 마커는 건너뜀 (인라인 코드만 처리)
                numbered_counter = 0
            else:
                numbered_counter = 0
                blocks.append(_block("paragraph", content))

        return blocks


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
