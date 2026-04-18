#!/usr/bin/env python3
"""
visual_tester/live_preview.py
=============================
Flutter 웹 빌드를 로컬에서 서빙하고, Cloudflare Tunnel을 통해 외부 공개 URL을 생성하여 텔레그램으로 보냅니다.
"""

import os
import sys
import time
import subprocess
import threading
import logging
import re
from pathlib import Path

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("LivePreview")

# 전역 변수 - 자동화 루트 경로 추가
_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.telegram_client import TelegramClient
from visual_tester.main import ThreadedHTTPServer, PORT

CLOUDFLARED_PATH = os.path.join(os.path.dirname(__file__), "cloudflared")

def launch_tunnel(build_dir: str, app_name: str, duration_mins: int = 60):
    """터널 생성 및 텔레그램 전송"""
    if not os.path.exists(build_dir):
        logger.error(f"빌드 디렉토리 없음: {build_dir}")
        return

    # 1. 로컬 서버 시작
    server = ThreadedHTTPServer(build_dir, PORT)
    server.daemon = True
    server.start()
    time.sleep(2)

    # 2. Cloudflare Tunnel 실행
    logger.info("[Tunnel] Launching Cloudflare Tunnel...")
    cmd = [CLOUDFLARED_PATH, "tunnel", "--url", f"http://localhost:{PORT}"]
    
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    tunnel_url = None
    
    # 3. URL 추출 루프 (stderr에서 .trycloudflare.com 찾기)
    start_time = time.time()
    logger.info("[Tunnel] Waiting for public URL...")
    
    def monitor_stderr():
        nonlocal tunnel_url
        for line in process.stderr:
            # logger.debug(f"[Cloudflared] {line.strip()}")
            match = re.search(r'https://[a-zA-Z0-9-]+\.trycloudflare\.com', line)
            if match:
                tunnel_url = match.group(0)
                logger.info(f"[Tunnel] Found URL: {tunnel_url}")
                break

    stderr_thread = threading.Thread(target=monitor_stderr)
    stderr_thread.daemon = True
    stderr_thread.start()

    # URL 발견될 때까지 대기 (최대 30초)
    while not tunnel_url and time.time() - start_time < 30:
        time.sleep(1)

    if not tunnel_url:
        logger.error("[Tunnel] Failed to get public URL within timeout.")
        server.shutdown()
        process.terminate()
        return

    # 4. 텔레그램 전송
    tg = TelegramClient()
    message = (
        f"🎮 **{app_name} Live Interaction Link**\n\n"
        f"지표님, 아래 링크를 클릭하면 폰에서 즉시 테스트 가능합니다.\n"
        f"🔗 {tunnel_url}\n\n"
        f"⚠️ 이 링크는 {duration_mins}분 동안 유지됩니다."
    )
    tg.send(message, parse_mode="Markdown")
    logger.info("[Telegram] Live link sent!")

    # 5. 지정된 시간 동안 유지 후 종료
    try:
        logger.info(f"[Main] Tunnel will be active for {duration_mins} minutes. Press Ctrl+C to stop.")
        time.sleep(duration_mins * 60)
    except KeyboardInterrupt:
        logger.info("[Main] Stop requested by user.")
    finally:
        logger.info("[Main] Closing tunnel and server...")
        process.terminate()
        server.shutdown()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 live_preview.py <build_dir> <app_name> [duration_mins]")
        sys.exit(1)
        
    b_dir = os.path.abspath(sys.argv[1])
    name = sys.argv[2]
    dur = int(sys.argv[3]) if len(sys.argv) > 3 else 60
    
    launch_tunnel(b_dir, name, dur)
