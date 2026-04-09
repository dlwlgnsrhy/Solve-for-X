#!/bin/bash
# =============================================================================
# Daily News Curator — launchd 등록 스크립트
# 매일 09:00 자동 실행 (아침 뉴스 브리핑)
# =============================================================================

echo "=================================================="
echo "📰 Daily News Curator Launchd 등록 스크립트"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.dailynewscurator.plist"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"

# 가상환경 생성 및 패키지 설치
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 가상환경 생성 및 패키지 설치 중..."
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install -r "$SCRIPT_DIR/requirements.txt" -q
    # 공통 모듈 의존성도 함께 설치
    "$SCRIPT_DIR/venv/bin/pip" install requests python-dotenv -q
    echo "✅ 패키지 설치 완료"
fi

echo "1. launchd plist 파일 생성 중..."

cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.soluni.dailynewscurator</string>

    <key>ProgramArguments</key>
    <array>
        <string>${VENV_PYTHON}</string>
        <string>${SCRIPT_DIR}/main.py</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

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
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardErrorPath</key>
    <string>/tmp/soluni_news_curator.err</string>

    <key>StandardOutPath</key>
    <string>/tmp/soluni_news_curator.out</string>

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
echo "🎉 등록 완료! 매일 09:00에 뉴스 브리핑이 실행됩니다."
echo "수동 테스트: python3 main.py"
echo "--------------------------------------------------"
