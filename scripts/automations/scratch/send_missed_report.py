import sys
import os
from pathlib import Path

# Add automations directory to path
automations_dir = Path("/Users/apple/development/soluni/Solve-for-X/scripts/automations")
if str(automations_dir) not in sys.path:
    sys.path.insert(0, str(automations_dir))

from _shared.telegram_client import TelegramClient

client = TelegramClient()

report_content = """
✅ **[에이전트 작업 완료 (수동 보고)]**
- 세션 ID: `20260429_195626_7f077f`

**📄 딸기(Strawberry) 영어 스펠링 및 어원 보고서**

**1. 기본 정보**
- **철자**: S-T-R-A-W-B-E-R-R-Y (10글자)
- **복수형**: strawberries (y → ies)

**2. 발음**
- 영국식: /ˈstrɔːb(ə)ri/
- 미국식: /ˈstrɔberi/

**3. 어원 (Etymology)**
Strawberry는 straw (짚) + berry (열매)의 합성어입니다.
- **고대 영어**: strēawberġe
- **중세 영어**: strawberie / strawbery

**4. "Straw"가 들어간 이유?**
- **설 1**: 야생 딸기가 짚 같은 줄기(runner)를 따라 퍼지며 자라는 특성.
- **설 2**: 딸기를 짚이나 줄기에 끼워서 수확하거나 짚 위에 올려 팔던 관습.

**5. 기억하기 팁**
- straw (짚) + berry (열매) = strawberry
- berry는 rr (쌍r)이 들어갑니다: b-e-rr-y

**6. 관련 표현**
- Strawberry jam (딸기 잼)
- Strawberry flavor (딸기 맛)
- Strawberry tart (딸기 타르트)

---
*출처: Wiktionary*
"""

try:
    client.send(report_content)
    print("Report sent to Telegram successfully.")
except Exception as e:
    print(f"Failed to send report: {e}")
