#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "=================================================="
echo "🚀 SRE Daily Auto-Blogger v2 테스트 런 스크립트"
echo "=================================================="

# automations 디렉토리 기준으로 실행 (공통 _shared 모듈 인식을 위해 필수)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUTOMATIONS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$AUTOMATIONS_DIR"

echo "[❗️ 사전 확인]"
echo "1. LM Studio가 실행 중이고 서버가 시작되어 있는지 확인 (포트 1234)"
echo "2. .env.shared의 EXTERNAL_LLM_URL, TELEGRAM_BOT_TOKEN 등이 설정되어 있는지 확인"
echo "--------------------------------------------------"

# 가상환경이 없으면 자동 생성
VENV_DIR="$SCRIPT_DIR/venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 로컬 가상 환경(venv)을 처음 생성하고 필수 모듈을 설치합니다..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install -r "$SCRIPT_DIR/requirements.txt" -q
    # 공통 모듈 의존성도 함께 설치
    "$VENV_DIR/bin/pip" install requests python-dotenv pyyaml -q
fi

source "$VENV_DIR/bin/activate"

echo ""
echo "🧠 [실행 중] SRE Bot v2를 1회 강제 구동합니다..."
PYTHONPATH="$AUTOMATIONS_DIR" python daily_sre_bot/main.py
