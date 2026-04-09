#!/bin/bash
# =============================================================================
# Daily Planner — launchd 등록 스크립트 (v2 — 실행 방식 버그 수정)
# 매일 22:00 자동 실행 (내일 계획 Notion에 작성)
#
# # 버그 수정 (v2):
#   - `python -m daily_planner.main` 방식 → `python main.py` 직접 실행으로 변경
#     이유: launchd 환경에서 -m 방식은 WorkingDirectory 설정이 까다롭고,
#           main.py 내부에서 sys.path.insert()로 automations/ 경로를 직접 추가하므로
#           직접 실행이 더 안정적
# =============================================================================

echo "=================================================="
echo "📋 Daily Planner Launchd 등록 스크립트 v2"
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
    # _shared 모듈 의존성 (requests, python-dotenv는 requirements에 포함)
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

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "--------------------------------------------------"
echo "🎉 등록 완료! 매일 22:00에 내일 계획이 Notion에 작성됩니다."
echo ""
echo "⚠️  실행 전 필수 준비:"
echo "  1. Notion Integration 생성:"
echo "     https://www.notion.so/my-integrations"
echo "  2. .env.shared에 아래 값 기입:"
echo "     NOTION_API_KEY=<token>"
echo "     NOTION_DAILY_DATABASE_ID=<database id>"
echo "  3. Notion DB에 Integration 접근 권한 부여"
echo ""
echo "📝 DB 속성명이 기본값(Name/Date/Done)과 다른 경우:"
echo "  .env.shared에 추가:"
echo "     NOTION_TITLE_PROP=<실제 제목 속성명>"
echo "     NOTION_DATE_PROP=<실제 날짜 속성명>"
echo "     NOTION_DONE_PROP=<실제 완료 체크박스 속성명>"
echo "--------------------------------------------------"
echo ""
echo "수동 테스트: python3 \"$MAIN_SCRIPT\""
