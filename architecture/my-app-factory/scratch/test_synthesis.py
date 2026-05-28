import os
import requests
import json
from dotenv import load_dotenv

ENV_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/.env"
load_dotenv(ENV_PATH)

def test_synthesis():
    api_key = os.environ.get("GEMINI_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemma-4-31b-it:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    
    sys_instruction = (
        "You are an expert Flutter configuration builder. Take these high-level prototype specs "
        "(project name, design system, fidelity, companion toggles, and requirements prompt) and output a "
        "strict, valid JSON containing exactly: app_name, version, api_base_url, primary_color, secondary_color, "
        "background_color, card_color, enable_chat, enable_profile, enable_settings, hero_title, hero_subtitle, "
        "and dynamic_items array. "
        "You must carefully customize the colors, headings, and dynamic cards based on the selected design system "
        "(Neutral Modern, Cozy Warm Pastel, Cyberpunk Neon, Sleek Dark Professional), selected fidelity (Wireframe "
        "should map to monochrome/greyscale colors like #f3f4f6, #9ca3af, #1f2937 with clean flat panels, while High Fidelity maps to rich vibrant colors), "
        "and prompt description!"
    )
    
    with open("/Users/apple/development/soluni/Solve-for-X/architecture/temp_spec_test.json", 'r', encoding='utf-8') as f:
        spec_content = f.read()
        
    prompt = f"Analyze this design AST and output strict JSON app spec:\n{spec_content}"
    
    payload = {
        "contents": [{
            "parts": [{"text": f"[SYSTEM INSTRUCTION]\n{sys_instruction}\n\n[USER INPUT]\n{prompt}"}]
        }],
        "generationConfig": {
            "responseMimeType": "application/json"
        }
    }
    
    response = requests.post(url, headers=headers, json=payload, timeout=90)
    print("Status:", response.status_code)
    if response.status_code == 200:
        res_data = response.json()
        text_content = res_data['candidates'][0]['content']['parts'][0]['text']
        print("Raw text:")
        print(text_content)
    else:
        print("Error:", response.text)

if __name__ == "__main__":
    test_synthesis()
