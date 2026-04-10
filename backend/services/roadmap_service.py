import json
import os
import requests
from dotenv import load_dotenv
from fastapi import HTTPException

load_dotenv()

_OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
_MODEL = os.getenv("OPENROUTER_MODEL", "mistralai/mistral-nemo")


def generate_roadmap(skill: str, duration_days: int = 90) -> dict:
    """
    Generate a structured learning roadmap for the given skill using the LLM.
    Falls back to a mock roadmap if the API key is missing or the call fails.
    """
    if not _OPENROUTER_API_KEY or _OPENROUTER_API_KEY == "YOUR_OPENROUTER_API_KEY_HERE":
        print("[Roadmap] No API key — using mock roadmap.")
        return _mock_roadmap(skill)

    prompt = f"""Generate a detailed learning roadmap for: {skill} spanning exactly {duration_days} days.

Return ONLY valid raw JSON — no markdown, no code fences, no explanation.

The JSON must follow this exact structure:

{{
  "skill": "...",
  "overview": "...",
  "total_duration_days": <integer>,
  "stages": [
    {{
      "title": "...",
      "description": "...",
      "duration_days": <integer>,
      "topics": [
        {{
          "name": "...",
          "subtopics": ["...", "..."]
        }}
      ],
      "tools": ["...", "..."],
      "projects": [
        {{
          "title": "...",
          "description": "..."
        }}
      ]
    }}
  ]
}}
"""

    headers = {
        "Authorization": f"Bearer {_OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": _MODEL,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are an expert curriculum designer. "
                    "Always respond with ONLY raw valid JSON — no markdown, no prose."
                ),
            },
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
    }

    for attempt in range(1, 3):
        try:
            print(f"[Roadmap] Calling OpenRouter ({_MODEL}) — attempt {attempt}...")
            response = requests.post(
                url="https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                data=json.dumps(payload),
                timeout=60,
            )

            if response.status_code != 200:
                print(f"[Roadmap] HTTP Error {response.status_code}: {response.text[:200]}")
                if attempt == 2:
                    return _mock_roadmap(skill, duration_days, warning=f"LLM HTTP {response.status_code}")
                continue

            resp_json = response.json()
            raw: str = resp_json.get("choices", [{}])[0].get("message", {}).get("content", "")
            print(f"[Roadmap] Raw response preview: {raw[:300]}...")

            # Strip markdown code fences if the model wraps the JSON anyway
            cleaned = raw.strip()
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```")[1]
                if cleaned.lower().startswith("json"):
                    cleaned = cleaned[4:]
                cleaned = cleaned.rsplit("```", 1)[0].strip()

            data = json.loads(cleaned)
            data.setdefault("skill", skill)
            print(f"[Roadmap] Parsed successfully — {len(data.get('stages', []))} stages.")
            return data

        except json.JSONDecodeError as e:
            print(f"[Roadmap] JSON parse error (attempt {attempt}): {e}")
            if attempt == 2:
                return _mock_roadmap(skill, duration_days, warning="LLM returned invalid JSON after 2 retries.")

        except Exception as e:
            print(f"[Roadmap Error] {type(e).__name__}: {e}")
            return _mock_roadmap(skill, duration_days, warning=f"LLM Error: {str(e)[:80]}")

    return _mock_roadmap(skill, duration_days)


def _mock_roadmap(skill: str, duration_days: int = 30, warning: str = "") -> dict:
    """Offline fallback roadmap — always returns valid structure."""
    # Proportional scaling for mock stages
    s1 = int(duration_days * 0.25)
    s2 = int(duration_days * 0.45)
    s3 = duration_days - s1 - s2

    mock = {
        "skill": skill,
        "overview": f"A structured {duration_days}-day roadmap to become proficient in {skill}.",
        "total_duration_days": duration_days,
        "_warning": warning or "Offline mock roadmap (API unavailable).",
        "stages": [
            {
                "title": "Foundation",
                "description": "Core fundamentals and environment setup",
                "duration_days": s1,
                "topics": [
                    {
                        "name": "Basics",
                        "subtopics": ["Syntax", "Data Types", "Control Flow"],
                    },
                    {
                        "name": "Environment",
                        "subtopics": ["Setup", "Tooling", "Package Manager"],
                    },
                ],
                "tools": ["VS Code", "Terminal"],
                "projects": [
                    {
                        "title": "Hello World App",
                        "description": "Set up the environment and run a simple program.",
                    }
                ],
            },
            {
                "title": "Intermediate",
                "description": "Core concepts and small projects",
                "duration_days": s2,
                "topics": [
                    {
                        "name": "Core Concepts",
                        "subtopics": ["Functions", "Modules", "Error Handling"],
                    },
                    {
                        "name": "Data Handling",
                        "subtopics": ["Collections", "File I/O", "APIs"],
                    },
                ],
                "tools": ["Git", "Postman"],
                "projects": [
                    {
                        "title": "Mini Project",
                        "description": "Build a functional small application.",
                    }
                ],
            },
            {
                "title": "Advanced",
                "description": "Real-world application and portfolio project",
                "duration_days": s3,
                "topics": [
                    {
                        "name": "Advanced Topics",
                        "subtopics": ["Performance", "Testing", "Deployment"],
                    }
                ],
                "tools": ["Docker", "CI/CD"],
                "projects": [
                    {
                        "title": "Portfolio Project",
                        "description": "End-to-end production-ready project.",
                    }
                ],
            },
        ],
    }
    return mock
