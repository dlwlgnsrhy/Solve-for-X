#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "=================================================="
echo "🚀 SRE Daily Auto-Blogger 테스트 런 스크립트"
echo "=================================================="

# 스크립트가 위치한 디렉토리로 이동
cd "$(dirname "$0")"

echo "[❗️ 필수 확인 사항]"
echo "테스트를 돌리기 전에 Mac에 깔린 LM Studio 우측 탭에서 [Start Server] 버튼을 눌러주셔야 합니다. (1234 포트 개방)"
echo "--------------------------------------------------"

# 가상환경이 없으면 자동 생성 및 패키지 설치
if [ ! -d "venv" ]; then
    echo "📦 로컬 가상 환경(venv)을 처음 생성하고 필수 모듈(requests)을 설치합니다..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi

echo ""
echo "🧠 [실행 중] 이제 main.py 데몬 봇을 강제로 1회 구동(테스트)해 봅니다..."
python main.py
