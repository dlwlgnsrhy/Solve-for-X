#!/usr/bin/env python3
"""
health_receiver/feedback_daemon.py
==================================
(v5: Full Autonomy Mode)
1. Telegram 피드백 수신
2. opencode 자율 수정 (Caffeine 모드 적용)
3. 성공 시 flutter build web 자동 수행
4. 완료 후 시각적 리포트 + 실물 테스트 링크 자동 발송
"""

import os
import sys
import time
import subprocess
import logging
import requests
import threading
from pathlib import Path

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("FeedbackBridge")

# 공통 라이브러리 로드
_AUTOMATIONS_DIR = str(Path(__file__).parent.parent)
if _AUTOMATIONS_DIR not in sys.path:
    sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared import config
from _shared.telegram_client import TelegramClient

# 설정값
OPENCODE_PATH = "/Users/apple/.opencode/bin/opencode"
FLUTTER_PATH = "/Users/apple/development/flutter/bin/flutter"
TARGET_PROJECT_PATH = "/Users/apple/development/soluni/Solve-for-X/apps/life_log_v8"
SCRIPTS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"

class FeedbackDaemon:
    def __init__(self):
        config.load_env()
        self.token = config.require("TELEGRAM_BOT_TOKEN")
        self.chat_id = config.require("TELEGRAM_CHAT_ID")
        self.base_url = f"https://api.telegram.org/bot{self.token}"
        self.tg = TelegramClient()
        self.last_update_id = -1
        self.is_running = False

    def get_updates(self):
        url = f"{self.base_url}/getUpdates"
        params = {"offset": self.last_update_id + 1, "timeout": 30}
        try:
            resp = requests.get(url, params=params, timeout=35)
            resp.raise_for_status()
            return resp.json().get("result", [])
        except Exception as e:
            logger.error(f"[Telegram] 업데이트 확인 실패: {e}")
            return []

    def run_autonomous_loop(self, feedback: str):
        self.is_running = True
        try:
            # 1. 시작 보고
            self.tg.send(f"🤖 **자율 수정 및 갱신 시작 (v5)**\n피드백: \"{feedback}\"\n\n작업 순서: 수정 → 빌드 → 링크 생성 순으로 자동 진행됩니다. ⏳")

            # 2. opencode 수정 (caffeinate 적용)
            logger.info("--- [Stage 1: Opencode Fix] ---")
            fix_cmd = [
                "/usr/bin/caffeinate", "-is",
                OPENCODE_PATH, "run",
                "--dir", TARGET_PROJECT_PATH,
                "--command", "ulw-loop",
                "--dangerously-skip-permissions",
                f"사용자 피드백: [{feedback}]. 모든 수정을 완료하고 flutter analyze까지 통과시키세요."
            ]
            subprocess.run(fix_cmd, stdout=sys.stdout, stderr=sys.stderr)

            # 3. Flutter Web 빌드
            logger.info("--- [Stage 2: Flutter Build] ---")
            self.tg.send("🛠️ 코드가 수정되었습니다. 이제 최신 웹 빌드를 생성합니다...")
            build_cmd = [FLUTTER_PATH, "build", "web"]
            subprocess.run(build_cmd, cwd=TARGET_PROJECT_PATH, stdout=sys.stdout, stderr=sys.stderr)

            # 4. 시각적 보고 및 링크 생성
            logger.info("--- [Stage 3: Visual Report] ---")
            self.tg.send("📸 새로운 화면 캡처 및 체험 링크를 생성 중입니다...")
            
            # 스크린샷 캡처
            tester_path = os.path.join(SCRIPTS_DIR, "visual_tester", "main.py")
            subprocess.run(["python3", tester_path, "build/web", "life_log_v8"], cwd=TARGET_PROJECT_PATH)

            # 🎯 대망의 "라이브 프리뷰" 실행 및 링크 추출
            # 여기서는 live_preview.py를 subprocess로 돌리면 링크 추출이 복잡하므로 
            # 텔레그램으로 링크가 가도록 별도 스크립트 트리거
            preview_path = os.path.join(SCRIPTS_DIR, "visual_tester", "live_preview.py")
            # 10분간만 유지되는 링크 생성 (검증용)
            subprocess.Popen(["python3", preview_path, "build/web", "life_log_v8", "10"], cwd=TARGET_PROJECT_PATH)

            self.tg.send(f"✅ **자율 수정 및 갱신 완료!**\n\"{feedback}\" 반영이 끝났습니다. 잠시 후 도착할 스크린샷과 링크로 확인해 주세요! 🎮")

        except Exception as e:
            logger.error(f"[Loop Error] {e}")
            self.tg.send(f"❌ **자율 루프 중단**: {e}")
        finally:
            self.is_running = False

    def trigger(self, feedback: str):
        if self.is_running:
            self.tg.send("⏳ 다른 작업이 이미 진행 중입니다.")
            return
        threading.Thread(target=self.run_autonomous_loop, args=(feedback,)).start()

    def run(self):
        logger.info("[Main] Feedback Daemon v5 가동 시작...")
        while True:
            updates = self.get_updates()
            for update in updates:
                self.last_update_id = update["update_id"]
                msg = update.get("message", {})
                if str(msg.get("from", {}).get("id", "")) == self.chat_id:
                    text = msg.get("text", "")
                    if text and not text.startswith("/"):
                        self.trigger(text)
            time.sleep(1)

if __name__ == "__main__":
    FeedbackDaemon().run()
