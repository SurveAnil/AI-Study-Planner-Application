import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

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
  Future<void> saveRoadmap(String skill, Map<String, dynamic> roadmap, {String? startDate}) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('roadmap_cache', {
      'skill': skill,
      'roadmap_json': json.encode(roadmap),
      'created_at': now,
      'start_date': startDate,
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
      final source = rows.first['roadmap_json'] as String;
      final decoded = await compute(_decodeMap, source);
      if (decoded == null) return null;
      
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

  // ── Learning State ────────────────────────────────────────────────────────

  Future<void> initLearningState(String skill, String startDate, int dailyHours) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'user_learning_state',
      {
        'skill': skill,
        'start_date': startDate,
        'current_day': 1,
        'last_active_date': startDate,
        'daily_hours': dailyHours,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLearningState(String skill) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'user_learning_state',
      where: 'skill = ?',
      whereArgs: [skill],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<bool> progressDayIfNeeded(String skill) async {
    final state = await getLearningState(skill);
    if (state == null) return false;

    final startDateStr = state['start_date'] as String;
    final lastActiveStr = state['last_active_date'] as String;
    final currentDay = state['current_day'] as int;

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    final todayDate = DateTime.parse(todayStr);
    final startDate = DateTime.parse(startDateStr);
    
    if (startDate.isAfter(todayDate)) {
      // Future start date handling: Keep current_day=1
      return false;
    }

    final lastActiveDate = DateTime.parse(lastActiveStr);

    if (todayDate.isBefore(lastActiveDate)) {
      debugPrint("System time anomaly detected: Time moved backward");
      return true; // time_anomaly = true
    }

    if (todayDate.isAfter(lastActiveDate)) {
      final daysPassed = todayDate.difference(lastActiveDate).inDays;
      if (daysPassed > 0) {
        final db = await DatabaseHelper.database;
        await db.update(
          'user_learning_state',
          {
            'current_day': currentDay + daysPassed,
            'last_active_date': todayStr,
          },
          where: 'skill = ?',
          whereArgs: [skill],
        );
      }
    }
    return false; // time_anomaly = false
  }

  /// Manually updates the current_day for [skill].
  Future<void> updateCurrentDay(String skill, int newDay) async {
    final db = await DatabaseHelper.database;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    await db.update(
      'user_learning_state',
      {
        'current_day': newDay,
        'last_active_date': todayStr,
      },
      where: 'skill = ?',
      whereArgs: [skill],
    );
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
    String? generationStatus,
    int isPreGenerated = 0,
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
      'generation_status': generationStatus,
      'is_pre_generated': isPreGenerated,
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
      final source = rows.first['plan_json'] as String;
      final decodedMap = await compute(_decodeMap, source);
      if (decodedMap != null) {
        decodedMap['generation_status'] = rows.first['generation_status'];
        decodedMap['is_pre_generated'] = rows.first['is_pre_generated'];
        decodedMap['status'] = rows.first['status'];

        // --- Migration: Assign task_position and task_id ---
        bool migrated = false;
        final tasks = decodedMap['tasks'] as List? ?? [];
        for (int i = 0; i < tasks.length; i++) {
          final t = tasks[i];
          if (t is Map<String, dynamic>) {
            if (!t.containsKey('task_position') || !t.containsKey('task_id')) {
              t['task_position'] = i;
              final title = t['title'] ?? 'untitled';
              final type = t['type'] ?? 'learn';
              t['task_id'] = generateTaskId(title, type, day, i);
              migrated = true;
            }
          }
        }

        if (migrated) {
          // Update silently
          await db.update(
            'daily_plan_cache',
            {'plan_json': json.encode(decodedMap)},
            where: 'skill = ? AND day = ?',
            whereArgs: [skill, day],
          );
        }
      }
      return decodedMap;
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

  /// Marks a specific day's plan as finalized so it can be executed.
  Future<void> finalizePlan(String skill, int day) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'daily_plan_cache',
      {'status': 'finalized'},
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
    );
  }

  /// Checks if a day's plan has been finalized.
  Future<bool> isPlanFinalized(String skill, int day) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'daily_plan_cache',
      columns: ['status'],
      where: 'skill = ? AND day = ?',
      whereArgs: [skill, day],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final status = rows.first['status'] as String?;
    return status == 'finalized' || status == 'completed' || status == 'skipped';
  }

  // ── Smart Scheduling ──────────────────────────────────────────────────────

  /// Centralized date calculation string (yyyy-MM-dd)
  String calculateDate(String startDateStr, int dayNumber) {
    if (startDateStr.isEmpty) return '';
    try {
      final start = DateTime.parse(startDateStr);
      final target = start.add(Duration(days: dayNumber - 1));
      return target.toIso8601String().split('T')[0];
    } catch (_) {
      return '';
    }
  }

  // ── Task Progress ─────────────────────────────────────────────────────────

  static String generateTaskId(String title, String type, int day, int position) {
    if (title.isEmpty) title = 'untitled';
    if (type.isEmpty) type = 'learn';
    final bytes = utf8.encode('$title$type$day$position');
    return md5.convert(bytes).toString();
  }

  /// Updates (or inserts) the completion status for a specific task.
  /// [status] should be `"pending"` or `"completed"`.
  Future<void> updateTaskStatus(
      String skill, int day, int index, String taskId, String status) async {
    final db = await DatabaseHelper.database;

    final existing = await db.query(
      'task_progress',
      where: 'skill = ? AND day = ? AND task_id = ?',
      whereArgs: [skill, day, taskId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'task_progress',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Safe Migration check
      final oldRows = await db.query(
          'task_progress',
          where: 'skill = ? AND day = ? AND task_index = ?',
          whereArgs: [skill, day, index],
          limit: 1);
      if (oldRows.isNotEmpty) {
        await db.update(
          'task_progress',
          {'status': status, 'task_id': taskId},
          where: 'id = ?',
          whereArgs: [oldRows.first['id']],
        );
      } else {
        await db.insert('task_progress', {
          'skill': skill,
          'day': day,
          'task_index': index,
          'task_id': taskId,
          'status': status,
        });
      }
    }
  }

  /// Returns the saved status for a specific task, or null if not tracked.
  Future<String?> getTaskStatus(String skill, int day, int index, String taskId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'task_progress',
      columns: ['id', 'status'],
      where: 'skill = ? AND day = ? AND task_id = ?',
      whereArgs: [skill, day, taskId],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['status'] as String?;

    // Safe migration check
    final oldRows = await db.query(
      'task_progress',
      columns: ['id', 'status'],
      where: 'skill = ? AND day = ? AND task_index = ?',
      whereArgs: [skill, day, index],
      limit: 1,
    );
    if (oldRows.isNotEmpty) {
      // update silently
      await db.update('task_progress', {'task_id': taskId},
          where: 'id = ?', whereArgs: [oldRows.first['id']]);
      return oldRows.first['status'] as String?;
    }
    return null;
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

// Top-level function for background isolate parsing
Map<String, dynamic>? _decodeMap(String source) {
  try {
    return json.decode(source) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}
