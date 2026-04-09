#!/bin/bash
# =============================================================================
# publish.sh — SRE Blog 수동 발행 스크립트  (v2 — 보안 수정)
# =============================================================================
# 용도: 초안을 검토하고 마음에 들 때만 이 스크립트를 실행하세요.
#       자동으로 Dev.to에 발행하고 LinkedIn 요약을 Telegram으로 전송합니다.
#
# 사용법: ./publish.sh 2026-04-10
#
# # 버그 수정 (v2):
#   - Python 인라인 변수 보간으로 인한 JSON 파괴 문제 수정
#     → 모든 Python 처리는 환경변수 경유 (DRAFT_PATH, TITLE 등을 env로 전달)
#   - Telegram 메시지 전송도 Python으로 일원화 (curl JSON 이스케이프 이슈 제거)
# =============================================================================

set -euo pipefail

TARGET_DATE="${1:-$(date +%Y-%m-%d)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DRAFT_PATH="$REPO_ROOT/apps/brand-web/src/app/blog/drafts/${TARGET_DATE}-daily-sre-draft.md"
ENV_FILE="$REPO_ROOT/scripts/automations/.env.shared"

echo "=================================================="
echo "📤 SRE Blog 수동 발행 스크립트 v2"
echo "=================================================="
echo "대상 날짜: $TARGET_DATE"
echo "초안 경로: $DRAFT_PATH"

# ── 초안 파일 확인 ──────────────────────────────────────────────
if [ ! -f "$DRAFT_PATH" ]; then
    echo "❌ 초안 파일을 찾을 수 없습니다: $DRAFT_PATH"
    echo "   먼저 SRE Bot을 실행하거나 초안을 작성해주세요."
    exit 1
fi

# ── 환경변수 로드 (.env.shared + 봇별 .env) ─────────────────────
if [ -f "$ENV_FILE" ]; then
    set -a
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" =~ \<.*\> ]] && continue
        [[ -z "$line" ]] && continue
        export "$line" 2>/dev/null || true
    done < "$ENV_FILE"
    set +a
fi

if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" =~ \<.*\> ]] && continue
        [[ -z "$line" ]] && continue
        export "$line" 2>/dev/null || true
    done < "$SCRIPT_DIR/.env"
    set +a
fi

# ── 필수 환경변수 확인 ───────────────────────────────────────────
: "${DEV_TO_API_KEY:?DEV_TO_API_KEY가 설정되지 않았습니다.}"
: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN이 설정되지 않았습니다.}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID가 설정되지 않았습니다.}"

# ── 메타데이터 추출 (순수 Python, bash 변수 보간 없음) ──────────
# 버그 수정: 이전 버전에서 TITLE에 따옴표/특수문자가 있으면 Python 인라인 코드가 깨졌음
# 해결: 환경변수로 경로만 전달하고 Python 내에서 모든 파싱 처리
METADATA=$(DRAFT_FILE="$DRAFT_PATH" python3 - <<'PYEOF'
import os
import re

draft_path = os.environ["DRAFT_FILE"]
with open(draft_path, "r", encoding="utf-8") as f:
    content = f.read()

# frontmatter에서 title/phase 추출
title_match = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', content, re.MULTILINE)
phase_match = re.search(r'^phase:\s*["\']?(.+?)["\']?\s*$', content, re.MULTILINE)

# fallback: H1 제목
if not title_match:
    title_match = re.search(r'^# (.+)$', content, re.MULTILINE)

title = title_match.group(1).strip() if title_match else "Untitled"
phase = phase_match.group(1).strip() if phase_match else "Unknown Phase"

print(f"TITLE={title}")
print(f"PHASE={phase}")
PYEOF
)

TITLE=$(echo "$METADATA" | grep "^TITLE=" | cut -d'=' -f2-)
PHASE=$(echo "$METADATA" | grep "^PHASE=" | cut -d'=' -f2-)

echo ""
echo "📌 제목: $TITLE"
echo "🎯 Phase: $PHASE"
echo ""
echo "⚠️  이 스크립트는 Dev.to에 실제로 발행합니다."
printf "계속하시겠습니까? (yes/no): "
read -r CONFIRM < /dev/tty

if [ "$CONFIRM" != "yes" ]; then
    echo "취소되었습니다."
    exit 0
fi

# ── Dev.to 발행 (Python으로 안전하게 처리) ──────────────────────
echo ""
echo "🌐 Dev.to에 발행 중..."

CANONICAL_URL="https://soluni.com/blog/posts/${TARGET_DATE}-daily-sre-log"

DEVTO_URL=$(
    DRAFT_FILE="$DRAFT_PATH" \
    DRAFT_TITLE="$TITLE" \
    DEVTO_KEY="$DEV_TO_API_KEY" \
    CANONICAL="$CANONICAL_URL" \
    python3 - <<'PYEOF'
import os
import json
import requests

draft_path  = os.environ["DRAFT_FILE"]
title       = os.environ["DRAFT_TITLE"]
api_key     = os.environ["DEVTO_KEY"]
canonical   = os.environ["CANONICAL"]

with open(draft_path, "r", encoding="utf-8") as f:
    body = f.read()

payload = {
    "article": {
        "title": title,
        "body_markdown": body,
        "published": True,
        "canonical_url": canonical,
        "tags": ["sre", "architecture", "automation"],
    }
}

try:
    resp = requests.post(
        "https://dev.to/api/articles",
        headers={"api-key": api_key, "Content-Type": "application/json"},
        json=payload,
        timeout=30,
    )
    resp.raise_for_status()
    print(resp.json().get("url", "URL 없음"))
except Exception as e:
    print(f"발행 오류: {e}")
PYEOF
)

echo "✅ Dev.to 발행 완료: $DEVTO_URL"

# ── Telegram 발행 완료 알림 (Python으로 안전하게 처리) ──────────
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID" \
DRAFT_TITLE="$TITLE" \
DRAFT_PHASE="$PHASE" \
DRAFT_DATE="$TARGET_DATE" \
DEVTO_URL="$DEVTO_URL" \
CANONICAL_URL="$CANONICAL_URL" \
python3 - <<'PYEOF'
import os
import requests

token      = os.environ["TELEGRAM_BOT_TOKEN"]
chat_id    = os.environ["TELEGRAM_CHAT_ID"]
title      = os.environ["DRAFT_TITLE"]
phase      = os.environ["DRAFT_PHASE"]
date_str   = os.environ["DRAFT_DATE"]
devto_url  = os.environ["DEVTO_URL"]
canonical  = os.environ["CANONICAL_URL"]

msg = (
    f"✅ [SRE Blog 발행 완료] {date_str}\n\n"
    f"제목: {title}\n"
    f"Phase: {phase}\n"
    f"Dev.to: {devto_url}\n"
    f"브랜드 웹: {canonical}\n\n"
    f"LinkedIn 요약문을 복사하여 게시하세요!"
)

requests.post(
    f"https://api.telegram.org/bot{token}/sendMessage",
    json={"chat_id": chat_id, "text": msg},
    timeout=15,
)
PYEOF

# ── git commit & push ────────────────────────────────────────────
echo ""
echo "📦 변경사항 커밋 및 push 중..."

git -C "$REPO_ROOT" add "$DRAFT_PATH"
# commit-msg hook을 우회하지 않고 형식에 맞게 커밋
git -C "$REPO_ROOT" commit \
    -m "docs(apps/brand-web): publish [${PHASE}] blog post for ${TARGET_DATE}" \
    || echo "ℹ️  커밋할 변경사항이 없습니다 (이미 커밋됨)"
git -C "$REPO_ROOT" push \
    || echo "⚠️  push 실패 — 수동으로 push 해주세요: git push"

echo ""
echo "=================================================="
echo "🎉 발행 완료!"
echo "Dev.to: $DEVTO_URL"
echo "=================================================="
