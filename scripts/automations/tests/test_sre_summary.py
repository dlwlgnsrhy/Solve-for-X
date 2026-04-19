
import re

blog_content = """
===PHASE_ANALYSIS===
Phase 1.5
===BLOG_TITLE===
The Solution
===BLOG_CONTENT===
**Problem: Critical Vulnerability**
We found a major issue in the system that caused several crashes during the weekend peak hours. This led to serious data loss.

**Approach: Engineering Resilience**
We implemented a circuit breaker...
"""

summary_match = re.search(r'\*\*Problem:.*?\n(.*?)\n\n\*\*', blog_content, re.DOTALL)
summary = summary_match.group(1).strip()[:180] if summary_match else "FAILED"

print(f"EXTRACTED SUMMARY:\n{summary}")
assert summary != "FAILED"
assert "crashes" in summary
print("✅ SRE Summary Extraction Test Passed!")
