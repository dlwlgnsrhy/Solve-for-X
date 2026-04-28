#!/usr/bin/env python3
"""
daily_news_curator/main.py
==========================
매일 06:00 실행 — 글로벌 엔지니어링 RSS를 수집하고,
로컬 LLM으로 필터링 후 외부 LLM으로 요약하여 Telegram으로 배달합니다.

파이프라인:
  RSS 수집 → 로컬 Qwen 14B (1차 필터) → 외부 Qwen3.6 35B (요약) → Telegram
"""

import sys
import logging
import datetime
import feedparser
import yaml
from pathlib import Path
from typing import List, Optional

# 공통 모듈 경로 추가
sys.path.insert(0, str(Path(__file__).parent.parent))

from _shared import config
from _shared.llm_client import LLMClient
from _shared.telegram_client import TelegramClient

# ── 설정 ──────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

FEEDS_PATH = Path(__file__).parent / "feeds.yaml"
MAX_ITEMS_PER_FEED = 15       # 피드당 최근 N개 기사만 수집 (기존 10에서 상향)
MAX_ITEMS_TO_SUMMARIZE = 5    # 필터링 후 최대 요약 기사 수
DEFAULT_COLLECT_HOURS = 24    # 평일 기본 수집 범위
WEEKEND_COLLECT_HOURS = 72    # 주말(토/일) 수집 범위 확대 (주중 기사 포함)


# ── 1단계: RSS 수집 ───────────────────────────────────────────
def load_config() -> dict:
    with open(FEEDS_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def fetch_recent_articles(feeds: list) -> List[dict]:
    """모든 RSS 피드에서 요일에 맞춰 최근 N시간 이내 기사를 수집합니다."""
    # 주말(토/일)에는 수집 범위를 넓힘
    is_weekend = datetime.datetime.now().weekday() >= 5
    hours = WEEKEND_COLLECT_HOURS if is_weekend else DEFAULT_COLLECT_HOURS
    
    logger.info(f"[RSS] 수집 범위 설정: {hours}시간 (주말 여부: {is_weekend})")
    cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=hours)
    articles = []

    for feed_cfg in feeds:
        name = feed_cfg.get("name", "Unknown")
        url = feed_cfg.get("url", "")
        try:
            logger.info(f"[RSS] {name} 수집 중...")
            parsed = feedparser.parse(url)
            count = 0
            for entry in parsed.entries[:MAX_ITEMS_PER_FEED]:
                # 발행 시각 파싱 (없으면 현재 시각으로 처리)
                published = entry.get("published_parsed") or entry.get("updated_parsed")
                if published:
                    pub_dt = datetime.datetime(*published[:6], tzinfo=datetime.timezone.utc)
                    if pub_dt < cutoff:
                        continue

                articles.append({
                    "source": name,
                    "title": entry.get("title", ""),
                    "summary": (entry.get("summary", "") or "")[:500],
                    "link": entry.get("link", ""),
                })
                count += 1
            logger.info(f"[RSS] {name}: {count}건 수집")
        except Exception as e:
            logger.warning(f"[RSS] {name} 수집 실패: {e}")

    logger.info(f"[RSS] 총 {len(articles)}건 수집 완료")
    return articles


# ── 2단계: 로컬 LLM 1차 필터링 ───────────────────────────────
def filter_relevant(articles: List[dict], keywords: List[str], client: LLMClient) -> List[dict]:
    """
    로컬 Qwen 14B로 키워드 관련성을 판단합니다.
    빠른 yes/no 판단만 요청하므로 속도 중심 모델을 사용합니다.
    """
    if not articles:
        return []

    keyword_str = ", ".join(keywords)
    relevant = []

    system_prompt = (
        "You are an expert technical news curator for a senior software engineer. "
        "Your goal is to identify high-quality articles about software engineering, "
        "infrastructure, and AI that would interest a professional developer. "
        "Strictly follow the output format."
    )

    for article in articles:
        prompt = (
            f"Keywords: {keyword_str}\n\n"
            f"Title: {article['title']}\n"
            f"Summary: {article['summary'][:300]}\n\n"
            "Question: Is this article relevant to any of the keywords or core software engineering topics?\n"
            "Reply with ONLY 'yes' or 'no'."
        )
        response = client.ask(
            user_prompt=prompt,
            system_prompt=system_prompt,
            use_external=False,  # 로컬 Qwen 14B — 속도 우선
            max_tokens=10,       # 안정성을 위해 10으로 상향
            temperature=0.0,
        )
        
        is_yes = response and "yes" in response.strip().lower()
        if is_yes:
            relevant.append(article)
        
        # 디버그 로그 강화 (나중에 분석 가능하도록)
        logger.info(f"  - [{ 'PASS' if is_yes else 'SKIP' }] {article['title'][:50]}... (Response: {response.strip() if response else 'None'})")

    logger.info(f"[Filter] {len(articles)}건 → {len(relevant)}건 관련 기사 선별")
    return relevant[:MAX_ITEMS_TO_SUMMARIZE]


# ── 3단계: 외부 LLM 고품질 요약 ──────────────────────────────
def summarize_articles(articles: List[dict], client: LLMClient) -> List[dict]:
    """
    외부 Qwen3.6 35B로 각 기사를 3줄 한국어로 요약합니다.
    품질 중심 작업이므로 외부 A100 모델을 사용합니다.
    """
    summarized = []
    for article in articles:
        prompt = (
            f"Article title: {article['title']}\n"
            f"Article content: {article['summary']}\n"
            f"Source: {article['source']}\n\n"
            f"Summarize this article in exactly 2 Korean sentences. "
            f"Focus on: what happened, why it matters to a senior engineer. "
            f"Be concrete and avoid vague language. No bullet points."
        )
        summary = client.ask(
            user_prompt=prompt,
            use_external=True,  # 외부 Qwen3.6 35B — 품질 우선
            max_tokens=150,
            temperature=0.3,
        )
        article["kr_summary"] = summary or "(요약 실패)"
        summarized.append(article)

    return summarized


# ── 4단계: Telegram 배달 ──────────────────────────────────────
def send_briefing(articles: List[dict], fetched_count: int, telegram: TelegramClient) -> None:
    """
    Telegram으로 뉴스 브리핑을 전송합니다.
    주의: parse_mode 없이 plain text로 전송합니다.
          Markdown(*bold* 등) 사용 시 특수문자 이스케이프 문제가 발생하므로
          모든 포맷을 ASCII/유니코드 기호로 처리합니다.
    """
    today = datetime.date.today().strftime("%Y-%m-%d")

    if not articles:
        telegram.send(
            f"📰 [Daily Tech Brief] {today}\n\n"
            f"오늘은 관심 키워드에 해당하는 새 기사가 없습니다.\n"
            f"(총 {fetched_count}건 수집 → 0건 선별)"
        )
        return

    lines = [
        f"📰 Daily Tech Brief — {today}",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━",
    ]

    emoji_map = ["1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣"]
    for i, article in enumerate(articles):
        emoji = emoji_map[i] if i < len(emoji_map) else f"[{i+1}]"
        # 제목에서 Telegram 특수문자 제거 (plain text이므로 불필요하지만 안전 처리)
        title = article['title'].replace("\n", " ").strip()
        lines.extend([
            "",
            f"{emoji} {title}",
            f"    출처: {article['source']}",
            f"    {article['kr_summary']}",
            f"    🔗 {article['link']}",
        ])

    lines.extend([
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━",
        f"수집 {fetched_count}건 → 선별 {len(articles)}건",
        "필터: Qwen 14B (로컬) | 요약: Qwen3.6 35B (외부)",
    ])

    full_message = "\n".join(lines)
    telegram.send_chunked(full_message)
    logger.info(f"[Telegram] 브리핑 전송 완료 ({len(articles)}건)")


# ── 메인 ─────────────────────────────────────────────────────
def main():
    config.load_env()
    logger.info("=" * 50)
    logger.info("📰 Daily News Curator 시작")

    cfg = load_config()
    feeds = cfg.get("feeds", [])
    keywords = cfg.get("keywords", [])

    llm = LLMClient()
    telegram = TelegramClient()

    telegram.send("🚀 [News Curator] 오늘의 기술 브리핑 수집을 시작합니다...")

    # 1. RSS 수집
    articles = fetch_recent_articles(feeds)

    if not articles:
        telegram.send("ℹ️ [News Curator] 최근 24시간 이내 수집된 기사가 없습니다.")
        return

    # 2. 로컬 LLM 필터링
    relevant = filter_relevant(articles, keywords, llm)

    # 3. 외부 LLM 요약
    summarized = summarize_articles(relevant, llm)

    # 4. Telegram 배달
    send_briefing(summarized, len(articles), telegram)

    logger.info("✅ Daily News Curator 완료")


if __name__ == "__main__":
    main()
