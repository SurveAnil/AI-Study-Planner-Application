"""
Quick test script to verify the OpenRouter API key is working.
Run from the backend/ directory:

  python test_openrouter.py

Expected output if key works:
  [OK] Connected! Response: <some text>
"""

import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("OPENROUTER_API_KEY")
model   = os.getenv("OPENROUTER_MODEL", "google/gemini-2.0-flash-exp:free")

if not api_key or api_key == "YOUR_OPENROUTER_API_KEY_HERE":
    print("[FAIL] OPENROUTER_API_KEY not set in your .env file!")
    exit(1)

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=api_key,
)

print(f"Testing with model: {model}")
print("Sending test request to OpenRouter...")

try:
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "user", "content": "Say exactly: 'API key works!'"}
        ],
        max_tokens=20,
    )
    reply = response.choices[0].message.content
    print(f"[OK] Connected! Response: {reply}")
except Exception as e:
    print(f"[FAIL] Error: {type(e).__name__}: {e}")
