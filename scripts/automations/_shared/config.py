"""
_shared/config.py
=================
환경변수 안전 로더 — 모든 자동화 봇이 공유합니다.
민감한 값(URL, 토큰)은 .env.shared 파일에서만 읽고, 코드에 직접 기입하지 않습니다.
"""

import os
import logging
from pathlib import Path
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

# .env.shared의 위치: scripts/automations/.env.shared
_SHARED_ENV_PATH = Path(__file__).parent.parent / ".env.shared"


def load_env():
    """공통 환경변수 로드. .env.shared → 현재 디렉토리 .env 순으로 탐색."""
    if _SHARED_ENV_PATH.exists():
        load_dotenv(dotenv_path=_SHARED_ENV_PATH, override=False)
    # 봇별 .env가 있으면 덮어쓰기 허용 (개별 설정 우선)
    load_dotenv(override=True)


def require(key: str) -> str:
    """필수 환경변수 조회. 없으면 즉시 에러로 실패."""
    value = os.getenv(key)
    if not value or value.startswith("<"):
        raise EnvironmentError(
            f"필수 환경변수 '{key}'가 설정되지 않았습니다. "
            f"scripts/automations/.env.shared 파일을 확인하세요."
        )
    return value


def get(key: str, default: str = "") -> str:
    """선택적 환경변수 조회. 없으면 default 반환."""
    return os.getenv(key, default)
