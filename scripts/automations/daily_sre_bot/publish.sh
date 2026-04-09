#!/bin/bash
# =============================================================================
# publish.sh — SRE Blog 수동 발행 스크립트
# =============================================================================
# 용도: 초안을 검토하고 마음에 들 때만 이 스크립트를 실행하세요.
#       자동으로 Dev.to에 발행하고 LinkedIn 요약을 Telegram으로 전송합니다.
#
# 사용법: ./publish.sh 2026-04-10
# =============================================================================

set -euo pipefail

TARGET_DATE="${1:-$(date +%Y-%m-%d)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
DRAFT_PATH="$REPO_ROOT/apps/brand-web/src/app/blog/drafts/${TARGET_DATE}-daily-sre-draft.md"
ENV_FILE="$REPO_ROOT/scripts/automations/.env.shared"

echo "=================================================="
echo "📤 SRE Blog 수동 발행 스크립트"
echo "=================================================="
echo "대상 날짜: $TARGET_DATE"
echo "초안 경로: $DRAFT_PATH"

# ── 초안 파일 확인 ──────────────────────────────────────────────
if [ ! -f "$DRAFT_PATH" ]; then
    echo "❌ 초안 파일을 찾을 수 없습니다: $DRAFT_PATH"
    echo "   먼저 SRE Bot을 실행하거나 초안을 작성해주세요."
    exit 1
fi

# ── 환경변수 로드 ────────────────────────────────────────────────
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

# 봇별 .env도 로드 (우선순위 높음)
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# ── 필수 환경변수 확인 ───────────────────────────────────────────
: "${DEV_TO_API_KEY:?DEV_TO_API_KEY가 설정되지 않았습니다. .env.shared를 확인하세요.}"
: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN이 설정되지 않았습니다.}"
: "${TELEGRAM_CHAT_ID:?TELEGRAM_CHAT_ID가 설정되지 않았습니다.}"

# ── 초안 내용 읽기 ──────────────────────────────────────────────
DRAFT_CONTENT=$(cat "$DRAFT_PATH")

# 제목 추출 (frontmatter의 title 필드)
TITLE=$(grep -E '^title:' "$DRAFT_PATH" | head -1 | sed 's/title: *"\(.*\)"/\1/' | sed "s/title: *'\(.*\)'/\1/")
if [ -z "$TITLE" ]; then
    # H1에서 추출
    TITLE=$(grep -E '^# ' "$DRAFT_PATH" | head -1 | sed 's/^# //')
fi

PHASE=$(grep -E '^phase:' "$DRAFT_PATH" | head -1 | sed 's/phase: *"\(.*\)"/\1/' | sed "s/phase: *'\(.*\)'/\1/")

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

# ── Dev.to 발행 ──────────────────────────────────────────────────
echo ""
echo "🌐 Dev.to에 발행 중..."

CANONICAL_URL="https://soluni.com/blog/posts/${TARGET_DATE}-daily-sre-log"

DEVTO_PAYLOAD=$(python3 -c "
import json, sys
content = open('$DRAFT_PATH').read()
payload = {
    'article': {
        'title': '''$TITLE''',
        'body_markdown': content,
        'published': True,
        'canonical_url': '$CANONICAL_URL',
        'tags': ['sre', 'architecture', 'automation']
    }
}
print(json.dumps(payload))
")

DEVTO_RESPONSE=$(curl -s -X POST "https://dev.to/api/articles" \
    -H "api-key: ${DEV_TO_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$DEVTO_PAYLOAD")

DEVTO_URL=$(echo "$DEVTO_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('url', 'URL 없음'))" 2>/dev/null || echo "발행 오류")

echo "✅ Dev.to 발행 완료: $DEVTO_URL"

# ── Telegram 발행 완료 알림 ──────────────────────────────────────
TG_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

MSG="✅ [SRE Blog 발행 완료] ${TARGET_DATE}

📌 제목: ${TITLE}
🎯 Phase: ${PHASE}
🌐 Dev.to: ${DEVTO_URL}
🔗 브랜드 웹: ${CANONICAL_URL}

LinkedIn 요약문을 복사하여 게시하세요!"

curl -s -X POST "$TG_URL" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": $(python3 -c "import json; print(json.dumps('$MSG'))")}" \
    > /dev/null

# ── git commit & push ────────────────────────────────────────────
echo ""
echo "📦 변경사항 커밋 및 push 중..."

git -C "$REPO_ROOT" add "$DRAFT_PATH"
git -C "$REPO_ROOT" commit -m "docs(apps/brand-web): publish [${PHASE}] blog post for ${TARGET_DATE}" || true
git -C "$REPO_ROOT" push || echo "⚠️  push 실패 — 수동으로 push 해주세요."

echo ""
echo "=================================================="
echo "🎉 발행 완료!"
echo "Dev.to: $DEVTO_URL"
echo "=================================================="
