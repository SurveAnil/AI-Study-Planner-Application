import json
import os
import requests
from dotenv import load_dotenv

load_dotenv()

_OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
_MODEL = os.getenv("OPENROUTER_MODEL", "mistralai/mistral-nemo")


def generate_daily_plan(roadmap: dict, day: int, hours: int) -> dict:
    """
    Generate a structured Day-N study plan from a given roadmap using the LLM.
    Falls back to a mock plan if the API key is missing or the call fails.
    """
    if not _OPENROUTER_API_KEY or _OPENROUTER_API_KEY == "YOUR_OPENROUTER_API_KEY_HERE":
        print("[DailyPlan] No API key — using mock daily plan.")
        return _mock_daily_plan(roadmap, day, hours)

    skill = roadmap.get("skill", "the subject")
    stages = roadmap.get("stages", [])

    # Derive which stage Day N falls into
    stage_context = _resolve_stage_for_day(stages, day)

    prompt = f"""You are an expert study coach. Generate a focused Day {day} study plan.

Skill: {skill}
Daily Study Hours: {hours}
Stage Context: {json.dumps(stage_context, ensure_ascii=False)}

Return ONLY valid raw JSON — no markdown, no code fences.

Use this exact structure:
{{
  "day": {day},
  "skill": "{skill}",
  "total_hours": {hours},
  "tasks": [
    {{
      "title": "...",
      "type": "learn",
      "description": "...",
      "duration_minutes": 60
    }}
  ]
}}

Rules:
- "type" must be one of: "learn", "practice", "project"
- Total duration_minutes of all tasks must sum to approximately {hours * 60}
- Include a mix of learn, practice, and (if appropriate) project tasks
- Keep task titles concise and actionable
- Output ONLY raw JSON, nothing else
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
                    "You are an expert study coach. "
                    "Always respond with ONLY raw valid JSON — no markdown, no prose."
                ),
            },
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
    }

    for attempt in range(1, 3):
        try:
            print(f"[DailyPlan] Calling OpenRouter ({_MODEL}) — attempt {attempt}...")
            response = requests.post(
                url="https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                data=json.dumps(payload),
                timeout=60,
            )

            if response.status_code != 200:
                print(f"[DailyPlan] HTTP Error {response.status_code}: {response.text[:200]}")
                if attempt == 2:
                    return _mock_daily_plan(
                        roadmap, day, hours,
                        warning=f"LLM HTTP {response.status_code}"
                    )
                continue

            resp_json = response.json()
            raw: str = (
                resp_json.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            print(f"[DailyPlan] Raw response preview: {raw[:300]}...")

            # Strip markdown code fences if the model wraps the JSON anyway
            cleaned = raw.strip()
            if cleaned.startswith("```"):
                cleaned = cleaned.split("```")[1]
                if cleaned.lower().startswith("json"):
                    cleaned = cleaned[4:]
                cleaned = cleaned.rsplit("```", 1)[0].strip()

            data = json.loads(cleaned)
            data.setdefault("day", day)
            data.setdefault("skill", skill)
            print(
                f"[DailyPlan] Parsed successfully — "
                f"{len(data.get('tasks', []))} tasks."
            )
            return data

        except json.JSONDecodeError as e:
            print(f"[DailyPlan] JSON parse error (attempt {attempt}): {e}")
            if attempt == 2:
                return _mock_daily_plan(
                    roadmap, day, hours,
                    warning="LLM returned invalid JSON after 2 retries."
                )

        except Exception as e:
            print(f"[DailyPlan Error] {type(e).__name__}: {e}")
            return _mock_daily_plan(
                roadmap, day, hours,
                warning=f"LLM Error: {str(e)[:80]}"
            )

    return _mock_daily_plan(roadmap, day, hours)


def _resolve_stage_for_day(stages: list, day: int) -> dict:
    """Return the roadmap stage that Day N falls into, or the first stage."""
    elapsed = 0
    for stage in stages:
        duration = int(stage.get("duration_days", 0))
        if day <= elapsed + duration:
            return {
                "title": stage.get("title", "Foundation"),
                "topics": [
                    t.get("name") for t in stage.get("topics", []) if isinstance(t, dict)
                ],
                "tools": stage.get("tools", []),
            }
        elapsed += duration
    # Beyond all stages — return last stage or empty
    if stages:
        last = stages[-1]
        return {
            "title": last.get("title", "Advanced"),
            "topics": [
                t.get("name") for t in last.get("topics", []) if isinstance(t, dict)
            ],
            "tools": last.get("tools", []),
        }
    return {"title": "Foundation", "topics": [], "tools": []}


def _mock_daily_plan(
    roadmap: dict, day: int, hours: int, warning: str = ""
) -> dict:
    """Offline fallback — always returns a valid Day plan structure."""
    skill = roadmap.get("skill", "the subject")
    stages = roadmap.get("stages", [])
    stage = _resolve_stage_for_day(stages, day)
    stage_title = stage.get("title", "Foundation")
    topics = stage.get("topics", ["Core Concepts"])
    first_topic = topics[0] if topics else "Core Concepts"

    tasks = []
    remaining = hours * 60

    # Learn task
    learn_mins = min(60, remaining)
    tasks.append({
        "title": f"Study: {first_topic}",
        "type": "learn",
        "description": f"Read and understand {first_topic} in the {stage_title} stage of {skill}.",
        "duration_minutes": learn_mins,
    })
    remaining -= learn_mins

    # Practice task
    if remaining >= 30:
        practice_mins = min(remaining, 45)
        tasks.append({
            "title": f"Practice: {first_topic} Exercises",
            "type": "practice",
            "description": f"Solve exercises and coding challenges related to {first_topic}.",
            "duration_minutes": practice_mins,
        })
        remaining -= practice_mins

    # Project task (if hours ≥ 3)
    if remaining >= 30 and hours >= 3:
        tasks.append({
            "title": f"Mini Project: Apply {first_topic}",
            "type": "project",
            "description": f"Build a small project that applies {first_topic} concepts.",
            "duration_minutes": remaining,
        })

    result = {
        "day": day,
        "skill": skill,
        "total_hours": hours,
        "tasks": tasks,
    }
    if warning:
        result["_warning"] = warning or "Offline mock plan (API unavailable)."
    return result
