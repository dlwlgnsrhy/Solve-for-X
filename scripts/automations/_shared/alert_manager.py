"""
_shared/alert_manager.py
===========================
시스템 에러 알림(Telegram, MacOS Native) 및 QA Log 자동 기록을 담당하는 통합 매니저 클래스
"""

import logging
import datetime
from pathlib import Path
from .telegram_client import TelegramClient

logger = logging.getLogger(__name__)

# 현재 스크립트: scripts/automations/_shared/alert_manager.py
# REPO 루트: scripts/automations/_shared/../../../ -> Solve-for-X/
REPO_ROOT = Path(__file__).parent.parent.parent.parent
QA_LOG_PATH = REPO_ROOT / "docs" / "automation_qa_log.md"

class AlertManager:
    def __init__(self):
        self.telegram = TelegramClient()
        
    def send_critical_alert(self, title: str, message: str):
        """치명적 에러 시 Telegram 알림, 실패 시 Mac 알림, 그리고 QA 로그 파일에 기록합니다."""
        logger.error(f"{title}\n{message}")
        
        # 1. 텔레그램 발송
        success = False
        try:
            success = self.telegram.send(f"{title}\n{message}")
        except Exception as e:
            logger.error(f"[AlertManager] Telegram 발송 예외: {e}")

        # 2. 로컬 Mac 알림 (네트워크 장애 등 텔레그램 발송 누락 시 Fallback)
        if not success:
            try:
                import subprocess
                safe_msg = message.replace('"', '\\"').replace("'", "\\'")[:100]
                safe_title = title.replace('"', '\\"')
                subprocess.run([
                    "osascript", "-e",
                    f'display notification "{safe_msg}..." with title "{safe_title}"'
                ], check=False)
            except Exception as e:
                logger.error(f"[AlertManager] Mac 알림 실패: {e}")

        # 3. QA Log 자동 기록
        self._append_to_qa_log(title, message)

    def _append_to_qa_log(self, title: str, message: str):
        if not QA_LOG_PATH.exists():
            logger.warning(f"[AlertManager] QA Log 파일을 찾을 수 없습니다: {QA_LOG_PATH}")
            return
            
        try:
            now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            log_entry = f"\n## 🚨 시스템 에러 로그 (자동 수집)\n- **시간**: {now_str}\n- **유형**: {title}\n- **내용**: {message}\n"
            
            with open(QA_LOG_PATH, "a", encoding="utf-8") as f:
                f.write(log_entry)
            logger.info(f"[AlertManager] QA Log 파일에 에러 내용 기록됨.")
        except Exception as e:
            logger.error(f"[AlertManager] QA Log 파일 작성 실패: {e}")
