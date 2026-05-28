#!/usr/bin/env python3
import os
import requests
from dotenv import load_dotenv

# Load API key
ENV_PATH = "/Users/apple/development/soluni/Solve-for-X/architecture/my-app-factory/.env"
load_dotenv(ENV_PATH)
api_key = os.environ.get("GEMINI_API_KEY")

if not api_key:
    print("Error: GEMINI_API_KEY not found!")
    exit(1)

# Correct model identifiers verified from models.list endpoint
models_to_test = [
    "gemini-3.5-flash",
    "gemini-3-flash-preview",
    "gemma-4-31b-it",
    "gemma-4-26b-a4b-it",
    "gemini-2.5-flash"
]

print("==================================================")
print("🎯 RETESTING VERIFIED GOOGLE GENAI MODEL API IDENTIFIERS")
print("==================================================")

for model in models_to_test:
    print(f"\n[TESTING] Model: {model} ...")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    
    if "gemma" in model:
        payload = {
            "contents": [{
                "parts": [{"text": "[SYSTEM INSTRUCTION]\nYou are a helpful assistant.\n\n[USER INPUT]\nHello! Say only the word 'Gemma' and nothing else."}]
            }]
        }
    else:
        payload = {
            "contents": [{
                "parts": [{"text": "Hello! Say only the word 'Gemini' and nothing else."}]
            }]
        }
        
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=20)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            res_data = response.json()
            try:
                text = res_data['candidates'][0]['content']['parts'][0]['text'].strip()
                print(f"✅ SUCCESS! Response: {text}")
            except Exception as parse_ex:
                print(f"⚠️ Success status, but failed to parse response JSON: {parse_ex}")
                print(f"Raw Response: {response.text[:200]}")
        else:
            print(f"❌ FAILED! Response: {response.text[:300]}")
    except Exception as e:
        print(f"💥 EXCEPTION: {e}")
