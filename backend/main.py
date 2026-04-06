from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pydantic import BaseModel
from typing import List
from models import PredictRequest, PredictResponse, ClusterRequest, ClusterResponse, PlanRequest, PlanDraftResponse, ChatGenerateRequest, ChatGenerateResponse
from services.cloud_llm import generate_plan_with_context, generate_chat_plan
from services.roadmap_service import generate_roadmap
from services.daily_plan_service import generate_daily_plan

app = FastAPI(title="AI Study Planner Backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Backend is running"}

# ─── Phase 1: Roadmap Generation ────────────────────────────────────────────

class RoadmapRequest(BaseModel):
    skill: str

@app.post("/roadmap/generate")
def roadmap_generate_endpoint(req: RoadmapRequest):
    """Generate a structured learning roadmap for a given skill using the LLM."""
    return generate_roadmap(req.skill)

# ─── Phase 1.2: Daily Plan Generation ───────────────────────────────────────

@app.post("/daily-plan/generate")
def daily_plan_api(req: dict):
    """Generate a structured Day-N study plan from a given roadmap."""
    return generate_daily_plan(
        roadmap=req.get("roadmap", {}),
        day=req.get("day", 1),
        hours=req.get("hours", 4),
    )

class GenerateWithContextRequest(BaseModel):
    user_id: str
    request: PlanRequest

@app.post("/plan/generate-with-context", response_model=PlanDraftResponse)
def generate_plan_with_context_endpoint(payload: GenerateWithContextRequest):
    return generate_plan_with_context(payload.user_id, payload.request)

@app.post("/plan/chat-generate", response_model=ChatGenerateResponse)
def chat_generate_endpoint(payload: ChatGenerateRequest):
    return generate_chat_plan(payload.message, payload.user_id)

class PlanCommitRequest(BaseModel):
    user_id: str
    draft: PlanDraftResponse
    plan_date: str
    session_length: int

@app.post("/plan/commit")
def commit_plan_endpoint(payload: PlanCommitRequest):
    # Stub: Normally would write validated PlanDraftResponse natively to DB via Python,
    # but TRD notes Flutter's CommitService does SQL insertions natively,
    # We expose this stub for architectural compliance if needed.
    return {
        "plan_id": "commit-stub-id",
        "task_ids": ["task-1", "task-2"],
        "task_count": 2
    }

@app.post("/ml/predict", response_model=PredictResponse)
def predict_endpoint(request: PredictRequest):
    # Stubbed ML Predict endpoint
    return PredictResponse(
        predicted_scores={"overall": 82},
        confidence=0.85,
        feature_importances={"consistency": 0.4, "focus": 0.6}
    )

@app.post("/ml/cluster", response_model=ClusterResponse)
def cluster_endpoint(request: ClusterRequest):
    # Stubbed ML Cluster endpoint to unblock Flutter S03 layout fetching
    return ClusterResponse(
        clusters={
            "strong": ["Math"],
            "moderate": ["English"],
            "weak": ["Science"]
        },
        fallback_used=True
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8765, reload=True)
