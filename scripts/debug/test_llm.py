import sys
sys.path.append('scripts/automations')
from _shared.llm_client import LLMClient
from _shared.notion_client import NotionClient
from _shared.telegram_client import TelegramClient

def test_all():
    print("Testing LLM Client...")
    llm = LLMClient()
    res = llm.ask("Hello, just say exactly 'OK'", use_external=True, max_tokens=10)
    print("LLM Response:", res)
    
    print("\nTesting Notion Client...")
    try:
        notion = NotionClient()
        print("Notion initialized.")
    except Exception as e:
        print("Notion Error:", e)

    print("\nTesting Telegram Client...")
    try:
        tg = TelegramClient()
        print("Telegram initialized.")
    except Exception as e:
        print("Telegram Error:", e)

test_all()
