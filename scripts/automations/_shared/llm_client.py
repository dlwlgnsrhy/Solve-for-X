"""
_shared/llm_client.py
=====================
로컬/외부 LLM 라우터 — 용도에 따라 두 엔드포인트를 전환합니다.

모델 라우팅 전략:
  - use_external=False (기본): 로컬 LM Studio (Qwen 14B) — 속도 우선
  - use_external=True        : 외부 A100 서버 (Qwen3.6 35B) — 품질 우선

# 버그 수정 (v2):
  - __init__에서 외부 LLM 변수를 Lazy하게 로드하도록 변경
    → LOCAL_LLM_* 만 설정된 환경에서도 인스턴스 생성 가능
    → EXTERNAL_LLM_* 는 use_external=True 호출 시점에만 검증

사용 방법:
    from _shared.llm_client import LLMClient
    client = LLMClient()
    result = client.ask("내 질문", use_external=True)  # 외부 Qwen3.6 35B
    result = client.ask("내 질문", use_external=False) # 로컬 Qwen 14B (기본)
"""

import json
import logging
import requests
from typing import Optional
from . import config

logger = logging.getLogger(__name__)


class LLMClient:
    def __init__(self):
        config.load_env()
        # 로컬 LLM — 반드시 필요 (없으면 시작 시점에 fail-fast)
        self._local_url   = config.require("LOCAL_LLM_URL")
        self._local_model = config.require("LOCAL_LLM_MODEL")

        # 외부 LLM — Lazy 로드 (use_external=True 호출 시에만 검증)
        # 로컬만 사용하는 시나리오(Git Hook 등)에서도 인스턴스 생성 허용
        self._ext_url     = config.get("EXTERNAL_LLM_URL")
        self._ext_model   = config.get("EXTERNAL_LLM_MODEL")
        self._ext_api_key = config.get("EXTERNAL_LLM_API_KEY")

    # ------------------------------------------------------------------
    def ask(
        self,
        user_prompt: str,
        system_prompt: str = "",
        use_external: bool = False,
        max_tokens: int = 2000,
        temperature: float = 0.3,
        timeout: tuple = (10, 180),
    ) -> Optional[str]:
        """
        LLM에 질문하고 텍스트 응답을 반환합니다.
        실패 시 None을 반환합니다 (예외를 올리지 않음).
        """
        if use_external:
            # 외부 LLM 사용 시점에 환경변수 검증
            if not self._ext_url or self._ext_url.startswith("<"):
                logger.error("[LLM] EXTERNAL_LLM_URL이 .env.shared에 설정되지 않았습니다.")
                return None
            if not self._ext_model or self._ext_model.startswith("<"):
                logger.error("[LLM] EXTERNAL_LLM_MODEL이 .env.shared에 설정되지 않았습니다.")
                return None
            url, model, api_key = self._ext_url, self._ext_model, self._ext_api_key
            label = "External (Qwen3.6 35B)"
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
        if api_key and not api_key.startswith("<"):
            headers["Authorization"] = f"Bearer {api_key}"

        import time
        max_retries = 3
        retry_delay = 5  # 초

        for attempt in range(1, max_retries + 1):
            try:
                logger.info(f"[LLM] {label} 호출 중... (시도 {attempt}/{max_retries}, max_tokens={max_tokens})")
                response = requests.post(
                    url,
                    data=json.dumps(payload),
                    headers=headers,
                    timeout=timeout,
                )
                response.raise_for_status()
                content = response.json()["choices"][0]["message"]["content"]
                
                # 디버깅용 원문 저장
                try:
                    with open("/tmp/soluni_llm_raw.txt", "w", encoding="utf-8") as f:
                        f.write(content)
                except:
                    pass
                
                # ── 하드 필터링: AI 노이즈 및 추론 과정 전면 제거 ──────────────────
                sanitized = self._sanitize_response(content)
                
                logger.info(f"[LLM] {label} 응답 완료 ({len(content)}자 -> 정제 후 {len(sanitized)}자)")
                return sanitized
            except requests.exceptions.ConnectionError:
                logger.warning(f"[LLM] {label} 연결 실패 (시도 {attempt}/{max_retries})")
            except requests.exceptions.Timeout:
                logger.warning(f"[LLM] {label} 타임아웃 (시도 {attempt}/{max_retries})")
            except Exception as e:
                logger.error(f"[LLM] {label} 기타 오류: {e}")
                break  # 기타 오류는 재시도 없이 중단
            
            if attempt < max_retries:
                time.sleep(retry_delay * attempt)  # 지수 백어프

        logger.error(f"[LLM] {label} 최종 호출 실패 (총 {max_retries}회 시도)")
        return None

    # ------------------------------------------------------------------
    def _sanitize_response(self, text: str) -> str:
        """
        AI 모델이 출력하는 모든 형태의 노이즈(CoT, 추론 블록, 인사말, 메타 담화)를 
        정규표현식으로 정밀 타격하여 제거합니다.
        """
        import re
        if not text:
            return ""

        # 1. XML 형태의 추론 블록 제거: <think>...</think>, <reasoning>...</reasoning> 등
        text = re.sub(r'<(think|reasoning|thought)>.*?</\1>', '', text, flags=re.DOTALL | re.IGNORECASE)
        
        # 2. Markdown 코드 블록 내의 추론 블록 제거
        text = re.sub(r'```(?:thinking|thought|reasoning|cot).*?```', '', text, flags=re.DOTALL | re.IGNORECASE)
        
        # 3. 텍스트 라벨 기반 추론 및 사족 패턴 리스트
        patterns = [
            r"^Thinking process:.*?\n\n",
            r"^Here's a thinking process:.*?\n\n",
            r"^I will analyze the data.*?Proceeding to create.*?\n\n",
            r"^Self-Correction/Verification:.*?\n\n",
            r"^Certainly! Here is.*?:\n\n",
            r"^Here is the requested.*?:\n\n",
            r"^Below is the correctly formatted.*?:\n\n"
        ]
        for p in patterns:
            text = re.sub(p, '', text, flags=re.DOTALL | re.IGNORECASE)

        # 4. 마지막 보루: 유효한 시작점 탐지 및 잡담 제거
        # AI가 추론 과정(Thinking process) 내에서 출력 양식을 미리 언급하는 경우가 많으므로,
        # 모든 유효한 앵커(가이드 및 템플릿 헤더) 중 문서의 가장 마지막에 나타나는 지점을 권장 시작점으로 잡습니다.
        
        all_anchors = [
            r'^\s*##\s*🧠\s*Coach', 
            r'^\s*##\s*📊\s*Last\s*Week',
            r'^\s*##\s*🌅\s*오늘의\s*작업\s*요약',
            r'^\s*###\s*이번\s*주\s*계획', 
            r'^\s*-\s*오늘의\s*할\s*일', 
            r'^\s*-\s*이번\s*주\s*핵심\s*목표'
        ]

        last_idx = -1
        
        for anchor in all_anchors:
            # finditer를 사용하여 해당 앵커의 가장 마지막 출현 위치를 검색
            for match in re.finditer(anchor, text, flags=re.MULTILINE | re.IGNORECASE):
                if match.start() > last_idx:
                    last_idx = match.start()
        
        if last_idx != -1:
            text = text[last_idx:]

        # 최종 정제: 불필요한 공백 및 마지막 사족 제거
        return text.strip()

        return text.strip()

        return text.strip()

    # ------------------------------------------------------------------
    def is_local_available(self) -> bool:
        """로컬 LM Studio가 응답 가능한지 빠르게 확인합니다."""
        try:
            base = self._local_url.replace("/v1/chat/completions", "")
            resp = requests.get(f"{base}/v1/models", timeout=3)
            resp.raise_for_status()
            return True
        except Exception:
            return False

    def is_external_available(self) -> bool:
        """외부 LLM 서버가 응답 가능한지 빠르게 확인합니다."""
        if not self._ext_url or self._ext_url.startswith("<"):
            return False
        try:
            base = self._ext_url.replace("/v1/chat/completions", "")
            headers = {}
            if self._ext_api_key and not self._ext_api_key.startswith("<"):
                headers["Authorization"] = f"Bearer {self._ext_api_key}"
            resp = requests.get(f"{base}/v1/models", headers=headers, timeout=5)
            resp.raise_for_status()
            return True
        except Exception:
            return False
