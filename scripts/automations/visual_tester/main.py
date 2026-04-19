#!/usr/bin/env python3
"""
visual_tester/main.py
======================
Flutter 웹 빌드 결과물을 브라우저로 실행하여 스크린샷을 찍고 텔레그램으로 전송합니다.
"""

import os
import sys
import time
import http.server
import socketserver
import threading
import logging
from pathlib import Path

# playwright는 스크린샷 캡처 시에만 필요하므로 지연 임포트 제안
# from playwright.sync_api import sync_playwright

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("VisualTester")

# 전역 변수 - 자동화 루트 경로 추가
_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.telegram_client import TelegramClient

PORT = 8089

class ThreadedHTTPServer(threading.Thread):
    def __init__(self, directory, port):
        super().__init__()
        self.directory = directory
        self.port = port
        self.server = None

    def run(self):
        try:
            # SimpleHTTPRequestHandler를 directory 인자와 함께 사용 (Python 3.7+)
            # os.chdir()을 쓰지 않아 전역 경로에 영향을 주지 않음
            class Handler(http.server.SimpleHTTPRequestHandler):
                def __init__(self, *args, **kwargs):
                    super().__init__(*args, directory=self.directory, **kwargs)
            
            # self.directory 가 ThreadedHTTPServer 의 속성이므로 클래스 내부에서 클로저처럼 접근하거나
            # partial을 쓸 수 있지만, 여기서는 커스텀 핸들러 클래스를 정의하여 해결
            directory = self.directory
            class FixedHandler(http.server.SimpleHTTPRequestHandler):
                def __init__(self, *args, **kwargs):
                    super().__init__(*args, directory=directory, **kwargs)

            # 포트가 이미 사용 중인 경우를 대비해 allow_reuse_address 설정
            socketserver.TCPServer.allow_reuse_address = True
            with socketserver.TCPServer(("", self.port), FixedHandler) as httpd:
                self.server = httpd
                logger.info(f"[Server] Serving at port {self.port} from {self.directory}")
                httpd.serve_forever()
        except Exception as e:
            logger.error(f"[Server] Failed to start server at port {self.port}: {e}")

    def shutdown(self):
        if self.server:
            self.server.shutdown()
            self.server.server_close() # 소켓 확실히 닫기
            logger.info("[Server] Shutting down.")

def capture_and_send(build_dir: str, app_name: str):
    """스크린샷 캡처 및 전송 메인 로직"""
    if not os.path.exists(build_dir):
        logger.error(f"[Error] 빌드 디렉토리가 존재하지 않습니다: {build_dir}")
        return

    # 1. 서버 시작
    server_thread = ThreadedHTTPServer(build_dir, PORT)
    server_thread.daemon = True
    server_thread.start()
    
    time.sleep(2)  # 서버 안정화 대기

    screenshot_path = os.path.join(os.getcwd(), f"screenshot_{app_name}.png")

    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            logger.info("[Browser] Launching chromium...")
            browser = p.chromium.launch()
            page = browser.new_page(viewport={'width': 1280, 'height': 800})
            
            url = f"http://localhost:{PORT}"
            logger.info(f"[Browser] Navigating to {url}...")
            
            # Flutter 웹 로딩 대기
            page.goto(url)
            
            # Glassmorphism 등 렌더링을 위해 충분히 대기 (최대 10초)
            logger.info("[Browser] Waiting for UI to settle...")
            time.sleep(7) 
            
            # 스크린샷 캡처
            page.screenshot(path=screenshot_path)
            logger.info(f"[Browser] Screenshot saved to {screenshot_path}")
            browser.close()

        # 2. 텔레그램 전송
        tg = TelegramClient()
        caption = f"🚀 {app_name} Visual Verification Result\nAnalyze: Success ✅\nBuild: Web ✅"
        success = tg.send_photo(screenshot_path, caption=caption)
        
        if success:
            logger.info("[Telegram] Screenshot sent successfully!")
        else:
            logger.error("[Telegram] Failed to send screenshot.")

    except Exception as e:
        logger.error(f"[Error] Visual Testing failed: {e}")
    finally:
        server_thread.shutdown()
        # 임시 파일 삭제 (선택 사항)
        if os.path.exists(screenshot_path):
            # os.remove(screenshot_path)
            pass

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 main.py <build_dir_path> <app_name>")
        sys.exit(1)
        
    build_path = os.path.abspath(sys.argv[1])
    name = sys.argv[2]
    capture_and_send(build_path, name)
