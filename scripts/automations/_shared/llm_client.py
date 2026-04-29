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
        timeout: tuple = (10, 60),
        status_callback: Optional[callable] = None,
    ) -> Optional[str]:
        """
        LLM에 질문하고 텍스트 응답을 반환합니다.
        외부(1순위) -> 로컬(2순위) 순환을 최대 3 사이클 반복합니다.
        status_callback을 통해 텔레그램 등으로 재요청 상황을 알릴 수 있습니다.
        """
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": user_prompt})

        # 사이클 설정 (총 3 사이클 = 최대 6번 시도)
        # 외부 LLM 사용 요청 시에만 외부를 포함
        strategies = []
        if use_external and self._ext_url and not self._ext_url.startswith("<"):
            strategies.append({
                "url": self._ext_url,
                "model": self._ext_model,
                "api_key": self._ext_api_key,
                "label": "External (Qwen3.6 35B)"
            })
        
        strategies.append({
            "url": self._local_url,
            "model": self._local_model,
            "api_key": None,
            "label": "Local (Qwen 14B)"
        })

        max_cycles = 3
        retry_delay = 5  # 초 (지수 백오프 기반)

        for cycle in range(1, max_cycles + 1):
            for strat in strategies:
                url, model, api_key, label = strat["url"], strat["model"], strat["api_key"], strat["label"]
                
                payload = {
                    "model": model,
                    "messages": messages,
                    "temperature": temperature,
                    "max_tokens": max_tokens,
                }
                headers = {"Content-Type": "application/json"}
                if api_key and not api_key.startswith("<"):
                    headers["Authorization"] = f"Bearer {api_key}"

                try:
                    logger.info(f"[LLM] {label} 호출 중... (사이클 {cycle}/{max_cycles}, max_tokens={max_tokens})")
                    response = requests.post(
                        url,
                        data=json.dumps(payload),
                        headers=headers,
                        timeout=timeout,
                    )
                    response.raise_for_status()
                    content = response.json()["choices"][0]["message"]["content"]
                    
                    try:
                        with open("/tmp/soluni_llm_raw.txt", "w", encoding="utf-8") as f:
                            f.write(content)
                    except:
                        pass
                    
                    # ── 하드 필터링: AI 노이즈 및 추론 과정 전면 제거 ──────────────────
                    sanitized = self._sanitize_response(content)

                    if not sanitized:
                        logger.warning(f"[LLM] {label} 응답 파싱 실패 (CoT/포맷 오류) -> 다음 전략 시도")
                        continue # 실패 시 바로 포기하지 않고 다음 전략(또는 다음 사이클)으로 넘어감

                    logger.info(f"[LLM] {label} 응답 완료 ({len(content)}자 -> 정제 후 {len(sanitized)}자)")
                    return sanitized

                except requests.exceptions.ConnectionError:
                    logger.warning(f"[LLM] {label} 연결 실패 (사이클 {cycle}/{max_cycles})")
                except requests.exceptions.Timeout:
                    logger.warning(f"[LLM] {label} 타임아웃 (사이클 {cycle}/{max_cycles})")
                except Exception as e:
                    logger.error(f"[LLM] {label} 기타 오류: {e}")
            
            # 한 사이클의 모든 전략(외부/로컬)이 실패했을 때
            if cycle < max_cycles:
                delay = retry_delay * (2 ** (cycle - 1))  # 5초, 10초
                logger.warning(f"[LLM] 모든 전략 실패. {delay}초 후 사이클 {cycle+1} 재시도...")
                if status_callback:
                    try:
                        status_callback(f"⏳ LLM 서버 지연(또는 포맷 에러)으로 재요청 중입니다... ({cycle}/{max_cycles} 재시도, {delay}초 후 재개)")
                    except: pass
                
                import time
                time.sleep(delay)

        # 3사이클 모두 실패
        err_msg = f"[LLM] 최종 호출 실패 (총 {max_cycles} 사이클 시도)"
        logger.error(err_msg)
        if status_callback:
            try:
                status_callback(f"❌ {err_msg}. 서버 상태를 확인해주세요.")
            except: pass
            
        raise Exception(err_msg)

    # ------------------------------------------------------------------
    def _sanitize_response(self, text: str) -> str:
        """
        AI 모델 CoT/추론 블록을 제거하고 유효한 출력만 추출합니다.
        """
        import re
        if not text:
            return ""

        # 1. 명시적인 OUTPUT_START 마커가 있다면 그 이후만 완벽하게 추출
        if "===OUTPUT_START===" in text:
            text = text.split("===OUTPUT_START===")[-1].strip()
            
            # 모델이 코드 블록으로 감싸거나, 이스케이프 문자(\n)를 날것으로 출력한 경우 복구
            text = text.replace("\\n", "\n")
            if text.startswith("```") and text.endswith("```"):
                # ```markdown ... ``` 형태 제거
                text = re.sub(r'^```[a-zA-Z]*\n', '', text)
                text = text.replace("```", "").strip()
            elif text.startswith("`") and text.endswith("`"):
                text = text.strip("`").strip()
                
            return text

        # 2. XML 태그 추론 블록 제거 (<think>, <reasoning>, <scratchpad> 등)
        text = re.sub(
            r'<(think|reasoning|thought|scratchpad)>.*?</\1>',
            '', text, flags=re.DOTALL | re.IGNORECASE
        )

        # 3. Markdown 코드 블록 형태 추론 제거
        text = re.sub(
            r'```(?:thinking|thought|reasoning|cot|scratchpad).*?```',
            '', text, flags=re.DOTALL | re.IGNORECASE
        )

        # 4. 주요 시작 앵커 목록 (아침 브리핑 / 저녁 리포트 / 주간 / SRE)
        PRIMARY_ANCHORS = [
            # 아침 브리핑
            r'^\s*##\s*\U0001f916\s*에이전트',   # 🤖
            r'^\s*##\s*\U0001f464\s*직접',        # 👤
            r'^\s*##\s*\U0001f4a1\s*오늘의\s*핵심',  # 💡
            # 저녁 리포트
            r'^\s*##\s*\U0001f4ca\s*오늘의\s*성과',   # 📊
            r'^\s*##\s*\U0001f3af\s*전문가\s*피드백',  # 🎯
            r'^\s*##\s*\U0001f319\s*오늘\s*완료',      # 🌙
            r'^\s*##\s*\U0001f305\s*오늘의\s*작업\s*요약',  # 🌅
            # 주간 플래너
            r'^\s*###\s*이번\s*주\s*계획',
            r'^\s*##\s*\U0001f4ca\s*Last\s*Week',  # 📊
            r'^\s*##\s*\U0001f9e0\s*Coach',         # 🧠
            # SRE 봇
            r'^\s*===PHASE_ANALYSIS===',
        ]

        # 첫 번째 발생 위치를 찾아 그 이후만 사용
        first_idx = len(text)
        found = False
        for anchor in PRIMARY_ANCHORS:
            m = re.search(anchor, text, flags=re.MULTILINE | re.IGNORECASE)
            if m and m.start() < first_idx:
                first_idx = m.start()
                found = True

        if found:
            return text[first_idx:].strip()

        # 앵커 없음 → 빈 문자열 반환 (호출자가 simple fallback 사용)
        return ""

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
