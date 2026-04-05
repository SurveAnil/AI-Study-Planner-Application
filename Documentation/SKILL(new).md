---
name: ai-study-planner
version: 2.0
description: >
  Complete project source of truth for the AI Study Planner app.
  Consolidates PRD, TRD, Screen Layouts, Design System, Master
  Implementation Blueprint, and Cloud LLM Architecture Specification.
  Feed this file to any AI coding assistant before generating any code,
  UI, schema, or architecture decisions.
  Nothing in this file is repeated — each fact appears exactly once.
changelog:
  - v2.0: Replaced local LLM planning with Cloud LLM (online-only).
          Added Draft→Edit→Commit model. Added Adaptive Onboarding
          (Conversation Mode). Added ContextBuilder middleware.
          Clarified offline/online feature split. Added ManualPlan path.
---

# AI Study Planner — Master Project Skill v2.0

---

## PART 1 — PROJECT CONTEXT

### 1.1 Problem & Solution

Students currently juggle 3–4 separate tools: an AI chatbot for plan generation, a task manager (e.g. Todoist), a focus timer (e.g. Forest), and a flashcard app (e.g. Anki). These tools don't share data, don't automate revision, and don't learn from each other.

**This app** replaces all of them with a single platform that:
1. Generates AI-structured daily/weekly study plans using a Cloud LLM (online only)
2. Provides a full manual plan builder for offline or no-account use
3. Converts each committed plan block into an executable task with a built-in countdown timer
4. Auto-schedules spaced repetition revision at Day+2/7/14/30 after every completed session
5. Tracks consistency, focus quality, and completion rates — fully offline once plan is committed
6. Predicts exam performance using local ML and surfaces weak subjects using K-Means Clustering
7. Attaches PDFs, slides, and video links to tasks so students never leave the app during a session

### 1.2 Core Architecture Principle — Two Phases, One Boundary

```
PHASE 1: PLANNING (requires internet)         PHASE 2: EXECUTION (fully offline)
─────────────────────────────────────         ──────────────────────────────────
Cloud LLM generates draft                     SQLite drives everything
BLoC holds draft in memory only               Timer, revision, ML — no network
User edits draft freely                       Reports, analytics — no network
                    │
                    │  "Export to Device" — the one atomic commit boundary
                    │  Draft → SQLite tasks  (UUID-stamped, Pydantic-validated)
                    ▼
          PlanCommitted state
          Plan lives in SQLite forever
          Network never needed again for this plan
```

**The commit boundary is inviolable:**
- Before commit: plan exists only in `PlanDraftBloc` memory. Zero DB writes.
- After commit: plan lives only in SQLite. Cloud LLM is never called again for this plan.
- If commit fails (DB error): full `ROLLBACK`. Draft is preserved. User can retry.

---

### 1.3 Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | Flutter (Dart) | Android + Web from one codebase |
| State | `flutter_bloc` v8 | BLoC pattern only. One Bloc per feature domain. |
| Local DB | SQLite via `sqflite` | All persistent storage. No cloud dependency for execution. |
| HTTP | `dio` | Flutter → Python IPC to `127.0.0.1:8765`. Also Cloud LLM calls via Python. |
| DI | `get_it` | Service locator. All repos, blocs, services registered here. |
| Error | `dartz` — `Either<Failure, T>` | Every repository method returns this. No raw exceptions to UI. |
| UUID | `uuid` package | Client-side UUID v4 for every record. No integer PKs ever. |
| Connectivity | `connectivity_plus` | Guards all cloud features. Listens for reconnect to drain sync queue. |
| Battery | `battery_plus` | Guards LLM invocation. Block if < 20%. |
| Secure Storage | `flutter_secure_storage` | Cloud LLM API key. Never in SharedPreferences or SQLite. |
| Backend | Python 3.11 + FastAPI | Local server on `127.0.0.1:8765`. Algorithms, ML, LLM middleware. |
| ML | `scikit-learn` | Linear Regression (prediction) + K-Means (weak subject detection). Both run locally. |
| Cloud LLM | Google Gemini `gemini-1.5-flash` (primary) | **Online only.** Plan generation + onboarding chat. |
| Cloud LLM fallback | OpenAI `gpt-4o-mini` | If Gemini unavailable. Same online-only rule applies. |
| ~~Local LLM~~ | ~~Phi-3 Mini / llama.cpp~~ | **Removed in v2.0.** Replaced by Cloud LLM for plan generation. No local LLM remains. |

> **Why Cloud LLM?** The local Phi-3 Mini approach (v1.0) caused OOM kills on mid-range devices, 10–25s inference times, and hallucinated outputs. Moving to Cloud LLM solves all three. The tradeoff — requiring internet for plan generation — is explicitly surfaced to the user with a clear offline fallback (Manual Plan Builder).

---

## PART 2 — ONLINE vs OFFLINE FEATURE SPLIT

This is the most important table in this file. Every feature must be categorized before implementation.

### 2.1 Feature Availability Matrix

| Feature | Online Required? | If Offline | Data Source |
|---------|-----------------|-----------|------------|
| **AI Plan Generation** | ✅ YES — hard requirement | Show `OfflinePlanningState`. Two options: Go Online / Build Manually | Cloud LLM API |
| **Adaptive Onboarding (Chat)** | ✅ YES | Fall back to structured form (S02 form mode) | Cloud LLM API |
| **Manual Plan Builder** | ✅ NO — fully offline | Always available | User input → SQLite |
| **View today's schedule** | ✅ NO | Always available | SQLite tasks |
| **Start / pause / end study timer** | ✅ NO | Always available | SQLite + BLoC memory |
| **Write session data** | ✅ NO | Always available | SQLite study_sessions |
| **Auto-create revision tasks** | ✅ NO | Always available | SQLite revision_tasks |
| **View revision calendar** | ✅ NO | Always available | SQLite revision_tasks |
| **Mark revision done + log score** | ✅ NO | Always available | SQLite |
| **Progress reports (charts)** | ✅ NO | Always available | SQLite aggregations |
| **ML performance prediction** | ✅ NO | Always available | local scikit-learn |
| **Weak subject detection** | ✅ NO | Always available | local K-Means |
| **View/open attached resources** | ✅ NO | Always available | Local filesystem |
| **Settings, profile edit** | ✅ NO | Always available | SQLite users |
| **Cloud sync (future)** | ✅ YES | Queue writes locally, drain on reconnect | sync_queue → Remote API |

### 2.2 The Offline Planning Wall — Exact UX Behavior

When a user taps "Generate AI Plan" (or "New Plan" on the Home screen) and the device is offline, the app **must never silently fail or show a spinner**. It must immediately show the `OfflinePlanningState` screen.

```
User taps "Generate Plan"
        │
ConnectivityCheck (instant, before any screen transition)
        │
   ┌────┴────┐
ONLINE     OFFLINE
   │           │
Normal      OfflinePlanningState screen:
flow        ┌────────────────────────────────────────┐
            │  📡 You're currently offline            │
            │                                        │
            │  AI Plan Generation needs an           │
            │  internet connection to build your     │
            │  personalized study plan.              │
            │                                        │
            │  [🌐 Go Online — I'll wait]            │
            │    (polls every 5s, auto-continues     │
            │     when connectivity restored)        │
            │                                        │
            │  [📝 Build Plan Manually]              │
            │    (opens Manual Plan Builder)         │
            │                                        │
            │  [← Back]                              │
            └────────────────────────────────────────┘
```

**Rules for the Offline Planning Wall:**
- Show it instantly — zero delay. Check connectivity before navigating to S04.
- "Go Online — I'll wait" polls `ConnectivityPlus` every 5 seconds. When connection is restored, automatically dismiss wall and continue to AI plan generation.
- Show a small animated wifi icon with a scanning animation to indicate it's listening for connectivity.
- "Build Plan Manually" always works regardless of connectivity. It opens the Manual Plan Builder.
- Never show a loading spinner on the offline wall. It is a decision screen, not a loading screen.
- This same wall applies to Onboarding Chat mode — but offers "Fill Out Form Instead" instead of "Build Plan Manually".

---

## PART 3 — PLANNING MODES

There are exactly **two** plan creation paths. Every plan — regardless of how it was created — results in the same committed SQLite records and the same offline execution experience.

### 3.1 Path A — AI Plan Generation (Online Only)

```
PRE-CHECK: isOnline? → NO → OfflinePlanningState (see Part 2)
                     → YES → continue below

1. ContextBuilder.build(user_id)
   Queries SQLite: users + study_sessions + revision_tasks + performance_data
   Assembles ContextPayload (profile, recent history, weak subjects, streak)

2. POST /plan/generate-with-context
   Python middleware injects ContextPayload into LLM prompt
   Calls Cloud LLM API (Gemini primary, OpenAI fallback)
   Validates response with Pydantic (PlanDraftResponse schema)
   Returns to Flutter as PlanDraft state (MEMORY ONLY — no DB write)

3. User reviews draft in S04:
   - Edit any block (time, subject, type, priority)
   - Add or delete blocks
   - Drag to reorder
   - See AI's plan_summary and warnings

4. User taps "Export to Device":
   CommitService.commit()
   BEGIN TRANSACTION
   → INSERT study_plans (UUID)
   → INSERT tasks × N (UUID per block, Pydantic-validated)
   COMMIT (or ROLLBACK if any failure — draft preserved)
   → enqueue all records to sync_queue
   → emit PlanCommitted state
```

### 3.2 Path B — Manual Plan Builder (Always Available, Fully Offline)

The Manual Plan Builder is a structured form that lets students build a plan block-by-block without any AI. It produces **identical SQLite output** to the AI path.

```
User taps "Build Plan Manually" (from Offline Wall or directly from Home)

S04-Manual screen:
  - Date picker (required)
  - "Add Study Block" button → bottom sheet form:
      Title (text field)
      Subject (dropdown from user's subject list)
      Type (study | break | revision | practice | review)
      Start time (time picker, 24h)
      End time (time picker, 24h — auto-computes duration)
      Priority (1 High / 2 Medium / 3 Low)
      Resource link (optional text)
  - Blocks appear as cards below, reorderable, deletable
  - "Save Plan" button (same as "Export to Device" in AI path)

Commit: identical CommitService.commit() call — same transaction, same schema
Result: identical PlanCommitted state — same SQLite records
```

**Manual Plan Builder guards (same as AI path):**
- At least 1 non-break block required before saving
- Each block: `end_time > start_time` (or midnight-crossing handled)
- Subject must exist in `users.subjects[]`
- Title required for all non-break blocks

---

## PART 4 — CONTEXT BUILDER (Python Middleware)

### 4.1 What It Does

Before every Cloud LLM call, `ContextBuilder.build(user_id)` assembles a rich `ContextPayload` from local SQLite. This transforms a generic prompt into a deeply personalized one — the LLM knows the student's weak subjects, streak, exam countdown, and recent focus quality.

### 4.2 Data Fetched

| Field | SQLite Query | Purpose in Prompt |
|-------|-------------|------------------|
| `user.name`, `subjects[]`, `daily_goal_hours` | `users` table | Personalization, subject assignment |
| `user.long_term_goals` | `users.long_term_goals` | Strategic context ("I want to pass finals") |
| `user.learning_style` | `users.learning_style` | Block type weighting (visual → more review, practice → more problem sets) |
| `user.exam_date` → `days_until_exam` | Computed from `users.exam_date` | Urgency weighting (≤7 days → more practice blocks) |
| `recent_sessions[]` (last 7 days) | `study_sessions JOIN tasks JOIN study_plans` | Detect what was studied recently, avoid repetition |
| `subject_summaries[]` (last 14 days) | Aggregated from same JOIN | Hours per subject, avg focus_score per subject |
| `subject_summaries[].cluster_label` | `performance_data.cluster_label` | Identify weak subjects → prioritize in plan |
| `consistency_score` | `completed / max(planned, 1) × 100` (30-day) | Tell LLM if student is struggling with consistency |
| `current_streak_days` | Consecutive days with completed sessions | Motivational context |
| `pending_revisions_today` | `revision_tasks WHERE scheduled_date = today` | Insert revision block if > 0 |
| `overdue_revisions` | `revision_tasks WHERE scheduled_date < today AND status='pending'` | Priority escalation |

### 4.3 Prompt Injection Rules (LLM Must Follow)

These rules are injected into the system prompt on every call:

1. Prioritize subjects where `cluster_label = 'weak'` with more time blocks
2. If `overdue_revisions > 0`, insert at least one revision block first
3. If `days_until_exam <= 7`, reduce new-topic blocks; increase practice/review blocks
4. If a subject's avg `focus_score < 0.5`, reduce that subject's block to `session_length / 2` minutes
5. Respect `learning_style`: `visual` → add diagram/review time; `practice` → add problem-set blocks
6. Respect `study_window_start` and `study_window_end` from user profile

### 4.4 Context Cache Strategy

| Field | Cache TTL | Rationale |
|-------|-----------|-----------|
| User profile (name, goals, style) | Session-level (until app restart or settings save) | Changes rarely |
| Subject summaries, recent sessions | 5 minutes | May change if a session is completed mid-day |
| Pending/overdue revisions | No cache — always fresh | Changes as student marks revisions done |
| Consistency score, streak | No cache — cheap query | Always accurate |

---

## PART 5 — DRAFT→EDIT→COMMIT STATE MACHINE

### 5.1 BLoC State Definitions

```
PlanDraftInitial          → No draft exists. Show empty state + Generate/Manual buttons.
PlanDraftLoading          → Awaiting LLM response. Show loading with message.
PlanDraft                 → Draft in memory. Blocks editable. NOT in SQLite.
PlanDraftEditing          → Extends PlanDraft. Edit bottom sheet is open.
PlanDraftError            → LLM error OR commit error. preservedDraft non-null on commit fail.
PlanCommitInProgress      → Writing to SQLite. Draft visible beneath progress overlay.
PlanCommitted             → Written to SQLite. Terminal state. Show success + navigate.
OfflinePlanningState      → Network unavailable. Show offline wall with two options.
```

### 5.2 Critical State Rules

- `PlanDraft` and `PlanDraftEditing` **never write to SQLite**. Memory only.
- `PlanCommitted` is the **first and only state that writes to SQLite**.
- On `CommitPlanEvent` failure: emit `PlanDraftError(failure, preservedDraft: draft)`. **Never discard the draft.** User must be able to retry commit without re-generating.
- On `DiscardDraftEvent`: emit `PlanDraftInitial`. Nothing to clean up in DB — memory is wiped.
- `OfflinePlanningState` is emitted by `PlanDraftBloc` before attempting LLM call. No LLM call is ever made offline.

### 5.3 Events

| Event | Emitted From | Guard |
|-------|-------------|-------|
| `RequestAIPlanEvent` | Generate button tap | `isOnline` must be true — else emit `OfflinePlanningState` |
| `RequestManualPlanEvent` | Manual button tap | No network check needed |
| `EditBlockEvent(index, block)` | Block edit save | State must be `PlanDraft` |
| `AddBlockEvent(block, insertAfter)` | Add block button | State must be `PlanDraft` |
| `DeleteBlockEvent(index)` | Delete block | Min 1 non-break block must remain |
| `ReorderBlocksEvent(old, new)` | Drag-and-drop | State must be `PlanDraft` |
| `CommitPlanEvent` | "Export to Device" tap | Min 1 non-break block; all blocks valid |
| `DiscardDraftEvent` | Discard / Back tap | Show confirmation dialog if `hasUnsavedEdits` |
| `RetryConnectivityEvent` | Emitted by 5s poll on Offline Wall | Checks connection; if restored → `PlanDraftInitial` |

---

## PART 6 — DATABASE SCHEMA

### 6.1 Universal Column Rules

Every table must include these 4 columns — no exceptions:
```
created_at   TEXT NOT NULL        -- ISO-8601 UTC
updated_at   TEXT NOT NULL        -- ISO-8601 UTC, refresh on every UPDATE
sync_status  TEXT DEFAULT 'local' -- local | synced | conflict
is_deleted   INTEGER DEFAULT 0    -- soft delete: 1 = deleted, never hard-delete
```

All PKs are `TEXT` UUID v4. **Never use SQLite AUTOINCREMENT or integer IDs.**

On every record UPDATE: always set `updated_at = now().utc()` and `sync_status = 'local'`.

---

### 6.2 Full Schema (Migration_001 + Migration_002)

```sql
-- ── MIGRATION_001: CORE SCHEMA ──────────────────────────────────────

CREATE TABLE users (
  id                   TEXT PRIMARY KEY,  -- UUID v4
  name                 TEXT NOT NULL,
  email                TEXT,
  device_id            TEXT NOT NULL,     -- generated once at first launch
  created_at           TEXT NOT NULL,
  updated_at           TEXT NOT NULL,
  sync_status          TEXT DEFAULT 'local',
  is_deleted           INTEGER DEFAULT 0
);

CREATE TABLE study_plans (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id),
  plan_date   TEXT NOT NULL,
  total_time  INTEGER NOT NULL,  -- minutes (excludes break blocks)
  plan_source TEXT DEFAULT 'ai', -- 'ai' | 'manual'
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  sync_status TEXT DEFAULT 'local',
  is_deleted  INTEGER DEFAULT 0
);

CREATE TABLE tasks (
  id               TEXT PRIMARY KEY,
  plan_id          TEXT NOT NULL REFERENCES study_plans(id),
  title            TEXT NOT NULL,
  subject          TEXT NOT NULL,
  start_time       TEXT NOT NULL,       -- HH:MM 24h
  end_time         TEXT NOT NULL,       -- HH:MM 24h
  planned_duration INTEGER NOT NULL,    -- minutes
  status           TEXT DEFAULT 'pending', -- pending | in_progress | done | skipped
  resource_link    TEXT,
  priority         INTEGER DEFAULT 2,   -- 1=High  2=Medium  3=Low
  block_type       TEXT DEFAULT 'study', -- study | break | revision | practice | review
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  sync_status      TEXT DEFAULT 'local',
  is_deleted       INTEGER DEFAULT 0
);

CREATE TABLE study_sessions (
  id               TEXT PRIMARY KEY,
  task_id          TEXT NOT NULL REFERENCES tasks(id),
  actual_duration  INTEGER NOT NULL,    -- seconds
  planned_duration INTEGER NOT NULL,    -- seconds
  pause_count      INTEGER DEFAULT 0,
  focus_score      REAL,                -- 0.0–1.0, computed at session end
  completed        INTEGER DEFAULT 0,
  started_at       TEXT NOT NULL,
  ended_at         TEXT,
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  sync_status      TEXT DEFAULT 'local',
  is_deleted       INTEGER DEFAULT 0
);

CREATE TABLE revision_tasks (
  id             TEXT PRIMARY KEY,
  user_id        TEXT NOT NULL REFERENCES users(id),
  topic          TEXT NOT NULL,
  subject        TEXT NOT NULL,
  scheduled_date TEXT NOT NULL,
  revision_type  TEXT NOT NULL,  -- revision | practice | test | final
  status         TEXT DEFAULT 'pending',
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  sync_status    TEXT DEFAULT 'local',
  is_deleted     INTEGER DEFAULT 0
);

CREATE TABLE performance_data (
  id             TEXT PRIMARY KEY,
  user_id        TEXT NOT NULL REFERENCES users(id),
  subject        TEXT NOT NULL,
  practice_score INTEGER,              -- 0–100, user-entered
  test_score     INTEGER,
  session_count  INTEGER DEFAULT 0,
  cluster_label  TEXT,                 -- strong | moderate | weak (cached from K-Means)
  recorded_at    TEXT NOT NULL,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  sync_status    TEXT DEFAULT 'local',
  is_deleted     INTEGER DEFAULT 0
);

-- Buffers all SQLite writes for future cloud sync
CREATE TABLE sync_queue (
  id          TEXT PRIMARY KEY,
  table_name  TEXT NOT NULL,
  record_id   TEXT NOT NULL,
  operation   TEXT NOT NULL,   -- INSERT | UPDATE | DELETE
  payload     TEXT NOT NULL,   -- full JSON blob
  created_at  TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error  TEXT
);

-- ── MIGRATION_002: ONBOARDING + PLANNING FIELDS ──────────────────────

ALTER TABLE users ADD COLUMN subjects            TEXT NOT NULL DEFAULT '[]';
-- JSON array: ["Java","DBMS","OS"]

ALTER TABLE users ADD COLUMN daily_goal_hours    REAL NOT NULL DEFAULT 2.0;
ALTER TABLE users ADD COLUMN study_window_start  TEXT NOT NULL DEFAULT '09:00';
ALTER TABLE users ADD COLUMN study_window_end    TEXT NOT NULL DEFAULT '21:00';

ALTER TABLE users ADD COLUMN long_term_goals     TEXT;
-- Free text: "I want to pass my final exams and get into college"

ALTER TABLE users ADD COLUMN learning_style      TEXT NOT NULL DEFAULT 'mixed';
-- Enum: visual | reading | practice | mixed

ALTER TABLE users ADD COLUMN exam_date           TEXT;
-- YYYY-MM-DD or NULL

ALTER TABLE users ADD COLUMN onboarding_complete INTEGER NOT NULL DEFAULT 0;
-- 0 = not complete, 1 = complete
-- App checks this on launch to route to Onboarding vs Dashboard
```

---

### 6.3 Migration Runner

```dart
class DatabaseHelper {
  static const int _dbVersion = 2; // increment on every schema change

  static Future<Database> openDb() async {
    return openDatabase('study_planner.db',
      version: _dbVersion,
      onCreate:  (db, v)    => _runMigrations(db, 0, v),
      onUpgrade: (db, o, n) => _runMigrations(db, o, n),
    );
  }

  static Future<void> _runMigrations(Database db, int from, int to) async {
    final migrations = {
      1: Migration_001_core_schema.up,
      2: Migration_002_onboarding_fields.up,
      // Never edit above entries. Always add new entries below.
    };
    for (int v = from + 1; v <= to; v++) await migrations[v]!(db);
  }
}
```

---

## PART 7 — PYTHON BACKEND API CONTRACT

All Flutter ↔ Python communication is HTTP to `127.0.0.1:8765`. All calls: 15-second timeout, wrapped in try/catch, return `Either<Failure, T>`.

| Endpoint | Method | Request | Response | Error Codes |
|----------|--------|---------|---------|------------|
| `/plan/generate-with-context` | POST | `{ user_id, request: PlanRequest }` | `{ plan_summary, warnings[], blocks[] }` (PlanDraftResponse) | `422` validation, `503` LLM unavailable, `408` timeout |
| `/plan/commit` | POST | `{ user_id, draft, plan_date, session_length }` | `{ plan_id, task_ids[], task_count }` | `422` schema fail, `500` DB error |
| `/ml/predict` | POST | `{ user_id, days_back: int }` | `{ predicted_scores{}, confidence, feature_importances{} }` | `422` if session_count < 5 |
| `/ml/cluster` | POST | `{ user_id }` | `{ clusters: { strong[], moderate[], weak[] }, fallback_used: bool }` | Always `200` |
| `/onboarding/chat` | POST | `{ history[], new_message }` | `{ reply: str, turn_count: int }` | `503` LLM unavailable |
| `/onboarding/extract-profile` | POST | `{ history[] }` | `{ status: complete\|incomplete, profile?, missing_fields? }` | `422` if confidence < 0.7 |
| `/onboarding/commit` | POST | `{ device_id, profile, email? }` | `{ user_id: str }` | `500` DB error |
| `/health` | GET | — | `{ llm_loaded, db_ok, battery_ok, cloud_llm_reachable }` | `500` critical |

> **Removed endpoint:** `POST /ai/nlp-parse` — the local LLM NLP parsing endpoint is removed in v2.0. All natural language input now goes through `/plan/generate-with-context`.
> **Removed endpoint:** `POST /plan/generate` — replaced by `/plan/generate-with-context` which includes context injection.

---

## PART 8 — LLM OUTPUT SCHEMA (Pydantic)

The Python middleware validates every LLM response against `PlanDraftResponse` before returning to Flutter. LLM output is **never written to SQLite directly** — always through `CommitService` after validation.

```python
# middleware/schemas/plan_draft_schema.py
import re
from pydantic import BaseModel, field_validator, model_validator
from typing import Optional, Literal

TIME_RE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")  # 24h HH:MM only

class DraftBlockSchema(BaseModel):
    title:            str
    subject:          Optional[str] = None   # nullable for break blocks only
    type:             Literal["study","break","revision","practice","review"]
    start_time:       str    # MUST match HH:MM 24h
    end_time:         str    # MUST match HH:MM 24h
    duration_minutes: int    # 5–240
    priority:         Optional[Literal[1, 2, 3]] = None  # nullable for break only
    resource_hint:    Optional[str] = None

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
    warnings:     list[str] = []
    blocks:       list[DraftBlockSchema]

    @field_validator("blocks")
    @classmethod
    def at_least_one_study_block(cls, blocks):
        if not any(b.type in {"study","revision","practice","review"} for b in blocks):
            raise ValueError("Plan must contain at least one non-break block")
        return blocks
```

### LLM JSON Field → SQLite Column Mapping

| LLM Field | Type | SQLite Column | Transformation |
|-----------|------|--------------|---------------|
| `title` | `str` | `tasks.title` | None |
| `subject` | `str \| null` | `tasks.subject` | Validated vs `users.subjects[]`. Break → `"break"`. |
| `type` | enum | `tasks.block_type` | Stored as TEXT |
| `start_time` | `"HH:MM"` | `tasks.start_time` | Regex-validated. 24h only. |
| `end_time` | `"HH:MM"` | `tasks.end_time` | Validated + midnight-crossing handled. |
| `duration_minutes` | `int` | `tasks.planned_duration` | Cross-checked vs start/end diff (±1 min tolerance). |
| `priority` | `1\|2\|3\|null` | `tasks.priority` | Null only for break blocks. Defaults to 3. |
| `resource_hint` | `str\|null` | `tasks.resource_link` | Optional hint text if no file attached. |
| *(generated)* | `uuid4()` | `tasks.id` | Never from LLM. Always fresh at commit. |
| *(generated)* | `uuid4()` | `tasks.plan_id` | Created for parent `study_plans` record. |
| *(generated)* | `datetime.utcnow()` | `created_at`, `updated_at` | Always server-side UTC. Never from LLM. |
| *(default)* | `'pending'` | `tasks.status` | Always pending at commit. |
| *(default)* | `'local'` | `tasks.sync_status` | Promoted to 'synced' by SyncQueue later. |

---

## PART 9 — ADAPTIVE ONBOARDING (Conversation Mode)

### 9.1 Architecture

On first launch, `AppLaunchRouter` checks:
1. Is there a `users` record with `onboarding_complete = 1`? → Go to Dashboard
2. No user record + network available → **Conversation Mode** (Cloud LLM chat)
3. No user record + network unavailable → **Structured Form** (offline fallback)
4. User record exists but `onboarding_complete = 0` → **Structured Form** (resume)

### 9.2 Conversation Mode Flow

The student types naturally (e.g. "I'm studying for my Java exam in 3 weeks, also have DBMS"). The LLM asks follow-up questions one at a time (study window, learning style, daily goal). After 4–5 turns, the LLM summarizes the profile as a review card. Student confirms or corrects, then the profile is committed to `users`.

**Key rules:**
- Conversation history is kept in `OnboardingBloc` memory — never persisted until final commit
- Each turn calls `POST /onboarding/chat` (stateless — full history sent each time)
- After student confirms: call `POST /onboarding/extract-profile` (extracts structured data from history)
- If `confidence < 0.7` OR `missing_fields` not empty: do NOT commit — AI asks for the missing data
- Final commit: `POST /onboarding/commit` → writes to `users` table with all Migration_002 columns

### 9.3 New Users Table Columns (from Migration_002)

| Column | Type | Default | Source |
|--------|------|---------|--------|
| `subjects` | `TEXT` (JSON array) | `'[]'` | Onboarding + Settings |
| `daily_goal_hours` | `REAL` | `2.0` | Onboarding + Settings |
| `study_window_start` | `TEXT` (HH:MM) | `'09:00'` | Onboarding + Settings |
| `study_window_end` | `TEXT` (HH:MM) | `'21:00'` | Onboarding + Settings |
| `long_term_goals` | `TEXT` | `NULL` | Onboarding conversation |
| `learning_style` | `TEXT` | `'mixed'` | Onboarding (inferred by LLM) |
| `exam_date` | `TEXT` (YYYY-MM-DD) | `NULL` | Onboarding + Settings |
| `onboarding_complete` | `INTEGER` | `0` | Set to `1` on final commit |

---

## PART 10 — FLUTTER ARCHITECTURE

### 10.1 Layer Structure

```
Flutter UI (BlocBuilder / BlocListener only — zero business logic)
    │ Events
BLoC / Cubit (one per feature — handles all logic)
    │ Either<Failure, T>
Repository (abstract interface — BLoC never touches data directly)
    │                         │
LocalDataSource          RemoteDataSource (future)
(sqflite + FastAPI)      (REST API)
```

### 10.2 BLoC Map

| Class | Type | Key Events | States | Screens |
|-------|------|-----------|--------|---------|
| `PlanDraftBloc` | Bloc | `RequestAIPlanEvent`, `RequestManualPlanEvent`, `EditBlockEvent`, `AddBlockEvent`, `DeleteBlockEvent`, `ReorderBlocksEvent`, `CommitPlanEvent`, `DiscardDraftEvent`, `RetryConnectivityEvent` | `PlanDraftInitial`, `PlanDraftLoading`, `PlanDraft`, `PlanDraftEditing`, `PlanDraftError`, `PlanCommitInProgress`, `PlanCommitted`, `OfflinePlanningState` | S04 |
| `OnboardingBloc` | Bloc | `StartConversationEvent`, `SendMessageEvent`, `ConfirmProfileEvent`, `EditProfileFieldEvent` | `OnboardingInitial`, `OnboardingConversing`, `OnboardingProfileExtracted`, `OnboardingComplete`, `OnboardingError` | S01, S02 |
| `ScheduleCubit` | Cubit | `loadDay(date)`, `navigateDay(delta)`, `completeTask(id)` | `ScheduleState { tasks, date, completionRing }` | S05 |
| `SessionBloc` | Bloc | `StartSession`, `PauseSession`, `ResumeSession`, `EndSession` | `SessionIdle`, `SessionRunning`, `SessionPaused`, `SessionComplete` | S06 |
| `RevisionCalendarCubit` | Cubit | `loadMonth(month)`, `markDone(revisionId)` | `CalendarState { events, selectedDay, upcoming }` | S07 |
| `ProgressCubit` | Cubit | `loadReport(period)`, `selectSubject(id)` | `ProgressState { consistency, charts, trend }` | S08 |
| `SubjectAnalyticsCubit` | Cubit | `loadSubject(id)` | `AnalyticsState { cluster, metrics, history }` | S09 |
| `PredictionCubit` | Cubit | `runPrediction()`, `adjustInput(feature, delta)` | `PredictionState { scores, confidence, whatIf }` | S12 |
| `ResourcesCubit` | Cubit | `loadAll()`, `filter(type)`, `addResource(file)` | `ResourcesState { files, activeFilter }` | S10 |
| `SettingsCubit` | Cubit | `updateGoal(h)`, `toggleDarkMode()` | `SettingsState { prefs }` | S11 |

### 10.3 Repository Pattern

```dart
// Abstract — the only thing BLoC ever sees
abstract class StudyPlanRepository {
  Future<Either<Failure, PlanDraft>>  generateAIPlan(PlanRequest request);
  Future<Either<Failure, PlanDraft>>  createManualDraft(ManualPlanRequest request);
  Future<Either<Failure, PlanCommittedResult>> commitDraft(PlanDraft draft);
  Future<Either<Failure, List<Task>>> getTasksForDate(DateTime date);
  Future<Either<Failure, Unit>>       saveTask(Task task);
}

// Impl routes between local and remote; handles connectivity check for AI
class StudyPlanRepositoryImpl implements StudyPlanRepository {
  final LocalStudyPlanSource  _local;
  final RemoteStudyPlanSource? _remote;
  final NetworkInfo            _network;
  final SyncQueueService       _syncQueue;

  @override
  Future<Either<Failure, PlanDraft>> generateAIPlan(PlanRequest req) async {
    // HARD CHECK — never call LLM offline
    if (!await _network.isConnected) {
      return Left(NetworkFailure('offline'));  // BLoC emits OfflinePlanningState
    }
    return _local.generateAIPlan(req);  // calls FastAPI which calls Cloud LLM
  }

  @override
  Future<Either<Failure, PlanDraft>> createManualDraft(ManualPlanRequest req) async {
    // No network check — always available
    return _local.createManualDraft(req);
  }
}
```

### 10.4 Folder Structure

```
lib/
  features/
    plan_draft/
      bloc/          ← PlanDraftBloc (events, states, bloc)
      data/          ← StudyPlanRepository (abstract + impl), LocalSource
      models/        ← DraftBlock, PlanRequest, ManualPlanRequest
      presentation/  ← S04 screen (BlocBuilder only — zero logic)
        widgets/     ← DraftBlockCard, EditBlockSheet, OfflinePlanningWall
    session/         ← same structure
    onboarding/      ← OnboardingBloc, conversation UI, profile form
    schedule/
    progress/
    revision/
    resources/
    settings/
  core/
    network/         ← NetworkInfo (ConnectivityPlus wrapper)
    database/        ← DatabaseHelper, migrations/
    di/              ← injection_container.dart
    error/           ← Failure class hierarchy
    router/          ← AppLaunchRouter
    sync/            ← SyncQueueService
    constants/       ← AppColors, AppSpacing, AppTextStyles
```

### 10.5 Non-Negotiable Code Rules

| Rule | Detail |
|------|--------|
| No `setState()` for business logic | BLoC states only |
| No SQLite queries in widget files | Always via Repository |
| No raw exceptions to UI | Map every throw to a `Failure` subclass |
| No hardcoded colors or spacing | Use `AppColors` / `AppSpacing` constants |
| No integer PKs | Always `Uuid().v4()` |
| No inline Python calls | Widget → Bloc → Repository → DataSource → HTTP |
| No LLM calls when offline | `isOnline` checked in repository before every cloud call |
| Every repository returns `Either<Failure, T>` | `dartz` package |
| Every UPDATE refreshes `updatedAt` + `syncStatus = 'local'` | No exceptions |

---

## PART 11 — ERROR HANDLING

### 11.1 Failure Class Hierarchy

```dart
abstract class Failure { final String message; const Failure(this.message); }

// Network / connectivity
class NetworkFailure         extends Failure { ... }  // offline — triggers OfflinePlanningState
class CloudLLMFailure        extends Failure { final int? statusCode; ... }
class LLMTimeoutFailure      extends Failure { final int elapsedMs; ... }
class LLMParseFailure        extends Failure { final String rawOutput; ... }

// Data layer
class DatabaseFailure        extends Failure { ... }
class SyncConflictFailure    extends Failure { final String localId; ... }

// Algorithm / input
class InsufficientTimeFailure  extends Failure { final int availableMinutes; ... }
class InsufficientDataFailure  extends Failure { final int sessionCount; ... }
class NoSubjectsFailure        extends Failure { ... }
class InvalidBlockFailure      extends Failure { final int blockIndex; ... }

// Onboarding
class OnboardingIncompleteFailure extends Failure { final List<String> missingFields; ... }

// Removed in v2.0: LLMUnavailableFailure, LowBatteryFailure (no local LLM)
```

### 11.2 Failure → UX Response Map

| Failure | Trigger | UX Response | Recovery |
|---------|---------|------------|---------|
| `NetworkFailure` (plan) | `isOnline = false` when tapping Generate | `OfflinePlanningState` screen: "Go Online" + "Build Manually" | Auto-dismiss when connectivity restored (5s poll) |
| `NetworkFailure` (onboarding) | `isOnline = false` at first launch | Show structured form (offline onboarding fallback) | Offer to redo as chat when online |
| `CloudLLMFailure` | Non-200 from Cloud LLM API | SnackBar: "AI service unavailable. Try again or build plan manually." | Retry button + Manual Plan option |
| `LLMTimeoutFailure` | > 15s elapsed | SnackBar: "Taking too long. Try again or build manually." | Same as above |
| `LLMParseFailure` | Pydantic validation fails after 2 retries | SnackBar: "AI returned unexpected output. Try again." | Retry or Manual |
| `NoSubjectsFailure` | `subjects[]` empty | Red border on subject picker + inline message | Block form submit |
| `InsufficientTimeFailure` | available < 15 min | SnackBar: "Under 15 min — switch to Quick Review?" + Yes/No | Yes → micro-blocks |
| `InvalidBlockFailure` | Block has `end ≤ start` or missing subject | Highlight invalid block card in red, inline error message | Block commit until fixed |
| `InsufficientDataFailure` | < 5 sessions for ML | Empty state: "Complete 5 sessions to unlock" + X/5 bar | Disable ML tab |
| `DatabaseFailure` | SQLite write fails | "Could not save. Try again." (no raw error shown) | Retry ×3 (1s/2s/4s backoff) |
| `SyncConflictFailure` | Same UUID, different `updated_at` from two devices | `ConflictResolutionSheet` with both versions side-by-side | User picks "Keep Mine" / "Use Newer" |
| `OnboardingIncompleteFailure` | Extraction confidence < 0.7 | AI continues conversation asking for missing fields | Do not commit until complete |

---

## PART 12 — SYNC STRATEGY

### 12.1 Every SQLite Write Must Do Three Things

```dart
// 1. Write record with sync_status = 'local', updated_at = now().utc()
// 2. Call enqueue immediately after successful write
await _syncQueue.enqueue(tableName, recordId, SyncOp.insert, payload);
// 3. ConnectivityPlus listener calls drainQueue() on reconnect
```

### 12.2 Conflict Resolution

| Rule | When | Resolution |
|------|------|-----------|
| **Last-Write-Wins** | `updated_at` timestamps differ by > 1s | Keep later `updated_at`. Soft-delete other. Silent. |
| **User-Prompt** | `updated_at` within 1s (simultaneous edit) | Show `ConflictResolutionSheet`. User picks. |
| **Append-Only Bypass** | `STUDY_SESSIONS`, `PERFORMANCE_DATA`, `SYNC_QUEUE` | Append-only — never updated after creation. No conflicts possible. |

### 12.3 UUID Generation

```dart
import 'package:uuid/uuid.dart';
const _uuid = Uuid();

// Every new record:
final id = _uuid.v4();  // Never use SQLite AUTOINCREMENT

// Every UPDATE:
record.copyWith(updatedAt: DateTime.now().toUtc(), syncStatus: SyncStatus.local);
```

---

## PART 13 — SCREENS

### 13.1 Navigation Structure

```
Bottom Navigation Bar (5 tabs):
  Tab 1 — Home (S03)
  Tab 2 — Schedule (S05)
  Tab 3 — Progress (S08)
  Tab 4 — Resources (S10)
  Tab 5 — Settings (S11)

First-launch flow: S01 (Onboarding) → S02 (Profile) → S03

Sub-screens:
  S04 Generate/Manual Plan  ← from S03 Home
  S06 Active Session        ← from S05 task Start button
  S07 Revision Calendar     ← from S03 Home
  S09 Subject Analytics     ← from S08 subject tap
  S12 Performance Pred.     ← from S03 or S08
```

### 13.2 Screen Quick Reference

| ID | Screen | Tab/Access | Key DB Writes |
|----|--------|-----------|--------------|
| S01 | Onboarding (slides or chat) | First launch | None until S02 commit |
| S02 | Create Profile (form or confirm card) | S01 → or Settings edit | `users` INSERT |
| S03 | Home Dashboard | Tab 1 | Read-only |
| S04 | Generate/Manual Plan | Home CTA | `study_plans` + `tasks` INSERT (on commit only) |
| S05 | Today's Schedule | Tab 2 | `tasks.status` UPDATE |
| S06 | Active Study Session | S05 Start | `study_sessions` INSERT + `revision_tasks` ×4 INSERT |
| S07 | Revision Calendar | Home CTA | `revision_tasks.status` UPDATE |
| S08 | Progress Report | Tab 3 | Read-only |
| S09 | Subject Analytics | S08 tap | Read-only + `performance_data` INSERT |
| S10 | Resources | Tab 4 | `tasks.resource_link` UPDATE |
| S11 | Settings | Tab 5 | `users` UPDATE |
| S12 | Performance Prediction | Home / S08 | Read-only |

### 13.3 S04 — Plan Screen (Updated for v2.0)

S04 now contains two modes and one gate, all managed by `PlanDraftBloc`:

| Mode | When Shown | What User Sees |
|------|-----------|---------------|
| **Empty state** (`PlanDraftInitial`) | No draft exists | Two CTAs: "✨ Generate with AI" + "📝 Build Manually". Connectivity badge (online/offline indicator). |
| **Offline wall** (`OfflinePlanningState`) | User taps AI generate while offline | Full offline wall (see Part 2.2). "Go Online — I'll wait" + "Build Plan Manually". |
| **AI Loading** (`PlanDraftLoading`) | Awaiting LLM response | Animated progress card: "Building your context..." → "Generating your plan...". No cancel available during context build (fast). Cancel available during LLM call. |
| **Draft review** (`PlanDraft`) | Plan generated or manual blocks added | Scrollable block cards + plan summary + warnings banner. FAB: "Export to Device". Top-right: "Discard". |
| **Block editing** (`PlanDraftEditing`) | Block card tapped | Bottom sheet: time pickers, subject dropdown, type/priority selectors. "Save" + "Cancel". |
| **Committing** (`PlanCommitInProgress`) | "Export to Device" tapped | Overlay: "Saving to your device...". Draft visible beneath. No user action available. |
| **Success** (`PlanCommitted`) | Commit succeeded | Confirmation bottom sheet: "✓ Plan saved! X tasks created." + "View Schedule →". |
| **Error — generate** (`PlanDraftError`, no preserved draft) | LLM or network error | Error card with message + "Try Again" + "Build Manually instead". |
| **Error — commit** (`PlanDraftError`, preserved draft) | SQLite error during commit | SnackBar: "Could not save. Your draft is still here." + "Retry" button. Draft fully preserved. |

### 13.4 S06 — Active Session: Critical Data Writes

On `EndSession`, `SessionBloc` MUST write all of:
```dart
// Write to STUDY_SESSIONS:
actual_duration  = elapsed seconds
planned_duration = task.planned_duration × 60 (convert to seconds)
pause_count      = number of PauseSession events
focus_score      = clamp((actual/planned) × (1 − pause_count × 0.1), 0.0, 1.0)
completed        = 1
ended_at         = DateTime.now().utc()

// Update TASKS:
status     = 'done'
updated_at = DateTime.now().utc()

// Create 4 REVISION_TASKS (Day+2, +7, +14, +30):
revision_type = revision | practice | test | final
```

---

## PART 14 — ALGORITHMS

### 14.1 Study Planning

**Input validation (enforce before calling Python):**
- `subjects[]` not empty → `NoSubjectsFailure`
- Total available minutes `>= 15` → `InsufficientTimeFailure`
- Parse `time_slots` as `List<(start, end)>` tuples (supports non-contiguous windows)
- If `end_time < start_time`: add 24h before computing duration (midnight-crossing)
- `isOnline` must be true for AI path — else `NetworkFailure` → `OfflinePlanningState`

**Algorithm (Python, runs on context-injected LLM output):**
1. Session length = 45 min (configurable: 30/45/60 min in Settings)
2. If available < 45 min but >= 15 min → Quick Review mode (10/15/20 min micro-blocks)
3. Create study block → insert 15-min break → check `remaining_time > 0` before each append
4. Single subject → skip priority weighting (avoids `ZeroDivisionError`)
5. After-break check: `remaining_time > 0` before inserting

### 14.2 Spaced Repetition

Auto-triggered on `SessionBloc → EndSession`. Creates 4 `REVISION_TASKS`:
```
Day+2  → revision
Day+7  → practice
Day+14 → test
Day+30 → final
```
Calendar color codes: Revision=Blue, Practice=Orange, Test=Red, Final=Purple.

### 14.3 Consistency Score

```
Consistency = completed_sessions / max(planned_sessions, 1) × 100
```

| Score | Level |
|-------|-------|
| 90–100% | Master |
| 70–89% | Consistent |
| 50–69% | Moderate |
| < 50% | Needs Improvement |

### 14.4 Performance Prediction (Linear Regression — local)

**Minimum:** 5 completed sessions. All features written by timer system.

```
predicted_score = w1×study_hours + w2×revision_count + w3×completion_rate + w4×focus_score
focus_score = clamp((actual/planned) × (1 − pause_count × 0.1), 0.0, 1.0)
```

### 14.5 Weak Subject Detection (K-Means — local)

**Minimum:** 3 subjects with ≥ 1 data point. Fallback if < 3 or all scores identical → threshold comparison. Always returns 200. `fallback_used` flag in response.

---

## PART 15 — EDGE CASE & GUARD CHECKLIST

Every guard must be implemented. None are optional.

| # | Context | Condition | Required Action |
|---|---------|-----------|----------------|
| 1 | AI plan generation | `isOnline = false` | Emit `NetworkFailure`. BLoC emits `OfflinePlanningState`. Show wall with two options. |
| 2 | AI plan generation | `subjects.isEmpty` | Emit `NoSubjectsFailure`. Red border on subject picker. |
| 3 | Plan generation | `totalMinutes < 15` | Emit `InsufficientTimeFailure`. Offer Quick Review mode. |
| 4 | Plan generation | `totalMinutes == 45` | Check `remaining_time > 0` before break. Avoid negative break duration. |
| 5 | Plan generation | Single subject | Skip priority weighting. |
| 6 | Plan generation | Window crosses midnight | Add 24h to `end_time` before computing duration. |
| 7 | Plan generation | Non-contiguous time slots | Parse as `List<(start, end)>`. Loop per segment. |
| 8 | Plan generation | Rapid repeated taps | Debounce: ignore new event while `PlanDraftLoading`. |
| 9 | Draft commit | 0 non-break blocks | Block commit. Message: "Add at least one study block." |
| 10 | Draft commit | Block `end_time <= start_time` (same day, no crossing) | Highlight block red. Message: "End time must be after start time." Block commit. |
| 11 | Draft commit | Block subject not in `users.subjects[]` | Message: "Subject not found in your profile. Add it in Settings." Block commit. |
| 12 | Draft commit | SQLite transaction fails | Full `ROLLBACK`. Emit `PlanDraftError(preservedDraft: draft)`. Never lose draft. |
| 13 | Manual plan | 0 blocks at save | Block save. Same message as guard 9. |
| 14 | ML prediction | `session_count < 5` | Emit `InsufficientDataFailure`. Disable tab. Show X/5 counter. |
| 15 | K-Means | `subject_count < 3` | Bypass K-Means. Use threshold. `fallback_used: true`. |
| 16 | K-Means | All scores identical | Fallback: recommend subject with fewest revisions. |
| 17 | Consistency score | `planned_sessions == 0` | Denominator = `max(1, planned)`. No divide-by-zero. |
| 18 | Cloud LLM | Timeout > 15s | Emit `LLMTimeoutFailure`. Show retry + manual option. |
| 19 | Cloud LLM | Pydantic validation fails (2 retries exhausted) | Emit `LLMParseFailure`. Show retry + manual option. |
| 20 | Onboarding chat | `isOnline = false` at launch | Show structured form fallback. Offer to redo as chat on reconnect. |
| 21 | Onboarding extraction | `confidence < 0.7` OR `missing_fields` not empty | Do not commit. Continue conversation. AI asks for missing data. |
| 22 | Connectivity poll (offline wall) | Reconnect detected | Auto-dismiss offline wall. Proceed to `PlanDraftInitial`. |
| 23 | Session timer | Pause tap | Increment `pause_count` in memory. Write to DB on `EndSession` only. |
| 24 | `EndSession` | Any termination path | Always write full session record + 4 revision tasks. No partial writes. |
| 25 | SQLite write (any) | Failure | Retry ×3 with 1s/2s/4s backoff. Surface `DatabaseFailure` after 3rd fail. |
| 26 | Sync queue | 5th failed retry | Escalate to `SyncConflictFailure`. Show `ConflictResolutionSheet`. |

---

## PART 16 — SPRINT BUILD ORDER

Complete each sprint fully before starting the next.

**Sprint 0 — Infrastructure (before any feature work)**
1. Cloud LLM API key: store in `flutter_secure_storage`. Inject to Python via environment variable. Never log.
2. Add Python dependencies: `pydantic v2`, `google-generativeai` or `openai`, `cachetools`.
3. Create `NetworkInfo` service wrapping `ConnectivityPlus`. Every cloud feature checks this first.
4. Set up all FastAPI endpoints (returning mock data): `/plan/generate-with-context`, `/plan/commit`, `/onboarding/chat`, `/onboarding/extract-profile`, `/onboarding/commit`, `/ml/predict`, `/ml/cluster`, `/health`.
5. Implement `AppLaunchRouter`: route to onboarding-chat, onboarding-form, or dashboard based on user record + connectivity.

**Sprint 1 — Foundation**
6. SQLite schema: all 7 tables + Migration_001 (core) + Migration_002 (onboarding fields). UUID PKs, all 4 universal columns.
7. `get_it` DI: register all repos, data sources, blocs.
8. All abstract Repository interfaces implemented.
9. `AppColors`, `AppSpacing`, `AppTextStyles` — zero inline values anywhere.
10. `DraftBlock` model + `PlanDraftResponse` Pydantic schema.

**Sprint 2 — Onboarding**
11. `OnboardingBloc`: all states + `StartConversationEvent`, `SendMessageEvent`, `ConfirmProfileEvent`.
12. `/onboarding/chat` endpoint: system prompt + full history pass-through.
13. `/onboarding/extract-profile`: Pydantic extraction + confidence threshold + `missing_fields` check.
14. `/onboarding/commit`: writes users record with all Migration_002 columns.
15. Conversation Mode UI: chat bubbles, typing indicator, profile preview card, Confirm CTA, Skip link.
16. Structured form fallback (offline onboarding): identical data, form fields instead of chat.

**Sprint 3 — Draft→Commit Loop**
17. `ContextBuilder.build()`: all 5 queries (user, sessions, summaries, consistency, revisions). 5-min cache.
18. `/plan/generate-with-context`: context injection + Cloud LLM call + Pydantic validation + 2-retry on parse failure.
19. `PlanDraftBloc`: all 9 events, full state machine, `OfflinePlanningState` on offline detect.
20. `OfflinePlanningWall` widget: "Go Online — I'll wait" with 5s poll + "Build Plan Manually" button.
21. Draft editing UI: block cards, edit bottom sheet (time pickers, subject dropdown, type/priority), add/delete/reorder.
22. Manual Plan Builder: block-by-block form, identical CommitService call.
23. `CommitService`: atomic SQLite transaction (`BEGIN / ROLLBACK / COMMIT`), UUID stamping, sync_queue enqueue. Guards 9–12.

**Sprint 4 — Execution Loop**
24. `SessionBloc`: start/pause/resume/end + write complete `STUDY_SESSIONS` record with all fields.
25. Wire spaced repetition: on `SessionComplete` → 4 `REVISION_TASKS` created.
26. `ScheduleCubit` + S05 timeline + day navigation.
27. `RevisionCalendarCubit` + `markDone()` → writes `REVISION_TASKS.status='done'`.
28. All execution guards (17, 23, 24, 25, 26) at repository layer.

**Sprint 5 — Intelligence & Polish**
29. `/ml/predict` + `InsufficientDataFailure` empty state (X/5 counter).
30. `/ml/cluster` + K-Means fallback for < 3 subjects.
31. "Log Score" flow on S07 → writes `PERFORMANCE_DATA` + updates `cluster_label`.
32. `SyncQueueService.enqueue()` on every SQLite write.
33. `ConnectivityPlus` listener → `drainQueue()` on reconnect.
34. `ConflictResolutionSheet` for simultaneous-edit conflicts.
35. Global error handler: all `Failure` subclasses → standardized SnackBar / empty state / offline wall.

---

## PART 17 — DESIGN SYSTEM TOKENS

### 17.1 Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#4F6FE8` | `#818CF8` | CTAs, active tabs |
| `primaryContainer` | `#EEF2FF` | `#312E81` | Chip backgrounds, banners |
| `secondary` | `#34D399` | `#6EE7B7` | Completion, streaks |
| `secondaryContainer` | `#D1FAE5` | `#064E3B` | Done states |
| `background` | `#F8FAFC` | `#0F172A` | Screen background |
| `surface` | `#FFFFFF` | `#1E293B` | Cards, dialogs |
| `surfaceVariant` | `#F1F5F9` | `#334155` | Input fills |
| `outline` | `#E2E8F0` | `#475569` | Borders |
| `onBackground` | `#0F172A` | `#F1F5F9` | Primary text |
| `onSurface` | `#1E293B` | `#E2E8F0` | Card text |
| `onSurfaceVariant` | `#64748B` | `#94A3B8` | Secondary text |
| `error` | `#EF4444` | `#FCA5A5` | Validation errors |
| `errorContainer` | `#FEF2F2` | `#7F1D1D` | Error backgrounds |
| `success` | `#10B981` | `#6EE7B7` | Completions |
| `warning` | `#F59E0B` | `#FCD34D` | Deadlines, caution |

**Offline wall specific:** Use `surfaceVariant` background + `#94A3B8` icon + `onSurfaceVariant` body text. Never red — offline is not an error, it's a condition.

### 17.2 Typography

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayMedium` | 45sp | 700 | Timer MM:SS (DM Mono) |
| `headlineLarge` | 32sp | 700 | Screen titles |
| `headlineMedium` | 28sp | 600 | Card headings |
| `titleMedium` | 16sp | 500 | Task names |
| `bodyLarge` | 16sp | 400 | Primary body |
| `bodyMedium` | 14sp | 400 | Descriptions |
| `bodySmall` | 12sp | 400 | Captions, metadata |
| `labelLarge` | 14sp | 500 | Button labels |

**Fonts:** `Plus Jakarta Sans` (UI) · `DM Mono` (timers, stats, code values only)

### 17.3 Spacing

Base unit: **4px**. All values must be multiples of 4. Use `AppSpacing` constants only.

| Token | Value | Usage |
|-------|-------|-------|
| `space4` | 16dp | Screen margin, card padding |
| `space6` | 24dp | Between unrelated components |
| `space8` | 32dp | Between major screen sections |

Screen margin: 16dp · Min touch target: 48×48dp · Card padding: 16dp · BottomNav height: 80dp

### 17.4 Key Components

| Component | Key Specs |
|-----------|-----------|
| `FilledButton` (primary) | bg: `primary`, radius: 12dp, height: 52dp, elevation: 0 |
| `OutlinedButton` | border: 1dp `primary`, radius: 12dp, height: 48dp |
| `Elevated Card` | radius: 16dp, elevation: 2, shadow: `0 2 8 #00000014` |
| `Hero Card` | bg: `#4F6FE8`, radius: 20dp, elevation: 4 |
| `TextField` (focused) | fill: `primaryContainer`, 2dp `primary` indicator |
| `NavigationBar` | height: 80dp, active: `primary`, inactive: `onSurfaceVariant` |
| `Chip` | height: 32dp, radius: 16dp, selected: `primaryContainer` |
| `SnackBar` | radius: 12dp, bg: `#1E293B`, floating, 16dp margin |

**Icons:** Material Symbols Rounded (`material_symbols_icons` ^4.x). Rounded style only. `fill: 0` inactive → `fill: 1` active. Animate with `AnimatedSwitcher(200ms, Curves.easeInOut)`.

### 17.5 Design Principles

1. **Clarity Over Complexity** — One primary purpose per screen. No decorative elements without meaning.
2. **Flow State Preservation** — Never interrupt active sessions. All interactions ≤ 2 taps. Batch notifications outside sessions.
3. **Progress as Motivation** — Streaks and charts are first-class. Use green/amber for progress — never red for progress indicators.
4. **Intelligent Accessibility** — Dark mode is core. WCAG AA contrast. Min touch target 48×48dp. Support `TextScaler` — test at 1.0× and 1.5×.

---

## PART 18 — VIBE CODING PROMPT BLOCK

Copy this block verbatim into Antigravity (or any AI coding tool) at the start of every session:

```
## AI Study Planner — Coding Context v2.0

### STACK
- Flutter (Dart), flutter_bloc v8, sqflite, dio, get_it, dartz, uuid,
  connectivity_plus, flutter_secure_storage
- Python 3.11, FastAPI on 127.0.0.1:8765, scikit-learn, pydantic v2
- Cloud LLM: Google Gemini gemini-1.5-flash (primary), OpenAI gpt-4o-mini (fallback)
- NO local LLM. Phi-3 Mini / llama.cpp was removed in v2.0.
- SQLite: all PKs = TEXT UUID v4. Every table has: created_at, updated_at (ISO UTC),
  sync_status (local|synced|conflict), is_deleted (0|1)

### THE ONE MOST IMPORTANT RULE
AI Plan Generation requires internet. ALWAYS check isOnline before calling
/plan/generate-with-context. If offline → emit NetworkFailure → BLoC emits
OfflinePlanningState → show wall with "Go Online" + "Build Manually" options.
NEVER show a spinner when offline. NEVER attempt a cloud call when offline.

### PATTERNS — NEVER DEVIATE
- State: BLoC pattern only. One Bloc per feature. No setState() for business logic.
- Data: Repository Pattern. All DB access via Repository. Return Either<Failure, T>.
- Python: HTTP to 127.0.0.1:8765. Always try/catch. Timeout 15s.
  Map failures to Failure subclasses. Never propagate raw exceptions to UI.
- Draft state: PlanDraft is memory-only. NEVER write to SQLite until CommitPlanEvent.
  On commit failure: ROLLBACK all DB writes. Preserve draft. Let user retry.
- Spacing/Colors: AppSpacing and AppColors constants only. No inline values.

### TWO PLAN CREATION PATHS
1. AI Path (online only):  RequestAIPlanEvent → check isOnline → context inject →
   Cloud LLM → PlanDraft state → user edits → CommitPlanEvent → SQLite
2. Manual Path (always):   RequestManualPlanEvent → user builds blocks →
   CommitPlanEvent → same CommitService → same SQLite schema

### BACKEND ENDPOINTS (v2.0)
- POST /plan/generate-with-context → {user_id, request} → PlanDraftResponse
- POST /plan/commit                → {user_id, draft, plan_date} → {plan_id, task_ids[]}
- POST /ml/predict                 → {user_id, days_back} → {predicted_scores{}, confidence}
- POST /ml/cluster                 → {user_id} → {clusters:{strong[],moderate[],weak[]}}
- POST /onboarding/chat            → {history[], new_message} → {reply, turn_count}
- POST /onboarding/extract-profile → {history[]} → {status, profile?, missing_fields?}
- POST /onboarding/commit          → {device_id, profile} → {user_id}
- GET  /health                     → {db_ok, cloud_llm_reachable}

### GUARDS — CHECK BEFORE EVERY CLOUD CALL
- isOnline MUST be true (else NetworkFailure → OfflinePlanningState)
- subjects.isNotEmpty AND totalMinutes >= 15 (plan generation)
- sessionCount >= 5 (ML prediction, else InsufficientDataFailure)
- At least 1 non-break block before CommitPlanEvent (else InvalidBlockFailure)

### SESSION END — ALWAYS WRITE ALL OF THESE
- STUDY_SESSIONS: actual_duration, planned_duration, pause_count, focus_score,
  completed=1, ended_at
- TASKS: status='done', updated_at=now()
- REVISION_TASKS: 4 new records at Day+2, +7, +14, +30

### DO NOT GENERATE
- Any code that calls Cloud LLM without first checking isOnline
- StatefulWidgets with business logic
- SQLite queries in widget files
- Raw exceptions reaching the UI
- Hardcoded colors or spacing values inline
- Integer primary keys
- Direct commits to SQLite from PlanDraft state (memory only until CommitPlanEvent)
- Any reference to Phi-3 Mini, llama.cpp, or llama-cpp-python (removed in v2.0)
```

---

*AI Study Planner — Master Project Skill v2.0*
*Sources: PRD · TRD · Screen Layouts · Design System · Master Implementation Blueprint · Cloud LLM Architecture Specification*
*Single source of truth — every fact appears exactly once — no duplication across sections*
