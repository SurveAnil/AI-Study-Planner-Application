import os
import json
import requests
from dotenv import load_dotenv

def test_openrouter():
    print("--- 🚀 Starting OpenRouter API Test ---")
    
    # 1. Load configuration
    load_dotenv()
    api_key = os.getenv("OPENROUTER_API_KEY")
    model = os.getenv("OPENROUTER_MODEL", "z-ai/glm-4.5-air:free")
    
    if not api_key:
        print("❌ ERROR: OPENROUTER_API_KEY is missing from .env!")
        return

    print(f"✅ Key found: {api_key[:8]}...")
    print(f"📡 Testing Model: {model}")

    # 2. Prepare Sample Prompt
    sample_message = "Test: Please create a quick study plan for Java for 1 hour."
    
    prompt = f"""User message:
{sample_message}

Your task:
1. Generate a structured study plan with time blocks.
2. Output EXACTLY as HUMAN text followed by JSON.

Output format EXACTLY:
--- HUMAN ---
Plan content here.

--- JSON ---
[
{{"title": "Java Basics", "subject": "Java", "start_time": "14:00", "end_time": "15:00", "type": "study"}}
]
"""

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a senior study planner assistant."},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7
    }

    # 3. Call API
    try:
        print("📡 Sending request to OpenRouter...")
        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(payload),
            timeout=30
        )
        
        print(f"📊 HTTP Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SUCCESS: OpenRouter responded correctly!")
            resp_json = response.json()
            content = resp_json.get("choices", [{}])[0].get("message", {}).get("content", "")
            
            print("\n--- AI RESPONSE CONTENT ---")
            print(content)
            print("---------------------------\n")
            
            # Simple check for our markers
            if "--- HUMAN ---" in content and "--- JSON ---" in content:
                print("✨ VERIFIED: Response follows HUMAN/JSON formatting!")
            else:
                print("⚠️ WARNING: AI returned content but format markers were missing.")
                
        else:
            print(f"❌ ERROR: API returned status {response.status_code}")
            print(f"Message: {response.text}")

    except Exception as e:
        print(f"❌ CRITICAL EXCEPTION: {e}")

if __name__ == "__main__":
    test_openrouter()
