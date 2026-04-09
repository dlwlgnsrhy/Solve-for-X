"""
_shared/llm_client.py
=====================
로컬/외부 LLM 라우터 — 용도에 따라 두 엔드포인트를 전환합니다.

사용 방법:
    from _shared.llm_client import LLMClient
    client = LLMClient()
    result = client.ask("내 질문", use_external=True)  # 외부 Gemma 31B
    result = client.ask("내 질문", use_external=False) # 로컬 Qwen 14B (기본)
"""

import json
import logging
import requests
from typing import Optional
from . import config

logger = logging.getLogger(__name__)


class LLMClient:
    """
    모델 라우팅 전략:
      - use_external=False (기본): 로컬 LM Studio (Qwen 14B) — 속도 우선
      - use_external=True        : 외부 A100 서버 (Gemma 31B) — 품질 우선
    """

    def __init__(self):
        config.load_env()
        self._local_url   = config.require("LOCAL_LLM_URL")
        self._local_model = config.require("LOCAL_LLM_MODEL")
        self._ext_url     = config.require("EXTERNAL_LLM_URL")
        self._ext_model   = config.require("EXTERNAL_LLM_MODEL")
        self._ext_api_key = config.require("EXTERNAL_LLM_API_KEY")

    # ------------------------------------------------------------------
    def ask(
        self,
        user_prompt: str,
        system_prompt: str = "",
        use_external: bool = False,
        max_tokens: int = 2000,
        temperature: float = 0.3,
        timeout: int = 120,
    ) -> Optional[str]:
        """
        LLM에 질문하고 텍스트 응답을 반환합니다.
        실패 시 None을 반환합니다 (예외를 올리지 않음).
        """
        if use_external:
            url, model, api_key = self._ext_url, self._ext_model, self._ext_api_key
            label = "External (Gemma 31B)"
        else:
            url, model, api_key = self._local_url, self._local_model, None
            label = "Local (Qwen 14B)"

        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": user_prompt})

        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
        }

        headers = {"Content-Type": "application/json"}
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        try:
            logger.info(f"[LLM] {label} 호출 중... (max_tokens={max_tokens})")
            response = requests.post(
                url,
                data=json.dumps(payload),
                headers=headers,
                timeout=timeout,
            )
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            logger.info(f"[LLM] {label} 응답 완료 ({len(content)}자)")
            return content
        except requests.exceptions.ConnectionError:
            logger.error(f"[LLM] {label} 연결 실패 — 서버가 실행 중인지 확인하세요.")
        except requests.exceptions.Timeout:
            logger.error(f"[LLM] {label} 타임아웃 ({timeout}초 초과)")
        except Exception as e:
            logger.error(f"[LLM] {label} 오류: {e}")
        return None

    # ------------------------------------------------------------------
    def is_local_available(self) -> bool:
        """로컬 LM Studio가 응답 가능한지 빠르게 확인합니다."""
        try:
            base = self._local_url.replace("/v1/chat/completions", "")
            requests.get(f"{base}/v1/models", timeout=3)
            return True
        except Exception:
            return False
