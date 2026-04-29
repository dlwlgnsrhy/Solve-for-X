#!/bin/bash
# =============================================================================
# Telegram Commander — launchd 등록 스크립트
# 텔레그램 /start, /feedback, /report, /done, /status 커맨드를 상시 대기
#
# 동작 방식:
#   - 폴링 모드로 상시 실행 (KeepAlive: true)
#   - 당신이 텔레그램에 /start 전송 → 노션 오늘 계획 읽기 → 실행 시작
#   - /feedback [내용] → 즉시 작업 조정 실행
#   - /report, /done → 리포트 생성 및 마무리
# =============================================================================

echo "=================================================="
echo "🤖 Telegram Commander Launchd 등록 스크립트"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.telegram-commander.plist"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
MAIN_SCRIPT="$SCRIPT_DIR/main.py"

# 가상환경 생성 및 의존성 설치
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 가상환경 생성 및 패키지 설치 중..."
    # daily_planner venv 재사용 가능하지만 독립성을 위해 별도 생성
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install --upgrade pip -q

    # _shared 의존성 포함 설치
    SHARED_REQS="$(dirname "$SCRIPT_DIR")/daily_planner/requirements.txt"
    if [ -f "$SHARED_REQS" ]; then
        "$SCRIPT_DIR/venv/bin/pip" install -r "$SHARED_REQS" -q
    fi
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
    <string>com.soluni.telegram-commander</string>

    <key>ProgramArguments</key>
    <array>
        <string>${VENV_PYTHON}</string>
        <string>${MAIN_SCRIPT}</string>
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

    <!-- 상시 실행: 프로세스가 종료되면 자동 재시작 -->
    <key>KeepAlive</key>
    <true/>

    <!-- 부팅 시 자동 시작 -->
    <key>RunAtLoad</key>
    <true/>

    <!-- 재시작 최소 간격: 10초 (빠른 재시작 방지) -->
    <key>ThrottleInterval</key>
    <integer>10</integer>

    <key>StandardErrorPath</key>
    <string>/tmp/soluni_telegram_commander.err</string>

    <key>StandardOutPath</key>
    <string>/tmp/soluni_telegram_commander.out</string>
</dict>
</plist>
EOF

echo "✅ 파일 생성: $PLIST_FILE"
echo "2. launchctl에 등록 중..."

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "--------------------------------------------------"
echo "🎉 등록 완료! Telegram Commander가 상시 실행됩니다."
echo ""
echo "  지원 커맨드:"
echo "  /start            → 노션 오늘 계획 읽고 실행 시작"
echo "  /status           → 현재 진행 상황 확인"
echo "  /report           → 즉시 리포트 생성"
echo "  /feedback [내용]  → 피드백 전달 및 즉시 작업 조정"
echo "  /done             → 오늘 마무리 + 최종 리포트"
echo "--------------------------------------------------"
echo ""
echo "로그 확인: tail -f /tmp/soluni_telegram_commander.out"
echo "수동 테스트: python3 \"$MAIN_SCRIPT\""
echo ""
echo "중지: launchctl unload $PLIST_FILE"
