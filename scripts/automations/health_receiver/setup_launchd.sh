#!/bin/bash
echo "=================================================="
echo "🩺 Health Receiver (Webhook) Launchd 등록 스크립트"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_FILE="$HOME/Library/LaunchAgents/com.soluni.healthreceiver.plist"
VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
MAIN_SCRIPT="$SCRIPT_DIR/main.py"

if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "📦 가상환경 생성 및 패키지 설치 중..."
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install --upgrade pip -q
    "$SCRIPT_DIR/venv/bin/pip" install fastapi[standard] pydantic uvicorn requests -q
    echo "✅ 패키지 설치 완료"
fi

cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.soluni.healthreceiver</string>
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
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/soluni_health_receiver.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/soluni_health_receiver.out</string>
</dict>
</plist>
EOF

chmod +x "$MAIN_SCRIPT"

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "🎉 Health Receiver (Webhook) 백그라운드 서비스 등록 완료!"
echo "서버가 8080 포트에서 수신 대기 중입니다."
