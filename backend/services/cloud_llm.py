import json
import os
import requests
from dotenv import load_dotenv
from fastapi import HTTPException
from pydantic import ValidationError
from models import PlanRequest, PlanDraftResponse, DraftBlockSchema, ChatGenerateResponse, ChatPlanBlock
from services.context_builder import ContextBuilder

# Load env variables safely
load_dotenv()
_OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

# Model to use 
_MODEL = os.getenv("OPENROUTER_MODEL", "z-ai/glm-4.5-air:free")


def generate_plan_with_context(user_id: str, request: PlanRequest) -> PlanDraftResponse:
    """
    Step 1: Build Context Payload
    Step 2: Inject to LLM Prompt
    Step 3: Pydantic Validation & Fallback
    """
    context = ContextBuilder.build(user_id)

    # If no API key is provided, gracefully fallback to the Mock logic
    if not _OPENROUTER_API_KEY or _OPENROUTER_API_KEY == "YOUR_OPENROUTER_API_KEY_HERE":
        print("[Cloud LLM] No API key found — using mock fallback.")
        return _generate_mock_fallback()

    system_prompt = """You are an expert Study Planner AI. Create a study plan strictly adhering to the user's constraints.
Output ONLY valid raw JSON with this exact schema — NO markdown, NO code fences:
{
  "plan_summary": "1-2 sentence summary of the strategy.",
  "warnings": ["optional warnings"],
  "blocks": [
    {
      "title": "Block title",
      "subject": "Subject name or null for breaks",
      "type": "study|break|revision|practice",
      "start_time": "HH:MM",
      "end_time": "HH:MM",
      "duration_minutes": 45,
      "priority": 1
    }
  ]
}"""

    user_message = f"""
USER CONSTRAINTS:
- Subjects: {request.subjects}
- Time Slots: {request.time_slots}
- Priorities: {request.priorities}
- Session Length: {request.session_length} minutes
- Date: {request.date}

SYSTEM CONTEXT:
- Weak Subjects (Prioritize!): {context['weak_subjects']}
- Pending Tasks: {context['pending_tasks']}
- Existing Plan Bounds: {context['existing_plan_bounds']}

Rules:
1. Only schedule within the requested time slots.
2. Study block ~{request.session_length} mins, then 15-min break (type='break', subject=null).
3. If total time < 45 min, use Quick Review mode (10-20 min micro-blocks).
4. Output ONLY raw JSON — no markdown wrapping.
"""

    for attempt in range(1, 3):  # 2 retries on parse failure (Guard #19)
        try:
            print(f"[Cloud LLM] Calling OpenRouter ({_MODEL}) — attempt {attempt}...")
            
            headers = {
                "Authorization": f"Bearer {_OPENROUTER_API_KEY}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "model": _MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user",   "content": user_message},
                ],
                "temperature": 0.2,
                "response_format": {"type": "json_object"}
            }

            response = requests.post(
                url="https://openrouter.ai/api/v1/chat/completions",
                headers=headers,
                data=json.dumps(payload),
                timeout=30
            )
            
            if response.status_code != 200:
                print(f"[Cloud LLM] OpenRouter HTTP Error {response.status_code}: {response.text}")
                if attempt == 2:
                    return _generate_mock_fallback(warning_msg=f"LLM API Error {response.status_code}")
                continue

            resp_json = response.json()
            raw = resp_json.get("choices", [{}])[0].get("message", {}).get("content", "")
            print(f"[Cloud LLM] Raw response: {raw[:200]}...")

            data = json.loads(raw)
            validated_plan = PlanDraftResponse(**data)
            print("[Cloud LLM] Plan validated successfully!")
            return validated_plan

        except json.JSONDecodeError as e:
            print(f"[Cloud LLM] JSON parse error (attempt {attempt}): {e}")
            if attempt == 2:
                return _generate_mock_fallback(warning_msg=f"LLM returned invalid JSON after 2 retries. Using fallback.")

        except Exception as e:
            print(f"[Cloud LLM Error] {type(e).__name__}: {e}")
            return _generate_mock_fallback(warning_msg=f"LLM Error: {str(e)[:80]}. Using fallback plan.")

    return _generate_mock_fallback()


def _generate_mock_fallback(warning_msg: str = "Using offline fallback plan.") -> PlanDraftResponse:
    """Mock plan generator used when API Key is missing or LLM fails."""
    blocks = [
        DraftBlockSchema(
            title="Physics Revision",
            subject="Physics",
            type="revision",
            start_time="09:00",
            end_time="09:45",
            duration_minutes=45,
            priority=1
        ),
        DraftBlockSchema(
            title="Break",
            type="break",
            start_time="09:45",
            end_time="10:00",
            duration_minutes=15
        ),
        DraftBlockSchema(
            title="Computer Science",
            subject="Computer Science",
            type="study",
            start_time="10:00",
            end_time="10:45",
            duration_minutes=45,
            priority=2
        )
    ]
    return PlanDraftResponse(
        plan_summary="Fallback plan generated.",
        warnings=[warning_msg],
        blocks=blocks
    )


def generate_chat_plan(message: str, user_id: str) -> ChatGenerateResponse:
    """
    Phase 1: Smart Chat -> AI Plan Output (Human + JSON)
    """
    model_to_use = os.getenv("OPENROUTER_MODEL", _MODEL)
    print(f"[Chat LLM] Request received for user {user_id}: {message}")
    print(f"[Chat LLM] Using model: {model_to_use}")

    if not _OPENROUTER_API_KEY or _OPENROUTER_API_KEY == "YOUR_OPENROUTER_API_KEY_HERE":
        print("[Chat LLM] No API key found — using fallback.")
        return _generate_chat_fallback("AI key missing, using default plan.")

    prompt = f"""User message:
{message}

Your task:

1. Generate a structured study plan with:
   * time blocks
   * subjects
   * checklist
   * short insights

2. ALSO generate structured JSON

Output format EXACTLY:

--- HUMAN ---
(text explanation)

--- JSON ---
[
{{
"title": "...",
"subject": "...",
"start_time": "HH:MM",
"end_time": "HH:MM",
"type": "study"
}}
]

Rules:
* JSON must be valid
* Include breaks if needed
* Keep times realistic
"""

    try:
        print(f"[Chat LLM] Calling OpenRouter ({model_to_use})...")
        
        headers = {
            "Authorization": f"Bearer {_OPENROUTER_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": model_to_use,
            "messages": [
                {"role": "system", "content": "You are a senior study planner assistant. Always follow the requested format exactly."},
                {"role": "user",   "content": prompt},
            ],
            "temperature": 0.7
        }

        response = requests.post(
            url="https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            data=json.dumps(payload),
            timeout=60
        )
        
        if response.status_code != 200:
            print(f"[Chat LLM Error] HTTP {response.status_code}: {response.text}")
            raise HTTPException(status_code=500, detail=f"OpenRouter HTTP {response.status_code}: {response.text[:150]}")

        resp_json = response.json()
        raw = resp_json.get("choices", [{}])[0].get("message", {}).get("content", "")
        print(f"[Chat LLM] AI response raw: {raw}")

        # Guard: Handle None response from model
        if not raw:
            print("[Chat LLM] AI returned empty/None response — using fallback.")
            return _generate_chat_fallback("AI returned an empty response, using default plan.")

        # Split human and JSON
        if "--- HUMAN ---" in raw and "--- JSON ---" in raw:
            parts = raw.split("--- JSON ---")
            human_part = parts[0].replace("--- HUMAN ---", "").strip()
            json_part = parts[1].strip()
            
            # Clean up potential markdown code blocks in json_part
            if "```json" in json_part:
                json_part = json_part.split("```json")[1].split("```")[0].strip()
            elif "```" in json_part:
                json_part = json_part.split("```")[1].strip()

            try:
                blocks_data = json.loads(json_part)
                # Filter out any extra keys LLM might have added that aren't in ChatPlanBlock
                blocks = []
                for b in blocks_data:
                    if isinstance(b, dict):
                        blocks.append(ChatPlanBlock(
                            title=b.get("title", "Study Session"),
                            subject=b.get("subject", "General"),
                            start_time=b.get("start_time", "09:00"),
                            end_time=b.get("end_time", "10:00"),
                            type=b.get("type", "study")
                        ))
                print(f"[Chat LLM] Parsed successfully. Blocks: {len(blocks)}")
                return ChatGenerateResponse(human=human_part, blocks=blocks)
            except Exception as e:
                print(f"[Chat LLM] JSON parse error: {e}")
                return _generate_chat_fallback(f"AI failed to produce valid JSON, using default plan. Error: {str(e)[:50]}")
        else:
            print("[Chat LLM] AI response missing markers.")
            return _generate_chat_fallback("AI response format invalid, using default plan.")

    except Exception as e:
        print(f"[Chat LLM Error] {e}")
        # Return a 500 error so the frontend catches it as a real error
        raise HTTPException(status_code=500, detail=f"AI provider error: {str(e)[:150]}")


def _generate_chat_fallback(human_msg: str) -> ChatGenerateResponse:
    return ChatGenerateResponse(
        human=human_msg,
        blocks=[
            ChatPlanBlock(
                title="Study Session",
                subject="General Study",
                start_time="09:00",
                end_time="10:00",
                type="study"
            )
        ]
    )
