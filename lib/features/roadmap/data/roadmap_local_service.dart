import 'dart:convert';

import '../../../core/database/database_helper.dart';

/// Handles reading and writing roadmap, daily-plan, and task-progress data
/// from/to SQLite.
///
/// All methods are **skill-scoped** so multiple roadmaps can coexist without
/// data collisions.
///
/// This service is intentionally a plain Dart class (no Bloc/Cubit) so it can
/// be used directly from StatefulWidget screens without extra BlocProvider
/// boilerplate.
class RoadmapLocalService {
  // ── Singleton ─────────────────────────────────────────────────────────────

  RoadmapLocalService._();
  static final RoadmapLocalService instance = RoadmapLocalService._();

  // ── Roadmap ───────────────────────────────────────────────────────────────

  /// Inserts a new roadmap row.  Multiple roadmaps are kept (one per skill
  /// generation).  [skill] is stored both as a column and inside [roadmap].
  Future<void> saveRoadmap(String skill, Map<String, dynamic> roadmap) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('roadmap_cache', {
      'skill': skill,
      'roadmap_json': json.encode(roadmap),
      'created_at': now,
    });
    
    print("Roadmap saved successfully to roadmap_cache");
  }

  /// Returns the most recently generated roadmap, or null if none exists.
  Future<Map<String, dynamic>?> getLatestRoadmap() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'roadmap_cache',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final decoded = json.decode(rows.first['roadmap_json'] as String)
          as Map<String, dynamic>;
      // Inject the skill column so callers always have it
      decoded['skill'] ??= rows.first['skill'];
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Returns every saved roadmap, newest first.  Each element contains:
  ///   `{ 'skill': String, 'roadmap_json': String, 'created_at': int }`
  Future<List<Map<String, dynamic>>> getAllRoadmaps() async {
    final db = await DatabaseHelper.database;
    return db.query(
      'roadmap_cache',
      orderBy: 'created_at DESC',
    );
  }

  /// Deletes all daily plans, task progress, AND day completions for [skill].
  Future<void> clearPlansForSkill(String skill) async {
    final db = await DatabaseHelper.database;
    await db.delete('daily_plan_cache',
        where: 'skill = ?', whereArgs: [skill]);
    await db.delete('task_progress', where: 'skill = ?', whereArgs: [skill]);
    await db.delete('day_completion', where: 'skill = ?', whereArgs: [skill]);
  }

  // ── Daily Plan ────────────────────────────────────────────────────────────

  /// Saves a daily plan for [skill]/[day].  Replaces any existing row for the
  /// same skill+day combination.
  ///
  /// [date] is an optional ISO-8601 date string (yyyy-MM-dd) to bind the plan
  /// to a calendar date.  [stageIndex] tracks which roadmap stage this plan
  /// belongs to.
  Future<void> saveDailyPlan(
    String skill,
    int day,
    Map<String, dynamic> planData, {
    String? date,
    int stageIndex = 0,
  }) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Delete existing row for this skill+day (if any) then insert fresh
    await db.delete(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
    );

    await db.insert('daily_plan_cache', {
      'skill': skill,
      'day': day,
      'plan_json': json.encode(planData),
      'created_at': now,
      'date': date,
      'stage_index': stageIndex,
    });
  }

  /// Returns the cached daily plan for [skill]/[day], or null if not found.
  Future<Map<String, dynamic>?> getDailyPlan(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return json.decode(rows.first['plan_json'] as String)
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns all daily plans whose `date` column matches [dateStr]
  /// (format: yyyy-MM-dd).  Used by the Schedule screen to show AI-generated
  /// tasks for a given day.
  Future<List<Map<String, dynamic>>> getPlansForDate(String dateStr) async {
    final db = await DatabaseHelper.database;
    return db.query(
      'daily_plan_cache',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
  }

  // ── Task Progress ─────────────────────────────────────────────────────────

  /// Updates (or inserts) the completion status for a specific task.
  /// [status] should be `"pending"` or `"completed"`.
  Future<void> updateTaskStatus(
      String skill, int day, int index, String status) async {
    final db = await DatabaseHelper.database;

    // Check if row exists
    final existing = await db.query(
      'task_progress',
      where: 'skill = ? AND day = ? AND task_index = ?',
      whereArgs: [skill, day, index],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'task_progress',
        {'status': status},
        where: 'skill = ? AND day = ? AND task_index = ?',
        whereArgs: [skill, day, index],
      );
    } else {
      await db.insert('task_progress', {
        'skill': skill,
        'day': day,
        'task_index': index,
        'status': status,
      });
    }
  }

  /// Returns the saved status for a specific task, or null if not tracked.
  Future<String?> getTaskStatus(String skill, int day, int index) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'task_progress',
      columns: ['status'],
      where: 'skill = ? AND day = ? AND task_index = ?',
      whereArgs: [skill, day, index],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['status'] as String?;
  }

  // ── Day Completion ────────────────────────────────────────────────────────

  /// Records that the user has completed [day] for [skill].
  Future<void> markDayComplete(String skill, int day,
      {int stageIndex = 0}) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Avoid duplicate entries
    final existing = await db.query(
      'day_completion',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('day_completion', {
      'skill': skill,
      'day': day,
      'stage_index': stageIndex,
      'completed_at': now,
    });
  }

  /// Returns true if [day] has been marked complete for [skill].
  Future<bool> isDayCompleted(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'day_completion',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Marks [day] for [skill] as skipped ('Take Day Off').
  /// If no row exists yet for this day (plan never fetched), a placeholder
  /// row is inserted so the status can be tracked and future navigation
  /// correctly jumps over it.
  Future<void> markDaySkipped(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final existing = await db.query(
      'daily_plan_cache',
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'daily_plan_cache',
        {'status': 'skipped'},
        where: 'skill = ? AND day = ?',
        whereArgs: [skill, day],
      );
    } else {
      // No plan fetched yet — insert a lightweight placeholder.
      await db.insert('daily_plan_cache', {
        'skill': skill,
        'day': day,
        'plan_json': '{"tasks":[]}',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'skipped',
      });
    }
  }

  /// Returns the lowest day number for [skill] whose status is neither
  /// 'completed' nor 'skipped'.  Accounts for gaps (days whose rows don't
  /// exist yet are treated as 'pending').
  ///
  /// Example: days 1=completed, 2=skipped, 3=pending → returns 3.
  /// Example: all saved days done → returns maxDay + 1.
  Future<int> getNextPendingDay(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      columns: ['day', 'status'],
      where: 'skill = ?',
      whereArgs: [skill],
      orderBy: 'day ASC',
    );

    if (rows.isEmpty) return 1;

    final int maxDay = (rows.last['day'] as int?) ?? 1;

    // Build a day→status map for quick lookup.
    final Map<int, String> statusMap = {
      for (final r in rows)
        (r['day'] as int): (r['status'] as String? ?? 'pending'),
    };

    // Walk every day from 1 to maxDay; the first day without a
    // 'completed'/'skipped' status is the next pending day.
    for (int d = 1; d <= maxDay; d++) {
      final s = statusMap[d] ?? 'pending';
      if (s != 'completed' && s != 'skipped') return d;
    }

    // All known days are done/skipped — advance to the next one.
    return maxDay + 1;
  }

  /// Returns the highest day number that's been completed for [skill],
  /// or 0 if nothing completed yet.
  Future<int> getLastCompletedDay(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT MAX(day) as max_day FROM day_completion WHERE skill = ?',
      [skill],
    );
    if (rows.isEmpty || rows.first['max_day'] == null) return 0;
    return rows.first['max_day'] as int;
  }

  // ── Active Skill ──────────────────────────────────────────────────────────

  /// Sets the currently active skill in app_settings.
  Future<void> setActiveSkill(String skill) async {
    final db = await DatabaseHelper.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      ['active_skill', skill],
    );
  }

  /// Returns the currently active skill, or null if none set.
  Future<String?> getActiveSkill() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['active_skill'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ── Skill-Specific Queries ────────────────────────────────────────────────

  /// Returns the latest roadmap for a specific [skill], or null.
  Future<Map<String, dynamic>?> getRoadmapForSkill(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'roadmap_cache',
      where: 'skill = ?',
      whereArgs: [skill],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final decoded = json.decode(rows.first['roadmap_json'] as String)
          as Map<String, dynamic>;
      decoded['skill'] ??= rows.first['skill'];
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Returns all distinct skill names from roadmap_cache, newest first.
  Future<List<String>> getDistinctSkills() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT skill FROM roadmap_cache ORDER BY created_at DESC',
    );
    return rows.map((r) => r['skill'] as String).toList();
  }

  /// Returns AI daily plans for a specific [dateStr] AND [skill].
  Future<List<Map<String, dynamic>>> getPlansForDateAndSkill(
      String dateStr, String skill) async {
    final db = await DatabaseHelper.database;
    return db.query(
      'daily_plan_cache',
      where: 'date = ? AND skill = ?',
      whereArgs: [dateStr, skill],
    );
  }
}

