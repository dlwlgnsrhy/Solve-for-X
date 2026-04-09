#!/bin/bash
# =============================================================================
# Daily Planner — launchd 등록 스크립트 (매일 22:00)
# =============================================================================

echo "=================================================="
echo "📋 Daily Planner Launchd 등록 스크립트"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.dailyplanner.plist"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"

# 가상환경 생성
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 가상환경 생성 및 패키지 설치 중..."
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install -r "$SCRIPT_DIR/requirements.txt" -q
    echo "✅ 패키지 설치 완료"
fi

echo "1. launchd plist 파일 생성 중..."

cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.soluni.dailyplanner</string>

    <key>ProgramArguments</key>
    <array>
        <string>${VENV_PYTHON}</string>
        <string>-m</string>
        <string>daily_planner.main</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}/..</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>LANG</key>
        <string>ko_KR.UTF-8</string>
    </dict>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>22</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardErrorPath</key>
    <string>/tmp/soluni_daily_planner.err</string>

    <key>StandardOutPath</key>
    <string>/tmp/soluni_daily_planner.out</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ 파일 생성: $PLIST_FILE"
echo "2. launchctl에 등록 중..."

launchctl unload "$PLIST_FILE" 2>/dev/null
launchctl load "$PLIST_FILE"

echo "--------------------------------------------------"
echo "🎉 등록 완료! 매일 22:00에 내일 계획이 Notion에 작성됩니다."
echo ""
echo "⚠️  실행 전 필수 준비:"
echo "  1. Notion Integration 생성: https://www.notion.so/my-integrations"
echo "  2. .env.shared에 NOTION_API_KEY, NOTION_DAILY_DATABASE_ID 기입"
echo "  3. Notion DB에 Integration 접근 권한 부여"
echo "--------------------------------------------------"
