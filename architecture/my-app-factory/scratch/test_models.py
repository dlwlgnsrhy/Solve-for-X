import os
import requests
import json
from dotenv import load_dotenv

ENV_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/.env"
load_dotenv(ENV_PATH)

def test_models():
    api_key = os.environ.get("GEMINI_API_KEY")
    headers = {"Content-Type": "application/json"}
    
    sys_instruction = (
        "You are an expert Flutter configuration builder. Take these high-level prototype specs "
        "(project name, design system, fidelity, companion toggles, and requirements prompt) and output a "
        "strict, valid JSON containing exactly: app_name, version, api_base_url, primary_color, secondary_color, "
        "background_color, card_color, enable_chat, enable_profile, enable_settings, hero_title, hero_subtitle, "
        "and dynamic_items array. "
        "Your entire response MUST be a single, strict, valid JSON object. No explanations, no thought logs, no comments, no markdown formatting. "
        "Ensure all keys are present: app_name, version, api_base_url, primary_color, secondary_color, background_color, "
        "card_color, enable_chat, enable_profile, enable_settings, hero_title, hero_subtitle, dynamic_items."
    )
    
    with open("/Users/apple/development/soluni/Solve-for-X/architecture/temp_spec_test.json", 'r', encoding='utf-8') as f:
        spec_content = f.read()
        
    prompt = f"Analyze this design spec and output strict JSON app spec:\n{spec_content}"
    
    # Let's try both gemma-4-31b-it and gemini-2.5-flash
    models = ["gemma-4-31b-it", "gemini-2.5-flash"]
    
    for model_name in models:
        print(f"\n=================== Testing {model_name} ===================")
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
        
        if "gemma" in model_name:
            payload = {
                "contents": [{
                    "parts": [{"text": f"[SYSTEM INSTRUCTION]\n{sys_instruction}\n\n[USER INPUT]\n{prompt}"}]
                }],
                "generationConfig": {
                    "responseMimeType": "application/json"
                }
            }
        else:
            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                "systemInstruction": {
                    "parts": [{"text": sys_instruction}]
                },
                "generationConfig": {
                    "responseMimeType": "application/json"
                }
            }
            
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=60)
            print("Status Code:", response.status_code)
            if response.status_code == 200:
                res_data = response.json()
                text = res_data['candidates'][0]['content']['parts'][0]['text']
                print("Response Length:", len(text))
                print("First 200 chars of text:")
                print(text[:200])
                print("Last 200 chars of text:")
                print(text[-200:])
                
                # Check if it parses as valid JSON
                try:
                    parsed = json.loads(text)
                    print("✅ PARSED SUCCESSFULLY!")
                    print("Keys:", list(parsed.keys()))
                except Exception as je:
                    print("❌ JSON PARSE FAILED:", je)
            else:
                print("Error Response:", response.text)
        except Exception as e:
            print("Request failed:", e)

if __name__ == "__main__":
    test_models()
