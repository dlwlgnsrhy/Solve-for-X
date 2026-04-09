#!/usr/bin/env python3
"""
daily_sre_bot/main.py  (v2 — 리팩토링)
========================================
변경사항:
  - LLM: 로컬 Qwen3 30B (하드코딩) → 외부 Gemma 31B (환경변수 참조)
  - 발행: 자동 Dev.to 업로드 → 초안 저장 + Telegram 검토 요청만
  - 보안: 모든 엔드포인트/토큰 .env 격리
  - 블로그 톤: 실무 중심, 포트폴리오 가치, 구조화된 서사
  - 공통 모듈(_shared) 사용

실제 발행은 publish.sh를 수동으로 실행하세요.
"""

import os
import sys
import subprocess
import datetime
import logging
import re
from pathlib import Path

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

config.load_env()

REPO_PATH = str(Path(__file__).parent.parent.parent.parent)
BLOG_DRAFT_DIR = os.path.join(REPO_PATH, "apps/brand-web/src/app/blog/drafts")


# ── 1. Git 데이터 수집 ────────────────────────────────────────
def get_target_date() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d")


def get_todays_commits() -> list[str]:
    if os.getenv("FORCE_TEST") == "1":
        cmd = ["git", "-C", REPO_PATH, "log", "-n", "3", "--format=%H %B",
               "--", ".", ":!apps/brand-web/src/app/blog"]
    else:
        cmd = ["git", "-C", REPO_PATH, "log", "--since=24 hours ago",
               "--format=%H %B", "--", ".", ":!apps/brand-web/src/app/blog"]

    result = subprocess.run(cmd, capture_output=True, text=True)
    commits = result.stdout.strip().split("\n")
    return [c for c in commits if c.strip()]


def get_git_diff() -> str:
    if os.getenv("FORCE_TEST") == "1":
        cmd = ["git", "-C", REPO_PATH, "log", "-n", "2", "-p",
               "--", ".", ":!apps/brand-web/src/app/blog"]
    else:
        cmd = ["git", "-C", REPO_PATH, "log", "--since=24 hours ago", "-p",
               "--", ".", ":!apps/brand-web/src/app/blog"]

    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout


def get_roadmap_context() -> str:
    main_roadmap = os.path.join(REPO_PATH, "ROADMAP.md")
    macro_roadmap = os.path.join(REPO_PATH, "docs/roadmap/01-macro-blueprint.md")

    context = "### Current Progress (ROADMAP.md) ###\n"
    if os.path.exists(main_roadmap):
        with open(main_roadmap, "r", encoding="utf-8") as f:
            context += f.read()[:2000]

    context += "\n\n### Macro Blueprint ###\n"
    if os.path.exists(macro_roadmap):
        with open(macro_roadmap, "r", encoding="utf-8") as f:
            context += f.read()[:1500]

    return context


# ── 2. Gemma 31B로 고품질 블로그 초안 생성 ────────────────────
def generate_blog_draft(commits: list[str], diff_text: str, target_date: str, llm: LLMClient) -> dict | None:
    roadmap = get_roadmap_context()

    system_prompt = (
        "You are a ghost-writer for a senior SRE/SWE engineer's technical blog.\n"
        "Your goal is to produce articles worth publishing on Medium or Dev.to — "
        "articles that make a hiring manager at Google or Netflix think: "
        "'This person understands systems at a deep level.'\n\n"
        "Strict writing rules:\n"
        "1. Structure: Problem → Approach → Implementation → Lessons Learned\n"
        "2. Focus on WHY decisions were made, not just WHAT was done\n"
        "3. Include concrete code snippets only for the most critical parts (no full dumps)\n"
        "4. Length: 800–1200 words (ideal for Medium)\n"
        "5. Tone: Clear, professional American English. No emojis. No fluff.\n"
        "6. Value: Every paragraph must deliver useful insight, not filler\n\n"
        "Also analyze the roadmap to identify which Phase/milestone this work advances.\n\n"
        "Respond ONLY in this exact format:\n"
        "===PHASE_ANALYSIS===\n"
        "(Brief phase mapping in Korean is OK)\n"
        "===BLOG_TITLE===\n"
        "(Concise, compelling English title — no chapter numbers)\n"
        "===BLOG_CONTENT===\n"
        "(Full English blog post in Markdown)\n"
        "===LINKEDIN_SUMMARY===\n"
        "(3-line English LinkedIn post with relevant emojis)"
    )

    user_prompt = (
        f"### Project Roadmap ###\n{roadmap}\n\n"
        f"### Today's Activity ({target_date}) ###\n\n"
        f"[Commits]\n" + "\n".join(f"- {c}" for c in commits if c.strip()) +
        f"\n\n[Code Diff (first 12,000 chars)]\n{diff_text[:12000]}\n\n"
        f"Write a high-quality blog post based on the above data."
    )

    logger.info("[SRE Bot] 외부 Gemma 31B로 블로그 초안 생성 중...")
    raw = llm.ask(
        user_prompt=user_prompt,
        system_prompt=system_prompt,
        use_external=True,   # 외부 Gemma 31B — 품질 우선
        max_tokens=3000,
        temperature=0.3,
    )

    if not raw:
        logger.error("[SRE Bot] LLM 응답 없음")
        return None

    # 파싱
    if "===BLOG_TITLE===" not in raw or "===BLOG_CONTENT===" not in raw:
        logger.error("[SRE Bot] 응답 형식이 맞지 않습니다.")
        return None

    try:
        parts1 = raw.split("===BLOG_TITLE===")
        phase_analysis = parts1[0].replace("===PHASE_ANALYSIS===", "").strip()

        parts2 = parts1[1].split("===BLOG_CONTENT===")
        blog_title = parts2[0].strip().strip('"').strip("'")

        parts3 = parts2[1].split("===LINKEDIN_SUMMARY===")
        blog_body = parts3[0].strip()
        linkedin = parts3[1].strip() if len(parts3) > 1 else ""

        phase_match = re.search(r"Phase\s*\d+(\.\d+)?", phase_analysis, re.IGNORECASE)
        assigned_phase = phase_match.group(0).capitalize() if phase_match else "Phase General"

        frontmatter = (
            f"---\n"
            f'title: "{blog_title}"\n'
            f'phase: "{assigned_phase}"\n'
            f'date: "{target_date}"\n'
            f'tags: ["sre", "architecture", "automation"]\n'
            f"published: false\n"
            f"---\n\n"
        )

        final_blog = (
            f"{frontmatter}"
            f"# {blog_title}\n\n"
            f"{blog_body}\n\n"
            f"---\n"
            f"> **Phase Mapping:** {phase_analysis}"
        )

        return {
            "title": blog_title,
            "blog": final_blog,
            "linkedin": linkedin,
            "phase": assigned_phase,
        }
    except Exception as e:
        logger.error(f"[SRE Bot] 파싱 오류: {e}")
        return None


# ── 3. 초안 저장 ─────────────────────────────────────────────
def save_draft(blog_markdown: str, target_date: str, phase: str) -> str:
    os.makedirs(BLOG_DRAFT_DIR, exist_ok=True)
    filename = f"{target_date}-daily-sre-draft.md"
    filepath = os.path.join(BLOG_DRAFT_DIR, filename)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(blog_markdown)

    # git add + commit (draft 저장만, push 안 함)
    subprocess.run(["git", "-C", REPO_PATH, "add", filepath])
    commit_msg = f"docs(apps/brand-web): save [{phase}] blog draft for {target_date}"
    subprocess.run(["git", "-C", REPO_PATH, "commit", "-m", commit_msg])

    logger.info(f"[SRE Bot] 초안 저장 완료: {filepath}")
    return filepath


# ── 4. Telegram 검토 요청 알림 ───────────────────────────────
def send_review_request(
    title: str,
    blog_markdown: str,
    linkedin: str,
    filepath: str,
    phase: str,
    target_date: str,
    telegram: TelegramClient,
) -> None:
    # 초안 미리보기 (처음 400자)
    preview = blog_markdown.split("---\n\n", 1)[-1][:400].strip()
    relative_path = filepath.replace(REPO_PATH + "/", "")

    msg1 = (
        f"📝 [SRE Blog Draft Ready] {target_date}\n\n"
        f"🎯 Phase: {phase}\n"
        f"📌 제목: {title}\n\n"
        f"━━━ 초안 미리보기 ━━━\n"
        f"{preview}...\n"
        f"━━━━━━━━━━━━━━━━━━━\n\n"
        f"📁 위치: {relative_path}\n\n"
        f"⚡ 다음 액션:\n"
        f"• 수정: 파일을 직접 편집\n"
        f"• 발행: ./scripts/automations/daily_sre_bot/publish.sh {target_date}"
    )
    telegram.send(msg1)

    if linkedin:
        msg2 = (
            f"🟦 [LinkedIn 초안 — 검토 후 사용]\n\n"
            f"{linkedin}"
        )
        telegram.send(msg2)


# ── 메인 ─────────────────────────────────────────────────────
def main():
    logger.info("=" * 50)
    logger.info("🚀 SRE Blog Bot v2 시작")

    llm = LLMClient()
    telegram = TelegramClient()

    telegram.send("🚀 [SRE Bot] 오늘의 기술 회고 초안 생성을 시작합니다...")

    target_date = get_target_date()
    commits = get_todays_commits()

    if not commits:
        msg = "ℹ️ [SRE Bot] 최근 24시간 커밋이 없습니다. 초안 생성을 건너뜁니다."
        logger.info(msg)
        telegram.send(msg)
        return

    logger.info(f"[SRE Bot] {len(commits)}건의 커밋 발견")
    diff_text = get_git_diff()

    content = generate_blog_draft(commits, diff_text, target_date, llm)

    if not content:
        msg = "❌ [SRE Bot] 블로그 초안 생성 실패. 로그를 확인해주세요."
        logger.error(msg)
        telegram.send(msg)
        return

    filepath = save_draft(content["blog"], target_date, content["phase"])

    send_review_request(
        title=content["title"],
        blog_markdown=content["blog"],
        linkedin=content["linkedin"],
        filepath=filepath,
        phase=content["phase"],
        target_date=target_date,
        telegram=telegram,
    )

    logger.info("✅ SRE Bot 완료 — 초안을 검토하고 만족하면 publish.sh를 실행하세요.")


if __name__ == "__main__":
    main()
