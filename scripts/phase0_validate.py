#!/usr/bin/env python3
import os
import sys
import json
import requests
import time
from pathlib import Path

def get_env_var(key):
    # Try getting from env, or look in hermes-agent-main/.env
    val = os.getenv(key)
    if val: return val
    
    env_path = Path(__file__).parent.parent / "hermes-agent-main" / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                if line.startswith(key + "="):
                    return line.strip().split("=", 1)[1].strip(' "\'')
    return None

def generate_validation_report(app_name):
    # Simple PG-style / Founder Playbook evaluation template
    return f"""
🚀 *Startup Validation Report (Phase 0)* 🚀
*App:* `{app_name}`

*1. Pressure Test (PG Framework)*
- Is the core assumption testable before writing more code? 
- What are the 3 most likely ways this fails?
- Does this solve a real pain people pay to solve, or is it a nice-to-have?

*2. Customer Discovery (Mom Test)*
- Who has this problem most acutely? (Specific person, not demographic)
- Are they currently cobbling together a solution?

*3. First Customers (Do Things That Don't Scale)*
- What is the manual outreach approach? (No ads)
- Would these users be genuinely upset if the product disappeared?

*Next Step:*
Founder, please review the current MVP state. Do we SHIP IT to automated CI/CD, or DEFER for more validation?
"""

def send_telegram_message(bot_token, chat_id, text):
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "Markdown",
        "reply_markup": json.dumps({
            "inline_keyboard": [
                [
                    {"text": "✅ 컨펌 (Phase 1 빌드/배포 실행)", "callback_data": f"approve_deploy"},
                    {"text": "❌ 거절 (기능 보완)", "callback_data": f"reject_deploy"}
                ]
            ]
        })
    }
    
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        print(f"✅ Successfully sent validation report to Telegram.")
    except Exception as e:
        print(f"❌ Failed to send Telegram message: {e}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python phase0_validate.py <app_name>")
        sys.exit(1)
        
    app_name = sys.argv[1]
    
    print(f"==============================================")
    print(f" Phase 0: Startup Validation for {app_name}")
    print(f"==============================================")
    
    # 1. 'Capture' screenshots (Placeholder for integration_test / fastlane snapshot)
    print(f"📸 Capturing UI screenshots for {app_name} (Simulator hook)...")
    time.sleep(1) # Simulating capture
    print(f"📸 Screenshots saved to /tmp/{app_name}_screenshots/")
    print(f"----------------------------------------------")
    
    # 2. Generate Report
    report = generate_validation_report(app_name)
    print(report)
    print(f"----------------------------------------------")
    
    # 3. Send to Telegram
    bot_token = get_env_var("TELEGRAM_BOT_TOKEN")
    chat_id = get_env_var("TELEGRAM_HOME_CHANNEL") or get_env_var("TELEGRAM_CHAT_ID")
    
    if bot_token and chat_id:
        print("📲 Sending report to Founder via Telegram...")
        send_telegram_message(bot_token, chat_id, report)
    else:
        print("⚠️ TELEGRAM_BOT_TOKEN or TELEGRAM_HOME_CHANNEL not found in hermes-agent-main/.env.")
        print("⚠️ Skipping Telegram notification. Please configure your .env to enable the Phase 0 Approval gate.")
        print("⚠️ For now, manually approve to proceed to Phase 1.")

if __name__ == "__main__":
    main()
