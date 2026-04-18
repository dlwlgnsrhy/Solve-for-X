#!/bin/bash
# setup_feedback_daemon.sh
# =========================
# Feedback Daemon을 macOS 서비스(launchd)로 등록합니다.

PLIST_NAME="com.sfx.feedback.daemon.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
SOURCE_PLIST="/Users/apple/development/soluni/Solve-for-X/scripts/automations/health_receiver/$PLIST_NAME"

echo "1. 기존 서비스 중단 (있는 경우)..."
launchctl unload "$PLIST_PATH" 2>/dev/null

echo "2. Plist 파일 복사..."
cp "$SOURCE_PLIST" "$PLIST_PATH"

echo "3. 서비스 등록 및 시작..."
launchctl load "$PLIST_PATH"

echo "✅ Feedback Daemon이 설치되었습니다!"
echo "이제 텔레그램으로 피드백을 보내면 자동으로 opencode가 가동됩니다."
echo "로그 확인: tail -f /Users/apple/development/soluni/Solve-for-X/scripts/automations/health_receiver/daemon.out"
