---
name: ai-study-planner
version: 1.0
description: >
  Complete project source of truth for the AI Study Planner app.
  Consolidates PRD, TRD, Screen Layouts, Design System, and Master
  Implementation Blueprint. Feed this file to any AI coding assistant
  before generating any code, UI, schema, or architecture decisions.
  Nothing in this file is repeated — each fact appears exactly once.
---

# AI Study Planner — Master Project Skill

---

## PART 1 — PROJECT CONTEXT

### 1.1 Problem & Solution

Students currently juggle 3–4 separate tools: an AI chatbot for plan generation, a task manager (e.g. Todoist), a focus timer (e.g. Forest), and a flashcard app (e.g. Anki). These tools don't share data, don't automate revision, and don't learn from each other.

**This app** replaces all of them with a single offline-first mobile platform that:
1. Generates AI-structured daily/weekly study plans from natural-language or form input
2. Converts each plan block into an executable task with a built-in countdown timer
3. Auto-schedules spaced repetition revision at Day+2/7/14/30 after every completed session
4. Tracks consistency, focus quality, and completion rates
5. Predicts exam performance using Linear Regression and surfaces weak subjects using K-Means Clustering
6. Attaches PDFs, slides, and video links to tasks so students never leave the app during a session

### 1.2 Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | Flutter (Dart) | Android + Web from one codebase |
| State | `flutter_bloc` v8 | BLoC pattern only. One Bloc per feature domain. |
| Local DB | SQLite via `sqflite` | All offline storage. No cloud dependency. |
| HTTP | `dio` | Flutter → Python IPC. All calls to `127.0.0.1:8765`. |
| DI | `get_it` | Service locator. All repositories and blocs registered here. |
| Error | `dartz` — `Either<Failure, T>` | Every repository method returns this. No raw exceptions. |
| UUID | `uuid` package | Client-side UUID v4 for every record. No integer PKs ever. |
| Connectivity | `connectivity_plus` | Triggers sync queue drain on reconnect. |
| Battery | `battery_plus` | Guards LLM invocation. Block if < 20%. |
| Backend | Python 3.11 + FastAPI | Local server on `127.0.0.1:8765`. Runs algorithms and ML. |
| ML | `scikit-learn` | Linear Regression (prediction) + K-Means (weak subject detection). |
| Local LLM | Phi-3 Mini via `llama-cpp-python` | Optional. NLP plan parsing only. |

---

## PART 2 — ALGORITHMS

### 2.1 Study Planning Algorithm

**Endpoint:** `POST /plan/generate`

**Input validation (enforce before calling Python):**
- `subjects[]` must not be empty → emit `NoSubjectsFailure`
- Total available minutes must be `>= 15` → emit `InsufficientTimeFailure`
- Parse `time_slots` as `List<(start, end)>` tuples — not a single range — to support non-contiguous windows (e.g. 3–4 PM and 7–8 PM)
- If `end_time < start_time`, add 24h to `end_time` before computing duration (midnight-crossing windows)

**Logic:**
1. For each time segment, compute available minutes
2. Session length = 45 min (configurable in Settings: 30/45/60 min). If available time < 45 min but >= 15 min → use Quick Review mode (10/15/20 min micro-blocks)
3. Create study block → insert 15-min break → check `remaining_time > 0` before each subsequent append
4. Assign subjects to blocks by priority weight. If `subject_count == 1`, skip weighting (avoids `ZeroDivisionError`)
5. Attach `resource_link` if subject has an associated resource

**Output:** `{ plan_id, blocks: [{ start, end, subject, type: study|break|practice|review }], warnings[] }`

**Debounce rule:** Ignore repeated `GeneratePlanEvent` taps while `PlanLoading` state is active. Never spawn concurrent Python calls.

---

### 2.2 Spaced Repetition Algorithm

Auto-triggered on `SessionBloc → EndSession` event. Creates 4 `REVISION_TASKS` records immediately.

```
Day+0  → Study        (current session — already logged)
Day+2  → Revision
Day+7  → Practice
Day+14 → Test
Day+30 → Final Revision
```

```python
revision_intervals = [2, 7, 14, 30]
for interval in revision_intervals:
    create_revision_task(topic, subject, date + timedelta(days=interval))
```

Revision tasks are type-labeled: `revision | practice | test | final`. The Revision Calendar color-codes them: Revision=Blue, Practice=Orange, Test=Red, Final=Purple.

---

### 2.3 Consistency Score

```
Consistency Score = completed_sessions / max(planned_sessions, 1)
```

Denominator minimum = 1 (prevents `ZeroDivisionError` on days with no planned sessions).

| Score | Gamification Level |
|-------|--------------------|
| 90–100% | Master |
| 70–89% | Consistent |
| 50–69% | Moderate |
| < 50% | Needs Improvement |

---

### 2.4 Performance Prediction (Linear Regression)

**Endpoint:** `POST /ml/predict`
**Minimum data:** 5 completed `STUDY_SESSIONS` — else emit `InsufficientDataFailure` and disable the Prediction tab.

```
predicted_score = w1×study_hours + w2×revision_count + w3×completion_rate + w4×focus_score
```

All 5 input features are written to the DB by the timer system. **This is the critical data bridge — none of these are optional writes:**

| Feature | Written To | Written When | Formula/Source |
|---------|-----------|-------------|---------------|
| `actual_duration` | `STUDY_SESSIONS` | `EndSession` event | Elapsed seconds (end − start) |
| `planned_duration` | `STUDY_SESSIONS` | `EndSession` event | From task record |
| `pause_count` | `STUDY_SESSIONS` | Incremented on each `PauseSession` event | Counter |
| `focus_score` | `STUDY_SESSIONS` | `EndSession` event | `clamp((actual/planned) × (1 − pause_count × 0.1), 0.0, 1.0)` |
| `revision_count` | Aggregated from `REVISION_TASKS` | When `status='done'` is set | `COUNT WHERE status='done'` |
| `task_completion_rate` | Aggregated | Python side | `completed_tasks / planned_tasks` (30-day window) |
| `practice_score` | `PERFORMANCE_DATA` | User taps "Log Score" on Revision Calendar | 0–100 integer |

---

### 2.5 Weak Subject Detection (K-Means)

**Endpoint:** `POST /ml/cluster`
**Minimum data:** 3 distinct subjects with ≥ 1 data point each.

**Fallback conditions (always return 200, never error):**
- `subject_count < 3` → skip K-Means, use simple threshold comparison
- All scores identical (cluster variance < threshold) → recommend subject with fewest revision sessions

**Output:** `{ clusters: { strong[], moderate[], weak[] }, fallback_used: bool }`

---

### 2.6 NLP Plan Parsing (Optional LLM)

**Endpoint:** `POST /ai/nlp-parse`

```
Input:  "I want to study Java and DBMS today from 3–6 PM"
Output: { time_slots: [["15:00","18:00"]], subjects: ["Java","DBMS"], goal: "Study", confidence: 0.91 }
```

Always validate LLM output against a strict Pydantic schema before passing to the planning algorithm. If validation fails → emit `LLMParseFailure` and show structured form.

---

## PART 3 — DATABASE SCHEMA

### 3.1 Universal Column Rules

Every table must include these 4 columns — no exceptions:
```
created_at   TEXT NOT NULL        -- ISO-8601 UTC
updated_at   TEXT NOT NULL        -- ISO-8601 UTC, refresh on every UPDATE
sync_status  TEXT DEFAULT 'local' -- local | synced | conflict
is_deleted   INTEGER DEFAULT 0    -- soft delete: 1 = deleted, never hard-delete
```

All PKs are `TEXT` UUID v4. **Never use SQLite `AUTOINCREMENT` or integer IDs.**

On every record UPDATE: always set `updated_at = now().utc()` and `sync_status = 'local'`.

---

### 3.2 Full Schema

```sql
CREATE TABLE users (
  id          TEXT PRIMARY KEY,  -- UUID v4
  name        TEXT NOT NULL,
  email       TEXT,
  device_id   TEXT NOT NULL,     -- generated once at first launch, stored in shared_preferences
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  sync_status TEXT DEFAULT 'local',
  is_deleted  INTEGER DEFAULT 0
);

CREATE TABLE study_plans (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id),
  plan_date   TEXT NOT NULL,
  total_time  INTEGER NOT NULL,  -- minutes
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
  completed        INTEGER DEFAULT 0,   -- boolean
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
  test_score     INTEGER,              -- 0–100
  session_count  INTEGER DEFAULT 0,
  recorded_at    TEXT NOT NULL,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  sync_status    TEXT DEFAULT 'local',
  is_deleted     INTEGER DEFAULT 0
);

-- New table: buffers all writes for future cloud sync
CREATE TABLE sync_queue (
  id          TEXT PRIMARY KEY,
  table_name  TEXT NOT NULL,
  record_id   TEXT NOT NULL,
  operation   TEXT NOT NULL,   -- INSERT | UPDATE | DELETE
  payload     TEXT NOT NULL,   -- full JSON blob of the record
  created_at  TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error  TEXT
);
```

---

### 3.3 Migration Runner

```dart
// core/database/database_helper.dart
class DatabaseHelper {
  static const int _dbVersion = 1; // increment for every schema change

  static Future<Database> openDb() async {
    return openDatabase(
      'study_planner.db',
      version: _dbVersion,
      onCreate:  (db, v)    => _runMigrations(db, 0, v),
      onUpgrade: (db, o, n) => _runMigrations(db, o, n),
    );
  }

  static Future<void> _runMigrations(Database db, int from, int to) async {
    final migrations = {
      1: Migration_001_initial_schema.up,
      // 2: Migration_002_add_xyz.up,   ← add future migrations here only
    };
    for (int v = from + 1; v <= to; v++) {
      await migrations[v]!(db);
    }
  }
}
```

**Rule:** Never edit existing migration files. Always add a new numbered file.

---

## PART 4 — FLUTTER ARCHITECTURE

### 4.1 Layer Overview

```
┌──────────────────────────────────────────────────┐
│  Flutter UI  — BlocBuilder / BlocListener only    │
│  Zero business logic. Zero direct DB calls.       │
└───────────────────────┬──────────────────────────┘
                        │  Events / States
┌───────────────────────▼──────────────────────────┐
│  BLoC / Cubit — one per feature domain            │
│  Calls repository methods only.                   │
└───────────┬──────────────────────────────────────┘
            │  Either<Failure, T>
┌───────────▼──────────────────────────────────────┐
│  Repository (abstract interface)                  │
│  Impl decides: local or remote                    │
└────────┬─────────────────────────────────────────┘
         │ sqflite                     │ dio (future)
┌────────▼──────────┐       ┌──────────▼──────────┐
│ LocalDataSource   │       │ RemoteDataSource      │
│ SQLite + FastAPI  │       │ REST API (future)     │
└───────────────────┘       └─────────────────────┘
```

---

### 4.2 BLoC Map — One Per Feature

| Class | Type | Key Events / Methods | States | Screens |
|-------|------|---------------------|--------|---------|
| `PlanGeneratorBloc` | Bloc | `GeneratePlanEvent`, `RegeneratePlanEvent`, `SavePlanEvent` | `PlanInitial`, `PlanLoading`, `PlanGenerated`, `PlanError` | S04 |
| `ScheduleCubit` | Cubit | `loadDay(date)`, `navigateDay(delta)`, `completeTask(id)` | `ScheduleState { tasks, date, completionRing }` | S05 |
| `SessionBloc` | Bloc | `StartSession`, `PauseSession`, `ResumeSession`, `EndSession` | `SessionIdle`, `SessionRunning`, `SessionPaused`, `SessionComplete` | S06 |
| `RevisionCalendarCubit` | Cubit | `loadMonth(month)`, `markDone(revisionId)` | `CalendarState { events, selectedDay, upcoming }` | S07 |
| `ProgressCubit` | Cubit | `loadReport(period)`, `selectSubject(id)` | `ProgressState { consistency, charts, trend }` | S08 |
| `SubjectAnalyticsCubit` | Cubit | `loadSubject(id)` | `AnalyticsState { cluster, metrics, history }` | S09 |
| `PredictionCubit` | Cubit | `runPrediction()`, `adjustInput(feature, delta)` | `PredictionState { scores, confidence, whatIf }` | S12 |
| `ResourcesCubit` | Cubit | `loadAll()`, `filter(type)`, `addResource(file)` | `ResourcesState { files, activeFilter }` | S10 |
| `SettingsCubit` | Cubit | `updateGoal(h)`, `toggleDarkMode()`, `toggleAI(feature)` | `SettingsState { prefs, aiFlags }` | S11 |
| `AuthCubit` | Cubit | `setupProfile(data)`, `loadProfile()` | `ProfileState { user, isSetup }` | S02 |

---

### 4.3 Repository Pattern

```dart
// Abstract interface — the only thing BLoC ever touches
abstract class StudyPlanRepository {
  Future<Either<Failure, StudyPlan>>   generatePlan(PlanRequest request);
  Future<Either<Failure, List<Task>>>  getTasksForDate(DateTime date);
  Future<Either<Failure, Unit>>        saveTask(Task task);
}

// Concrete implementation — routes between local and remote
class StudyPlanRepositoryImpl implements StudyPlanRepository {
  final LocalStudyPlanSource  _local;
  final RemoteStudyPlanSource? _remote; // null = offline-only mode
  final NetworkInfo            _network;
  final SyncQueueService       _syncQueue;

  @override
  Future<Either<Failure, StudyPlan>> generatePlan(PlanRequest req) async {
    final result = await _local.generatePlan(req);
    if (_network.isConnected && _remote != null) {
      _syncQueue.enqueue('study_plans', result, SyncOp.insert);
    }
    return result;
  }
}
```

---

### 4.4 Dependency Injection (get_it)

```dart
// core/di/injection_container.dart
Future<void> init() async {
  // Repositories — singletons
  sl.registerLazySingleton<StudyPlanRepository>(() =>
    StudyPlanRepositoryImpl(
      local:     sl<LocalStudyPlanSource>(),
      remote:    sl<RemoteStudyPlanSource>(), // swap to null for pure offline build
      network:   sl<NetworkInfo>(),
      syncQueue: sl<SyncQueueService>(),
    ),
  );

  // Data sources
  sl.registerLazySingleton(() => LocalStudyPlanSource(db: sl<DatabaseHelper>()));
  sl.registerLazySingleton(() => RemoteStudyPlanSource(client: sl<DioClient>()));

  // BLoCs — factories (new instance per route)
  sl.registerFactory(() => PlanGeneratorBloc(repository: sl()));
  sl.registerFactory(() => SessionBloc(repository: sl()));
  // ... repeat for all blocs
}
```

---

### 4.5 Folder Structure

```
lib/
  features/
    plan_generator/
      bloc/          ← PlanGeneratorBloc  (events, states, bloc class)
      data/          ← StudyPlanRepository (abstract + impl), LocalSource
      presentation/  ← Screen widget — BlocBuilder only, zero logic
    session/         ← same structure
    progress/        ← same structure
    revision/
    resources/
    settings/
    auth/
  core/
    network/         ← DioClient, interceptors
    database/        ← DatabaseHelper, migrations/
    di/              ← injection_container.dart
    error/           ← Failure class hierarchy
    ai/              ← ModelGateway, LocalLLMService, CloudAIService
    sync/            ← SyncQueueService
    constants/       ← AppColors, AppSpacing, AppTextStyles
```

---

### 4.6 Non-Negotiable Code Rules

| Rule | Detail |
|------|--------|
| No `setState()` for business logic | BLoC states only |
| No SQLite in widget files | Always via Repository |
| No raw exceptions to UI | Map every throw to a `Failure` subclass |
| No hardcoded colors or spacing | Use `AppColors` / `AppSpacing` constants only |
| No integer PKs | Always `uuid` package — `Uuid().v4()` |
| No inline Python calls | Always: Widget → Bloc → Repository → LocalDataSource → HTTP |
| Every repository returns `Either<Failure, T>` | Using `dartz` package |
| Every UPDATE refreshes `updatedAt` | Set `syncStatus = SyncStatus.local` too |

---

## PART 5 — PYTHON BACKEND CONTRACT

The Flutter app communicates with Python **only** via HTTP to `127.0.0.1:8765`. Timeout = 15 seconds on all calls.

| Endpoint | Method | Request Body | Response | Error Codes |
|----------|--------|-------------|---------|------------|
| `/plan/generate` | POST | `{ user_id, subjects[], time_slots[], priorities{} }` | `{ plan_id, blocks[], warnings[] }` | `422` validation fail, `507` insufficient time |
| `/ml/predict` | POST | `{ user_id, days_back: int }` | `{ predicted_scores{}, confidence, feature_importances{} }` | `422` if session_count < 5 |
| `/ml/cluster` | POST | `{ user_id }` | `{ clusters: { strong[], moderate[], weak[] }, fallback_used: bool }` | Always `200` |
| `/ai/nlp-parse` | POST | `{ raw_text: str, device_tier: str }` | `{ time_slots[], subjects[], goal, confidence }` | `503` LLM unavailable, `408` timeout |
| `/health` | GET | — | `{ llm_loaded, db_ok, battery_ok }` | `500` critical failure |

---

## PART 6 — ERROR HANDLING

### 6.1 Failure Class Hierarchy

```dart
// core/error/failures.dart
abstract class Failure { final String message; const Failure(this.message); }

// Data
class DatabaseFailure      extends Failure { ... }
class NetworkFailure       extends Failure { ... }
class SyncConflictFailure  extends Failure { final String localId; ... }

// Algorithm
class InsufficientTimeFailure  extends Failure { final int availableMinutes; ... }
class InsufficientDataFailure  extends Failure { final int sessionCount; ... }
class NoSubjectsFailure        extends Failure { ... }

// AI / LLM
class LLMUnavailableFailure  extends Failure { ... }
class LLMTimeoutFailure      extends Failure { final int elapsedMs; ... }
class LLMParseFailure        extends Failure { final String rawOutput; ... }
class LowBatteryFailure      extends Failure { final int batteryLevel; ... }
class CloudAIFailure         extends Failure { final int statusCode; ... }
```

---

### 6.2 Every Failure Has a Required UX Response

| Failure | Trigger | UX Response | Recovery |
|---------|---------|------------|---------|
| `NoSubjectsFailure` | `subjects[]` empty | Red border on subject picker + inline message | Block form submit |
| `InsufficientTimeFailure` | available < 15 min | SnackBar: "Under 15 min — switch to Quick Review?" + Yes/No | Yes → regenerate with micro-blocks |
| `InsufficientDataFailure` | < 5 sessions | Empty state: "Complete 5 sessions to unlock" + X/5 progress bar | Disable ML tab; show CTA to start session |
| `LLMUnavailableFailure` | RAM < 2 GB or OOM | Banner: "AI parsing unavailable. Use form instead." Auto-switch. | Permanently hide NLP input for this device |
| `LLMTimeoutFailure` | > 15s elapsed | "Taking too long. Switched to quick mode." | 3+ timeouts → disable LLM for session |
| `LowBatteryFailure` | Battery < 20% | "Low battery (X%). AI input disabled." | Block LLM; show form only |
| `DatabaseFailure` | SQLite write fails | "Could not save. Try again." (no raw error) | Retry 3× with 1s / 2s / 4s backoff |
| `SyncConflictFailure` | Same UUID, different `updated_at` from two devices | `ConflictResolutionSheet`: both versions side-by-side | User picks "Keep Mine" / "Use Newer" |
| `NetworkFailure` | Cloud or sync API fails | Silent. Queue to `sync_queue`. Offline badge in AppBar. | Drain queue on `ConnectivityPlus` reconnect |

---

## PART 7 — AI ROUTING (ModelGateway)

### 7.1 Decision Flow

```
User inputs text
       │
Pre-flight checks:
  1. subjects >= 1?
  2. battery > 20%?
  3. device RAM >= 3 GB?
       │
 ANY FAIL ─────────────────► Structured Form UI
       │
  ALL PASS
       │
 LLM already loaded?
  YES ──► Invoke local LLM (15s timeout)
           │
        OK ──► Validate Pydantic schema ──► Planning algorithm
        FAIL / TIMEOUT
           │
     WiFi / 5G available?
      YES ──► Cloud API ──► Validate ──► Planning algorithm
      NO  ──► Structured Form UI

  NO (not loaded) ──► Load Phi-3 Mini (max 15s load budget)
           │
       Loaded? YES ──► (same as "already loaded" above)
       Loaded? NO  ──► WiFi? ──► Cloud API
                             ──► Structured Form
```

### 7.2 ModelGateway Implementation

```dart
// core/ai/model_gateway.dart
enum AIPath { localLLM, cloudAPI, structuredForm }

class ModelGateway {
  Future<Either<Failure, NLPResult>> parseNaturalLanguage(String input) async {
    final path = await _selectPath();
    switch (path) {
      case AIPath.localLLM:
        return _localLLM.parse(input).timeout(
          const Duration(seconds: 15),
          onTimeout: () => Left(LLMTimeoutFailure('Exceeded 15s')),
        );
      case AIPath.cloudAPI:
        return _cloudAI.parse(input);
      case AIPath.structuredForm:
        return Left(LLMUnavailableFailure('Use structured form'));
    }
  }

  Future<AIPath> _selectPath() async {
    if (await _battery.level < 20)       return AIPath.structuredForm;
    if (await _device.availableRamGB < 3) return AIPath.structuredForm;
    if (_localLLM.isLoaded)              return AIPath.localLLM;
    final loaded = await _localLLM.loadModel()
        .timeout(const Duration(seconds: 15), onTimeout: () => false);
    if (loaded)                          return AIPath.localLLM;
    if (await _network.isConnected)      return AIPath.cloudAPI;
    return AIPath.structuredForm;
  }
}
```

### 7.3 Cloud Provider Priority

| Priority | Provider | Model | Reason |
|----------|---------|-------|--------|
| 1 | Google Gemini | `gemini-1.5-flash` | Fastest, best structured JSON output, generous free tier |
| 2 | OpenAI | `gpt-4o-mini` | Higher accuracy for complex NLP |
| 3 | Anthropic | `claude-haiku-4-5` | Best when strict JSON schema compliance is critical |
| 4 | Ollama (local) | `phi3:mini` on `localhost:11434` | Desktop/tablet companion if user runs Ollama separately |

### 7.4 LLM Safety Rules

- Warm up Phi-3 Mini at app launch (background thread). Cache loaded state — never re-load per request.
- Always run in a foreground service with persistent notification (prevents Android background kill).
- Hard timeout: cancel inference if > 15 seconds.
- Check battery and RAM before every invocation — not just on first launch.

---

## PART 8 — SYNC STRATEGY

### 8.1 Every Write Must Do Three Things

```dart
// 1. Write to SQLite with sync_status = 'local'
// 2. Set updated_at = DateTime.now().toUtc()
// 3. Enqueue to sync_queue
await _syncQueue.enqueue(tableName, recordId, SyncOp.insert, payload);
```

### 8.2 SyncQueueService

```dart
class SyncQueueService {
  // Called on every SQLite write
  Future<void> enqueue(String table, String recordId, SyncOp op, Map payload) async {
    await db.insert('sync_queue', {
      'id':         Uuid().v4(),
      'table_name': table,
      'record_id':  recordId,
      'operation':  op.name,
      'payload':    jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
    });
  }

  // Called by ConnectivityPlus listener on reconnect
  Future<void> drainQueue() async {
    final pending = await db.query('sync_queue', orderBy: 'created_at ASC');
    for (final row in pending) {
      try {
        await _remote.pushRecord(row);
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [row['id']]);
      } catch (e) {
        final retries = (row['retry_count'] as int) + 1;
        if (retries >= 5) {
          await _flagAsConflict(row); // escalate to ConflictResolutionSheet
        } else {
          await db.update('sync_queue',
            { 'retry_count': retries, 'last_error': e.toString() },
            where: 'id = ?', whereArgs: [row['id']],
          );
        }
      }
    }
  }
}
```

### 8.3 Conflict Resolution — Three Rules

| Rule | When It Applies | Resolution |
|------|----------------|-----------|
| **Last-Write-Wins** | Same UUID, `updated_at` timestamps differ by > 1 second | Keep record with later `updated_at`. Soft-delete other. Silent — no user prompt. |
| **User-Prompt** | Same UUID, `updated_at` within 1 second (simultaneous edit) | Show `ConflictResolutionSheet` with both versions. User picks "Keep Mine" / "Use Newer". |
| **Append-Only Bypass** | `STUDY_SESSIONS`, `PERFORMANCE_DATA`, `SYNC_QUEUE` | These tables are append-only — never updated after creation. Conflicts impossible. UUID guarantees isolation. |

### 8.4 UUID Generation

```dart
import 'package:uuid/uuid.dart';
const _uuid = Uuid();

final task = Task(
  id:         _uuid.v4(),                        // never use SQLite AUTOINCREMENT
  createdAt:  DateTime.now().toUtc(),
  updatedAt:  DateTime.now().toUtc(),
  syncStatus: SyncStatus.local,
  isDeleted:  false,
);

// On any UPDATE:
task.copyWith(updatedAt: DateTime.now().toUtc(), syncStatus: SyncStatus.local);
```

---

## PART 9 — SCREENS

### 9.1 Navigation Structure

```
Bottom Navigation Bar (5 tabs):
  Tab 1 — Home (S03)
  Tab 2 — Schedule (S05)
  Tab 3 — Progress (S08)
  Tab 4 — Resources (S10)
  Tab 5 — Settings (S11)

First-launch flow: S01 → S02 → S03

Sub-screens (reached from parent):
  S04 Generate Plan       ← from S03 Home quick action
  S06 Active Session      ← from S05 task "Start" button
  S07 Revision Calendar   ← from S03 Home quick action
  S09 Subject Analytics   ← from S08 subject tap
  S12 Performance Pred.   ← from S03 or S08
```

### 9.2 Screen Definitions

**S01 — Onboarding**
3 swipeable slides. Slide 1: "Plan Smarter". Slide 2: "Study with Focus". Slide 3: "Improve Every Day". Dot page indicator. "Get Started" CTA on slide 3. "Skip" link on slides 1–2. → navigates to S02.

**S02 — Create Profile** *(one-time setup)*
Input: Full Name, Email (optional). Multi-select subject chips + "+" for custom. Daily study goal stepper (1–5h+). Spaced repetition reminders toggle. Time range picker (study window). "Continue →" writes to `USERS` table → S03.

**S03 — Home Dashboard** *(Tab 1)*
Zones: Greeting card (name, date, streak 🔥) → Quick stats row (today's hours | consistency % | tasks done) → Today's plan preview (top 3 tasks + "View All") → Quick action 2×2 grid (Generate Plan | Start Timer | View Reports | Revision Calendar) → AI Suggestion Banner (weak subject recommendation from K-Means output). Data: `USERS`, `STUDY_SESSIONS` + `TASKS` aggregates, K-Means output.

**S04 — Generate Study Plan**
Natural language input field (labelled "Powered by local AI model") OR toggle to structured form. Structured form: date picker, time range pickers (From/To), subject multi-select chips, priority dropdown per subject, optional goal text field. "Generate Plan ✨" button → loading spinner while FastAPI runs. Generated plan preview: colored time-block cards (study=indigo, break=grey, practice=amber, review=teal), each editable. Action row: "Regenerate" (outline) + "Save Plan" (filled). Save → writes `STUDY_PLANS` + `TASKS` → S05.

**S05 — Today's Schedule** *(Tab 2)*
Top bar: date label + left/right day navigation + "Add Task" icon. Circular progress ring (X/N done, hours studied). Vertical timeline task list — each card: time range (left) | subject chip + topic + resource icon (center) | status badge + Start▶/timer MM:SS/✓ (right). Break cards: lighter background, coffee icon, not interactive. Empty state: illustration + "No plan yet" + "Generate Plan" CTA.

**S06 — Active Study Session** *(launched from S05 Start button)*
Full-screen distraction-free mode. Minimal top bar (subject label only). Large MM:SS countdown timer with circular progress arc + elapsed time below. 3 timer controls: Pause | End Session | +5 min extend. Collapsible resource panel (bottom sheet — PDFs, links, PPTs for this task, openable without leaving screen). Focus Score building indicator. On completion: confetti animation + "Session Complete!" + "Mark Done ✓" | "Add 10 min" | "Skip for Now".

**Critical data writes on EndSession:**
```
STUDY_SESSIONS:  actual_duration, planned_duration, pause_count, focus_score, completed=1, ended_at
TASKS:           status='done', updated_at
REVISION_TASKS:  4 new records (Day+2/7/14/30) with correct revision_type
```

**S07 — Revision Calendar** *(from Home quick action)*
Monthly calendar grid. Dates with tasks show colored dot: Revision=Blue, Practice=Orange, Test=Red, Final=Purple. Legend strip. Tap date → expand day detail panel (topic, type badge, subject chip, status, "Start" button → S06 revision mode). "Next 7 Days" upcoming list below calendar.

**S08 — Progress Report** *(Tab 3)*
Week/Month toggle. Consistency Score gauge + gamification level + 🔥 streak badge. Bar chart (daily study hours). Doughnut chart (completed/pending/skipped). Subject-wise time table (sorted by hours desc). Consistency trend line chart (4-week). "Download Report" button. Data: `STUDY_SESSIONS` + `TASKS` aggregates.

**S09 — Subject Analytics** *(from S08 subject tap)*
Top bar shows subject name. STRONG/MODERATE/WEAK badge (K-Means output, color-coded). Key metrics row: Total hours | Avg practice score | Revision count. Score history line chart (last 5–10 sessions). Revision log timeline (date, score, type, pass/needs-work color). AI Recommendation card (e.g. "Study DBMS 4h/week for better results" + "Schedule More Sessions" CTA).

**S10 — Resources** *(Tab 4)*
Search bar + filter chips (All | PDF | Video | PPT | Practice Sets). 2-column card grid: file type icon + name + subject + date. FAB (+) → bottom sheet: Upload PDF | Paste Link | Import from Files. Long-press → context menu: Delete | Move to Subject | Share. Empty state with CTA.

**S11 — Settings** *(Tab 5)*
Section 1 — Profile (avatar, name, Edit button → S02). Section 2 — Study Preferences (daily goal stepper, session length 30/45/60 min, break duration 5/10/15 min, study window time picker). Section 3 — Notifications (daily reminder toggle + time, revision alerts, weekly report summary). Section 4 — AI Settings (NLP input toggle, performance prediction toggle, weak subject detection toggle, note: "AI runs locally. No data sent online."). Section 5 — Data (export CSV, clear all data in red, app version).

**S12 — Performance Prediction** *(from Home or S08)*
Headline prediction card with gradient (overall predicted score % + "Based on last 30 days"). Subject breakdown table: Subject | Study Hours | Revision Count | Practice Score | Predicted Score (green >70% / yellow 50–70% / red <50%). Key factors card (4 model inputs with current values). What-if slider (e.g. "+2h revision → new prediction updates live"). Recommendations list (3–5 bulleted suggestions). "Create Improvement Plan" CTA → opens S04 pre-filled with suggested sessions.

---

## PART 10 — DESIGN SYSTEM

### 10.1 Design Principles

1. **Clarity Over Complexity** — One primary purpose per screen. Strict information hierarchy. No decorative elements without meaning. Whitespace is intentional.
2. **Flow State Preservation** — Never interrupt active study sessions. All interactions ≤ 2 taps. Notifications batched outside sessions.
3. **Progress as Motivation** — Streaks, charts, and badges are first-class UI. Use green/amber for progress, never red for progress indicators.
4. **Intelligent Accessibility** — Dark mode is a core mode (students study at night). WCAG AA contrast (4.5:1 body text). Min touch target 48×48dp. Support `TextScaler` — test at 1.0× and 1.5×.

---

### 10.2 Color Tokens

**Primary:** `#4F6FE8` (Indigo) — focus, trust, calm determination. Blue-spectrum primaries reduce perceived cognitive load in educational UX.
**Secondary:** `#34D399` (Mint) — completion, streaks, encouragement.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#4F6FE8` | `#818CF8` | CTAs, active tabs, selected states |
| `primaryVariant` | `#3D59D0` | — | Pressed primary states |
| `primaryContainer` | `#EEF2FF` | `#312E81` | Chip backgrounds, info banners |
| `secondary` | `#34D399` | `#6EE7B7` | Completion, streak, success |
| `secondaryContainer` | `#D1FAE5` | `#064E3B` | Done state backgrounds |
| `background` | `#F8FAFC` | `#0F172A` | Screen background |
| `surface` | `#FFFFFF` | `#1E293B` | Cards, dialogs, bottom sheets |
| `surfaceVariant` | `#F1F5F9` | `#334155` | Input fills, chip backgrounds |
| `outline` | `#E2E8F0` | `#475569` | Borders, dividers |
| `onBackground` | `#0F172A` | `#F1F5F9` | Primary text |
| `onSurface` | `#1E293B` | `#E2E8F0` | Card text |
| `onSurfaceVariant` | `#64748B` | `#94A3B8` | Secondary text, placeholders |
| `error` | `#EF4444` | `#FCA5A5` | Validation errors |
| `errorContainer` | `#FEF2F2` | `#7F1D1D` | Error message backgrounds |
| `success` | `#10B981` | `#6EE7B7` | Completed tasks, positive trends |
| `successContainer` | `#D1FAE5` | `#064E3B` | Success banners |
| `warning` | `#F59E0B` | `#FCD34D` | Deadline alerts, caution states |
| `warningContainer` | `#FEF3C7` | — | Warning backgrounds |

---

### 10.3 Typography

**Display/UI font:** `Plus Jakarta Sans` (Google Fonts: `plus-jakarta-sans`) — weights 300/400/500/600/700
**Monospace/stats font:** `DM Mono` (Google Fonts: `dm-mono`) — weights 400/500 — used exclusively for timers, hex codes, numeric stats. Tabular figures prevent digit-width shifting.

| Token | Size | Weight | Line Height | Primary Use |
|-------|------|--------|------------|-------------|
| `displayLarge` | 57sp | 700 | 1.12 | Hero score numbers, splash screens |
| `displayMedium` | 45sp | 700 | 1.16 | Timer MM:SS countdown (DM Mono) |
| `displaySmall` | 36sp | 600 | 1.22 | Section hero stats |
| `headlineLarge` | 32sp | 700 | 1.25 | Screen titles, plan headings |
| `headlineMedium` | 28sp | 600 | 1.28 | Card headings, subject names |
| `headlineSmall` | 24sp | 600 | 1.33 | Section headers within screens |
| `titleLarge` | 22sp | 600 | 1.27 | Dialog titles, bottom sheet headers |
| `titleMedium` | 16sp | 500 | 1.50 | List item titles, task names |
| `titleSmall` | 14sp | 500 | 1.43 | Chip labels, tab bar labels |
| `bodyLarge` | 16sp | 400 | 1.50 | Primary body copy |
| `bodyMedium` | 14sp | 400 | 1.43 | Secondary body, card descriptions |
| `bodySmall` | 12sp | 400 | 1.33 | Captions, helper text, metadata |
| `labelLarge` | 14sp | 500 | 1.43 | Button labels |
| `labelMedium` | 12sp | 500 | 1.33 | Chip text, badge labels |
| `labelSmall` | 11sp | 500 | 1.45 | Overlines, category tags |

---

### 10.4 Spacing System

**Base unit: 4px.** All values must be multiples of 4. Never hardcode spacing inline — use `AppSpacing`.

| Token | Value | Flutter | Usage |
|-------|-------|---------|-------|
| `space1` | 4dp | `4.0` | Icon-to-label micro gap |
| `space2` | 8dp | `8.0` | Chip horizontal padding, tight gaps |
| `space3` | 12dp | `12.0` | List tile vertical padding |
| `space4` | 16dp | `16.0` | Screen horizontal margin, card padding |
| `space5` | 20dp | `20.0` | Label-to-input gap |
| `space6` | 24dp | `24.0` | Between unrelated components |
| `space8` | 32dp | `32.0` | Between major screen sections |
| `space10` | 40dp | `40.0` | Screen top padding below app bar |
| `space12` | 48dp | `48.0` | Hero section vertical padding |
| `space16` | 64dp | `64.0` | Bottom nav buffer |

**Fixed layout values:**
- Screen horizontal margin: 16dp
- AppBar height: 56dp
- Bottom nav height: 80dp (64dp bar + 16dp safe area)
- Card internal padding: 16dp (12dp for compact list cards)
- Section spacing: 32dp
- Min touch target: 48×48dp
- FAB: 16dp from right edge, 16dp above bottom nav
- Bottom sheet handle: 32×4dp, centered, 8dp from top of sheet

---

### 10.5 Component Tokens

**Buttons:**

| Variant | Background | Text | Radius | Height | Elevation | Use |
|---------|-----------|------|--------|--------|-----------|-----|
| `FilledButton` | `primary` | white | 12dp | 52dp | 0 | Save Plan, Start Session |
| `FilledTonalButton` | `primaryContainer` | `#3D59D0` | 12dp | 48dp | 0 | Add Subject, Set Reminder |
| `OutlinedButton` | transparent | `primary` | 12dp | 48dp | 0 | Cancel, View All, Edit |
| `TextButton` | transparent | `primary` | 8dp | 40dp | 0 | Skip, Later, Dismiss |
| `IconButton (Filled)` | `primaryContainer` | `primary` | full | 40dp | 0 | Timer: Pause, Play, Stop |
| `FAB (Large)` | `primary` | white | 16dp | 96dp | 3dp | Generate Study Plan |
| `FAB (Standard)` | `primary` | white | 16dp | 56dp | 3dp | Add task, add resource |

Button disabled state: 38% opacity on all elements.
Button loading state: replace label with `CircularProgressIndicator.adaptive()`, same color as text, strokeWidth 2.5.

**Cards:**

| Type | Background | Radius | Shadow | Use |
|------|-----------|--------|--------|-----|
| `ElevatedCard` | `surface` | 16dp | elevation 2, `0 2 8 #00000014` | Task cards, progress summary |
| `FilledCard` | `surfaceVariant` | 16dp | elevation 0 | Info panels, tip banners |
| `OutlinedCard` | `surface` | 16dp | border 1dp `outline` | Resources, settings rows |
| `HeroCard` | `#4F6FE8` (primary) | 20dp | elevation 4, `0 8 24 #4F6FE840` | Today's plan hero, streak banner |
| `CompactListCard` | `surface` | 12dp | elevation 1, `0 1 4 #0000000D` | Schedule list rows |

Card selected state: border 2dp solid `primary`, background tint `primaryContainer`.

**Input Fields (FilledInputDecoration default):**

| State | Fill | Indicator | Label color |
|-------|------|-----------|------------|
| Inactive | `surfaceVariant` | none | `onSurfaceVariant` |
| Focused | `primaryContainer` | 2dp `primary` (bottom) | `primary` |
| Error | `errorContainer` | 2dp `error` (bottom) | `error` + error icon |
| Disabled | `background` | none | `outline` |

Radius: 12dp top corners, 0dp bottom (filled style). Min height: 56dp. Content padding: 16dp horizontal, 12dp vertical.

**Other components:**

| Component | Key Specs |
|-----------|-----------|
| `NavigationBar` | height 80dp, indicator 64×32dp pill, active: `primary`, inactive: `onSurfaceVariant`, label 12sp |
| `Chip` | height 32dp, radius full (16dp), selected fill: `primaryContainer`, selected border 1.5dp `primary` |
| `LinearProgressIndicator` | height 8dp, radius 4dp, track: `surfaceVariant`, value: `primary` |
| `CircularProgressIndicator` | strokeWidth 4dp, strokeCap `StrokeCap.round` (session timer arc) |
| `SnackBar` | radius 12dp, bg `#1E293B`, text `#F1F5F9`, action `primary`, elevation 6, floating (16dp margin) |
| `Dialog` | radius 24dp, max width 280dp, title `titleLarge`, content `bodyMedium` |
| `BottomSheet` | radius 28dp top corners, handle 32×4dp centered |
| `Divider` | 1dp, color `outline`, indent 16dp for list dividers |
| `Switch` | active: `primary`, track: `primaryContainer`, thumb: white |

---

### 10.6 Iconography

**Primary library:** Material Symbols Rounded (`material_symbols_icons` ^4.x) — variable font, fill/outlined transitions via fill variable.
**Supplemental:** Lucide Icons (`lucide_icons`) — for productivity metaphors not in Material Symbols.

Rules:
- Rounded style only. Never Sharp or Outlined — conflicts with rounded card aesthetic.
- `fill: 0` inactive → `fill: 1` active/selected
- Sizes: 24dp standard · 20dp dense/chips · 32dp section headers · 64dp empty states (60% opacity)
- Animate tab bar state changes: `AnimatedSwitcher(duration: 200ms, curve: Curves.easeInOut)`

Navigation bar icons: `home` | `calendar_today` | `bar_chart` | `folder` | `settings`

---

### 10.7 Flutter Implementation Notes

```dart
// Theme setup
ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF4F6FE8),
    brightness: Brightness.light,
  ),
).copyWith(/* override component themes here */);

// Dark mode
ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);
// Persist with shared_preferences

// Define globally in ThemeData — never style components per-widget:
// FilledButtonThemeData, CardThemeData, InputDecorationTheme,
// NavigationBarThemeData, ChipThemeData

// Respect text scaling
MediaQuery.textScalerOf(context); // test at 1.0x and 1.5x

// Never use fixed-height containers for text
```

---

## PART 11 — EDGE CASE & GUARD CHECKLIST

Every one of these must be implemented. None are optional.

| # | Context | Condition | Required Action |
|---|---------|-----------|----------------|
| 1 | Plan generation | `subjects.isEmpty` | Emit `NoSubjectsFailure`. Block Python call. Red border on subject picker. |
| 2 | Plan generation | `totalMinutes < 15` | Emit `InsufficientTimeFailure`. Offer Quick Review mode (10/15/20 min blocks). |
| 3 | Plan generation | `totalMinutes == 45` | Check `remaining_time > 0` before appending break. Avoid negative break duration. |
| 4 | Plan generation | Single subject | Skip priority weighting to avoid `ZeroDivisionError`. |
| 5 | Plan generation | Window crosses midnight | Add 24h to `end_time` before computing duration. |
| 6 | Plan generation | Non-contiguous time slots | Parse as `List<(start, end)>`. Run block loop per segment independently. |
| 7 | Plan generation | Rapid repeated taps | Debounce: ignore new `GeneratePlanEvent` while `PlanLoading` is active. |
| 8 | ML prediction | `session_count < 5` | Emit `InsufficientDataFailure`. Disable prediction tab. Show X/5 progress bar. |
| 9 | K-Means | `subject_count < 3` | Bypass K-Means. Use threshold comparison. Set `fallback_used: true`. |
| 10 | K-Means | All scores identical (variance < threshold) | Fallback: recommend subject with fewest revision sessions. |
| 11 | Consistency score | `planned_sessions == 0` | Use denominator `max(planned_sessions, 1)`. Never divide by zero. |
| 12 | LLM invocation | Battery < 20% | Emit `LowBatteryFailure`. Show structured form. Block LLM. |
| 13 | LLM invocation | Device RAM < 3 GB | Emit `LLMUnavailableFailure`. Permanently hide NLP input for this device. |
| 14 | LLM invocation | > 15s inference time | Cancel. Emit `LLMTimeoutFailure`. Auto-fallback. After 3 timeouts, disable for session. |
| 15 | LLM output | Invalid/malformed JSON | Emit `LLMParseFailure`. Show structured form. Never crash. |
| 16 | SQLite write | Failure | Retry ×3 with 1s/2s/4s backoff. Surface `DatabaseFailure` after 3rd failure. |
| 17 | Sync queue | 5th failed retry | Escalate to `SyncConflictFailure`. Show `ConflictResolutionSheet`. |
| 18 | Session timer | Pause tap | Increment `pause_count` in memory. Write to DB on `EndSession`. |
| 19 | `EndSession` | Regardless of how session ends | Always write `actual_duration`, `focus_score`, `pause_count` to `STUDY_SESSIONS`. Always create 4 `REVISION_TASKS`. |

---

## PART 12 — SPRINT BUILD ORDER

Complete each sprint fully before starting the next. Database schema must be done first — every other component depends on it.

**Sprint 1 — Foundation**
1. Create SQLite schema: all 7 tables, UUID PKs, `created_at`, `updated_at`, `sync_status`, `is_deleted` — Migration_001
2. Set up `get_it` DI: register all repositories, data sources, and blocs
3. Implement all abstract Repository interfaces
4. Create `AppColors`, `AppSpacing`, `AppTextStyles` static constant classes — zero inline values
5. Set up FastAPI: all 5 endpoints returning mock data

**Sprint 2 — Core Loop**
6. `PlanGeneratorBloc` + `LocalStudyPlanSource` → POST `/plan/generate` → write to SQLite
7. `ScheduleCubit` + S05 task list + day navigation arrows
8. `SessionBloc`: start / pause / resume / end; write complete `STUDY_SESSIONS` record
9. Wire spaced repetition on `SessionComplete` → 4 `REVISION_TASKS` created
10. All input guard clauses (guards 1–7 and 11 above) at repository layer

**Sprint 3 — Intelligence Layer**
11. `ModelGateway` with all 3 paths + pre-flight guards (guards 12–15)
12. `/ml/predict` + `InsufficientDataFailure` empty state with X/5 counter
13. `/ml/cluster` + K-Means fallback for < 3 subjects (guards 9–10)
14. "Log Score" flow on S07 Revision Calendar → writes `PERFORMANCE_DATA`
15. `RevisionCalendarCubit` `markDone()` → writes `REVISION_TASKS.status='done'`

**Sprint 4 — Polish & Sync**
16. `SyncQueueService.enqueue()` called on every SQLite write
17. `ConnectivityPlus` listener → `drainQueue()` on reconnect
18. `ConflictResolutionSheet` UI for simultaneous-edit conflicts
19. Migration runner tested: v1 → v2 upgrade path verified
20. Global error handler: all `Failure` subclasses → standardized SnackBar or empty state UI

---

## PART 13 — VIBE CODING PROMPT BLOCK

Copy this block verbatim into Antigravity (or any AI coding tool) at the start of every session. It encodes all critical constraints in one injectable context:

```
## AI Study Planner — Coding Context v1.0

### STACK
- Flutter (Dart), flutter_bloc v8, sqflite, dio, get_it, dartz, uuid
- Python 3.11, FastAPI on 127.0.0.1:8765, scikit-learn, llama-cpp-python
- SQLite: all PKs = TEXT UUID v4. Every table has: created_at, updated_at (ISO UTC),
  sync_status (local|synced|conflict), is_deleted (0|1)

### PATTERNS — NEVER DEVIATE
- State: BLoC pattern only. One Bloc per feature. No setState() for business logic.
  No direct repository calls inside widget files.
- Data: Repository Pattern. All DB access via repository classes.
  All repositories return Either<Failure, T> from dartz.
- Python: HTTP POST to 127.0.0.1:8765. Always try/catch. Timeout 15s.
  On failure → emit specific Failure subclass. Never propagate raw exceptions to UI.
- Spacing: 4px base unit, 16dp screen margin, 16dp card padding.
  Use AppSpacing constants. Never hardcode spacing values inline.
- Colors: Use AppColors constants. Never hardcode hex values inline.

### BACKEND ENDPOINTS
- POST /plan/generate  → {user_id, subjects[], time_slots[], priorities{}} → {plan_id, blocks[], warnings[]}
- POST /ml/predict     → {user_id, days_back} → {predicted_scores{}, confidence, feature_importances{}}
- POST /ml/cluster     → {user_id} → {clusters:{strong[],moderate[],weak[]}, fallback_used:bool}
- POST /ai/nlp-parse   → {raw_text, device_tier} → {time_slots[], subjects[], goal, confidence}
- GET  /health         → {llm_loaded, db_ok, battery_ok}

### GUARDS — CHECK BEFORE EVERY PYTHON CALL
- Plan: subjects.isNotEmpty AND totalMinutes >= 15
- ML:   sessionCount >= 5 (else InsufficientDataFailure)
- LLM:  battery > 20% AND deviceRam >= 3GB AND !timedOut (else LowBatteryFailure or LLMUnavailableFailure)

### SESSION END — ALWAYS WRITE ALL OF THESE
- STUDY_SESSIONS: actual_duration, planned_duration, pause_count, focus_score, completed=1, ended_at
- TASKS: status='done', updated_at=now()
- REVISION_TASKS: 4 new records at Day+2, +7, +14, +30

### DO NOT GENERATE
- StatefulWidgets with business logic
- SQLite queries in widget or screen files
- Raw exception handling that reaches the UI
- Hardcoded color hex values or spacing values inline
- Integer primary keys — always Uuid().v4()
- Single-range time_slots — always List<(start,end)> tuples
```

---

*AI Study Planner — Master Project Skill v1.0*
*Sources: PRD · TRD · Screen Layouts · Design System · Master Implementation Blueprint*
*Single source of truth — every fact appears exactly once*
