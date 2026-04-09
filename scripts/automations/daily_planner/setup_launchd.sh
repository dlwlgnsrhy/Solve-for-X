#!/bin/bash
# =============================================================================
# Daily Planner — launchd 등록 스크립트 (v3 — 아침 실행)
# 매일 07:00 자동 실행
# 전날 Daily Log 참조 → 오늘 계획 Notion에 작성 → Telegram 알림
#
# 흐름:
#   07:00 봇 실행 → 어제 기록 읽기 → 오늘 계획 생성 → Notion 오늘 페이지
#   저녁 회고: 지훈님이 직접 작성 (봇이 생성하지 않음)
# =============================================================================

echo "=================================================="
echo "📋 Daily Planner Launchd 등록 스크립트 v3 (아침 07:00)"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.dailyplanner.plist"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
MAIN_SCRIPT="$SCRIPT_DIR/main.py"

# 가상환경 생성 및 의존성 설치
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 가상환경 생성 및 패키지 설치 중..."
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install --upgrade pip -q
    "$SCRIPT_DIR/venv/bin/pip" install -r "$SCRIPT_DIR/requirements.txt" -q
    echo "✅ 패키지 설치 완료"
else
    echo "ℹ️  기존 가상환경 재사용. (재설치: rm -rf $SCRIPT_DIR/venv && 재실행)"
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
        <string>${MAIN_SCRIPT}</string>
    </array>

    <!-- WorkingDirectory: daily_planner/ 기준으로 실행
         main.py 내부에서 sys.path에 automations/를 추가하므로 _shared 모듈 접근 가능 -->
    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>LANG</key>
        <string>ko_KR.UTF-8</string>
    </dict>

    <!-- 매일 07:00 실행 — 하루 시작 전 오늘 계획 준비 -->
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>7</integer>
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

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "--------------------------------------------------"
echo "🎉 등록 완료! 매일 07:00에 오늘 계획이 Notion에 작성됩니다."
echo ""
echo "  전날 기록 → Gemma 31B → 오늘 Notion 페이지 → Telegram 알림"
echo "  저녁 회고는 지훈님이 직접 작성하세요."
echo "--------------------------------------------------"
echo ""
echo "수동 테스트: python3 \"$MAIN_SCRIPT\""
