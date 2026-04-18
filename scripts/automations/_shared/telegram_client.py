"""
_shared/telegram_client.py
===========================
Telegram 알림 헬퍼 — 모든 자동화 봇이 공유합니다.
"""

import logging
import requests
from typing import Optional
from . import config

logger = logging.getLogger(__name__)


class TelegramClient:
    def __init__(self):
        config.load_env()
        self._token   = config.require("TELEGRAM_BOT_TOKEN")
        self._chat_id = config.require("TELEGRAM_CHAT_ID")
        self._base_url = f"https://api.telegram.org/bot{self._token}"

    def send(self, text: str, parse_mode: Optional[str] = None) -> bool:
        """단순 텍스트 메시지 전송. 성공 시 True, 실패 시 False."""
        payload: dict = {"chat_id": self._chat_id, "text": text}
        if parse_mode:
            payload["parse_mode"] = parse_mode
        try:
            resp = requests.post(
                f"{self._base_url}/sendMessage",
                json=payload,
                timeout=15,
            )
            resp.raise_for_status()
            return True
        except Exception as e:
            logger.error(f"[Telegram] 전송 실패: {e}")
            return False

    def send_photo(self, photo_path: str, caption: Optional[str] = None) -> bool:
        """이미지 파일 전송. 성공 시 True, 실패 시 False."""
        url = f"{self._base_url}/sendPhoto"
        payload = {"chat_id": self._chat_id}
        if caption:
            payload["caption"] = caption
        
        try:
            with open(photo_path, 'rb') as photo:
                files = {'photo': photo}
                resp = requests.post(url, data=payload, files=files, timeout=30)
                resp.raise_for_status()
                return True
        except Exception as e:
            logger.error(f"[Telegram] 사진 전송 실패: {e}")
            return False

    def send_chunked(self, text: str, chunk_size: int = 4000) -> None:
        """Telegram 4096자 제한을 고려해 긴 텍스트를 분할 전송합니다."""
        for i in range(0, len(text), chunk_size):
            self.send(text[i : i + chunk_size])
