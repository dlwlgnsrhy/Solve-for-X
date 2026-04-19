
import sys
from pathlib import Path

# 모듈 경로 추가
_AUTOMATIONS_DIR = "/Users/apple/development/soluni/Solve-for-X/scripts/automations"
sys.path.insert(0, _AUTOMATIONS_DIR)

from _shared.llm_client import LLMClient

def test_sanitizer():
    client = LLMClient()
    
    test_cases = [
        # Case 1: XML Think block + preamble
        """<think>I should create a plan for Monday.</think>
Certainly! Here is the daily plan:

- 오늘의 할 일 Top 3
    - [ ]  First task
""",
        # Case 2: Code block thinking
        """```thinking
User wants a weekly plan.
```
### 이번 주 계획

- 이번 주 핵심 목표 3가지
""",
        # Case 3: Leading conversational noise
        """I have analyzed your logs. Proceeding to create the plan...

- 오늘의 할 일 Top 3
    - [ ]  Task
""",
        # Case 4: Multiple issues
        """<reasoning>Comparing weekly goals.</reasoning>
Here is the requested weekly plan:

### 이번 주 계획

- 이번 주 핵심 목표 3가지
"""
    ]

    for i, case in enumerate(test_cases):
        print(f"--- Test Case {i+1} ---")
        sanitized = client._sanitize_response(case)
        print(f"RESULT:\n{sanitized}")
        print("-" * 20)
        
        # Verification: Should not contain think or preamble
        assert "<think>" not in sanitized
        assert "Thinking process" not in sanitized
        assert "Certainly!" not in sanitized
        # Should start with # or -
        assert sanitized.startswith("#") or sanitized.startswith("-")

    print("\n✅ All sanitizer test cases passed!")

if __name__ == "__main__":
    test_sanitizer()
