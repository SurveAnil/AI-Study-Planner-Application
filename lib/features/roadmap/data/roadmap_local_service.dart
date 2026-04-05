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

