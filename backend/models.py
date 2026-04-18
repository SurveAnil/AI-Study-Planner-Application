from pydantic import BaseModel, field_validator, model_validator
import re
from typing import List, Dict, Optional, Literal

# --- Cloud LLM Draft Parsing ---
TIME_RE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")  # 24h HH:MM only

class DraftBlockSchema(BaseModel):
    title:            str
    subject:          Optional[str] = None   # nullable for break blocks only
    type:             Literal["study","break","revision","practice","review"]
    start_time:       str    # MUST match HH:MM 24h
    end_time:         str    # MUST match HH:MM 24h
    duration_minutes: int    # 5–240
    priority:         Optional[Literal[1, 2, 3]] = None  # nullable for break only

    @field_validator("start_time", "end_time")
    @classmethod
    def valid_time(cls, v):
        if not TIME_RE.match(v):
            raise ValueError(f"Must be HH:MM 24h, got: {v!r}")
        return v

    @field_validator("duration_minutes")
    @classmethod
    def valid_duration(cls, v):
        if not (5 <= v <= 240):
            raise ValueError(f"Duration {v} out of range 5–240")
        return v

    @model_validator(mode="after")
    def times_match_duration(self):
        h1, m1 = map(int, self.start_time.split(":"))
        h2, m2 = map(int, self.end_time.split(":"))
        start = h1*60+m1; end = h2*60+m2
        if end < start: end += 24*60   # midnight crossing
        if abs((end - start) - self.duration_minutes) > 1:
            raise ValueError("duration_minutes does not match start/end diff")
        return self

    @model_validator(mode="after")
    def non_break_fields_required(self):
        if self.type != "break":
            if not self.subject:
                raise ValueError(f"subject required for type={self.type!r}")
            if self.priority is None:
                raise ValueError(f"priority required for type={self.type!r}")
        return self

class PlanDraftResponse(BaseModel):
    plan_summary: str
    warnings:     List[str] = []
    blocks:       List[DraftBlockSchema]

    @field_validator("blocks")
    @classmethod
    def at_least_one_study_block(cls, blocks):
        if not any(b.type in {"study","revision","practice","review"} for b in blocks):
            raise ValueError("Plan must contain at least one non-break block")
        return blocks

# --- Plan Generation ---
class PlanRequest(BaseModel):
    user_id: Optional[str] = None   # sent at top-level wrapper; optional here
    subjects: List[str]
    time_slots: List[List[str]]      # e.g. [["09:00", "11:00"]]
    priorities: Dict[str, int]       # e.g. {"Math": 1, "Science": 2}
    session_length: int = 45
    date: Optional[str] = None
    instruction: Optional[str] = None

class Block(BaseModel):
    subject: str
    type: str                    # "study" or "break" or "review"
    start: str
    end: str

class PlanResponse(BaseModel):
    plan_id: str
    blocks: List[Block]
    warnings: List[str] = []

# --- Machine Learning Predictions ---
class PredictRequest(BaseModel):
    user_id: str
    days_back: int

class PredictResponse(BaseModel):
    predicted_scores: Dict[str, int]
    confidence: float
    feature_importances: Dict[str, float]

# --- Machine Learning Clustering ---
class ClusterRequest(BaseModel):
    user_id: str

class ClusterResponse(BaseModel):
    clusters: Dict[str, List[str]] # strong, moderate, weak lists
    fallback_used: bool

class ChatPlanBlock(BaseModel):
    title: str
    subject: str
    start_time: str
    end_time: str
    type: str

class ChatGenerateRequest(BaseModel):
    message: str
    user_id: str

class ChatGenerateResponse(BaseModel):
    human: str
    blocks: List[ChatPlanBlock]
