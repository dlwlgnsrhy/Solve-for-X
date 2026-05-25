#!/usr/bin/env bash
# =====================================================================
# unicorn_factory/launchd_deployer.sh
# =====================================================================
# 1인 유니콘 무중단 운영 체제 구축을 위한 launchd 데몬 이식 스크립트.
# 현재 터미널의 환경변수를 다이내믹하게 인젝션하여 launchd plist를 
# 생성하고 launchctl 로드를 자동으로 마쳐 무인 상시 기동을 수립합니다.
# =====================================================================

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLIST_LABEL="com.sfx.unicorn"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_LABEL}.plist"
PYTHON_BIN="$(which python3)"
ORCH_SCRIPT="${REPO_ROOT}/scripts/unicorn_factory/factory_orchestrator.py"

# 로그 폴더 생성
LOGS_DIR="${REPO_ROOT}/logs"
mkdir -p "${LOGS_DIR}"

echo "🛰️  [LAUNCHD DEPLOYER]: Processing Launch Agent installation..."

# 환경변수 로딩 및 병합
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$(grep -E "^TELEGRAM_BOT_TOKEN=" "${REPO_ROOT}/scripts/automations/.env.shared" | cut -d'=' -f2- || echo "")}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-$(grep -E "^TELEGRAM_CHAT_ID=" "${REPO_ROOT}/scripts/automations/.env.shared" | cut -d'=' -f2- || echo "")}"
DATABASE_URL="${DATABASE_URL:-$(grep -E "^DATABASE_URL=" "${REPO_ROOT}/scripts/automations/.env" | cut -d'=' -f2- || echo "")}"

if [ -z "${TELEGRAM_BOT_TOKEN}" ]; then
    echo "❌ [DEPLOY ERROR]: TELEGRAM_BOT_TOKEN could not be loaded from current env or env.shared!" >&2
    exit 1
fi

echo "📦 [DEPLOY INFO]: Preserving credentials and writing plist..."

# plist 템플릿 생성 및 주입
cat << EOF > "${PLIST_PATH}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${PYTHON_BIN}</string>
        <string>${ORCH_SCRIPT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOGS_DIR}/unicorn_out.log</string>
    <key>StandardErrorPath</key>
    <string>${LOGS_DIR}/unicorn_err.log</string>
    <key>WorkingDirectory</key>
    <string>${REPO_ROOT}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>TELEGRAM_BOT_TOKEN</key>
        <string>${TELEGRAM_BOT_TOKEN}</string>
        <key>TELEGRAM_CHAT_ID</key>
        <string>${TELEGRAM_CHAT_ID}</string>
        <key>DATABASE_URL</key>
        <string>${DATABASE_URL}</string>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}</string>
    </dict>
</dict>
</plist>
EOF

chmod 644 "${PLIST_PATH}"
echo "✅ [DEPLOY SUCCESS]: Launchd Plist generated at: ${PLIST_PATH}"

# 기존 데몬 언로드 (안전성 조치)
echo "🔄 [DEPLOY INFO]: Unloading existing Agent to perform hot reload..."
launchctl unload "${PLIST_PATH}" 2>/dev/null || true

# 신규 데몬 로드
echo "🚀 [DEPLOY INFO]: Loading and starting background orchestrator agent..."
launchctl load "${PLIST_PATH}"

echo "🎉 [DEPLOY COMPLETE]: The 1-Person Unicorn Software Factory is now permanently running in the background!"
echo "📂 Monitor Logs at:"
echo "   - OUT: tail -f ${LOGS_DIR}/unicorn_out.log"
echo "   - ERR: tail -f ${LOGS_DIR}/unicorn_err.log"

chmod +x "${PLIST_PATH}" || true # plist는 실행권한이 아니라 소유주 권한만 644면 됩니다.

