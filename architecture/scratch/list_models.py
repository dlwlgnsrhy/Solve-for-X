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

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
try:
    response = requests.get(url, timeout=15)
    if response.status_code == 200:
        res_data = response.json()
        models = res_data.get("models", [])
        print("==================================================")
        print("📋 ALL AVAILABLE API MODELS LIST:")
        print("==================================================")
        for m in models:
            name = m.get("name", "")
            display_name = m.get("displayName", "")
            print(f"ID: {name}   ➔ Display: {display_name}")
    else:
        print(f"Error fetching models: {response.text}")
except Exception as e:
    print(f"Exception: {e}")
