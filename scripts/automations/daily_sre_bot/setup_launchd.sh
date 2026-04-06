#!/bin/bash
echo "=================================================="
echo "🚀 SRE Auto-Blogger Launchd (Mac OS) 백그라운드 등록 스크립트"
echo "=================================================="

PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.dailysrebot.plist"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/test_run.sh"

echo "1. 백그라운드 스케줄러 설정(plist) 파일을 생성합니다..."

# XML Launchd plist 생성
cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.soluni.dailysrebot</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_PATH}</string>
    </array>

    <key>WorkingDirectory</key>
    <string>$(dirname "${SCRIPT_PATH}")/../..</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>LANG</key>
        <string>ko_KR.UTF-8</string>
    </dict>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>05</integer>
        <key>Minute</key>
        <integer>00</integer>
    </dict>
    
    <key>StandardErrorPath</key>
    <string>/tmp/soluni_sre_bot.err</string>
    
    <key>StandardOutPath</key>
    <string>/tmp/soluni_sre_bot.out</string>
    
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

echo "✅ 파일 생성 완료: $PLIST_FILE"
echo "2. 시스템(Launchctl)에 작업을 등록합니다..."

# 혹시 기존에 있으면 내리고 다시 등록
launchctl unload "$PLIST_FILE" 2>/dev/null
launchctl load "$PLIST_FILE"

echo "--------------------------------------------------"
echo "🎉 세팅이 완벽히 끝났습니다."
echo "이제 매일 아침 05시 00분에 스크립트가 동작합니다."
echo "[중요] 만약 아침 05시 00분에 맥북이 자고(Sleep) 있었다면,"
echo "맥북 뚜껑을 열고 전원이 들어오는 즉시 밀린 작업을 실행합니다!"
echo "--------------------------------------------------"
