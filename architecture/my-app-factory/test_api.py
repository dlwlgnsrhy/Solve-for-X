import os
import requests
import json

def test_gemini_api():
    api_key = "AIzaSyAyulgHRdzp2_TMz0uCxRdDubihKlN-Nxk"
    
    # 1. Test gemini-2.5-flash
    print("--- 1. Testing gemini-2.5-flash ---")
    url_flash = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
    headers = {"Content-Type": "application/json"}
    payload_flash = {
        "contents": [{
            "parts": [{"text": "Hello, write a short 1-sentence greeting in Korean."}]
        }]
    }
    
    try:
        response = requests.post(url_flash, headers=headers, json=payload_flash)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            res_data = response.json()
            text = res_data['candidates'][0]['content']['parts'][0]['text']
            print(f"Response text: {text.strip()}")
        else:
            print(f"Error Response: {response.text}")
    except Exception as e:
        print(f"Request failed: {e}")

    # 2. Test gemma-4-31b-it
    print("\n--- 2. Testing gemma-4-31b-it ---")
    url_gemma = f"https://generativelanguage.googleapis.com/v1beta/models/gemma-4-31b-it:generateContent?key={api_key}"
    payload_gemma = {
        "contents": [{
            "parts": [{"text": "Hello, write a short 1-sentence greeting in Korean."}]
        }]
    }
    
    try:
        response = requests.post(url_gemma, headers=headers, json=payload_gemma)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            res_data = response.json()
            text = res_data['candidates'][0]['content']['parts'][0]['text']
            print(f"Response text: {text.strip()}")
            
            # Check if there is "thinking" or "thought" field
            try:
                # Some beta models return thinking process inside parts or under candidates
                print(f"Raw Response snippet: {json.dumps(res_data, indent=2)[:300]}...")
            except:
                pass
        else:
            print(f"Error Response: {response.text}")
    except Exception as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    test_gemini_api()
