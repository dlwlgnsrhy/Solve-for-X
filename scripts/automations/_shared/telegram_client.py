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

    def send(self, text: str, parse_mode: Optional[str] = None) -> Optional[int]:
        """단순 텍스트 메시지 전송. 성공 시 message_id 반환, 실패 시 None 반환."""
        payload: dict = {"chat_id": self._chat_id, "text": text}
        if parse_mode:
            payload["parse_mode"] = parse_mode
            
        for attempt in range(3):
            try:
                resp = requests.post(
                    f"{self._base_url}/sendMessage",
                    json=payload,
                    timeout=15,
                )
                resp.raise_for_status()
                return resp.json().get("result", {}).get("message_id")
            except Exception as e:
                logger.warning(f"[Telegram] 전송 실패 (시도 {attempt+1}/3): {e}")
                import time
                time.sleep(2)
                
        logger.error("[Telegram] 최종 전송 실패: 재시도 횟수 초과")
        return None

    def edit_message(self, message_id: int, text: str, parse_mode: Optional[str] = None) -> bool:
        """기존 메시지의 내용을 수정합니다. 성공 시 True 반환."""
        payload: dict = {"chat_id": self._chat_id, "message_id": message_id, "text": text}
        if parse_mode:
            payload["parse_mode"] = parse_mode
            
        for attempt in range(3):
            try:
                resp = requests.post(
                    f"{self._base_url}/editMessageText",
                    json=payload,
                    timeout=15,
                )
                resp.raise_for_status()
                return True
            except Exception as e:
                logger.warning(f"[Telegram] 메시지 수정 실패 (시도 {attempt+1}/3): {e}")
                import time
                time.sleep(2)
                
        logger.error("[Telegram] 최종 메시지 수정 실패: 재시도 횟수 초과")
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
