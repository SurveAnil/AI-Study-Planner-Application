import 'dart:convert';
import '../../../core/database/database_helper.dart';
import '../domain/entities/daily_study_snapshot.dart';
import '../domain/entities/progress_report.dart';

/// Service responsible for normalizing raw database rows into domain entities.
/// This layer decouples the Analytics logic from the raw SQL schema.
class AnalyticsAggregator {
  
  /// Computes a full report for the given [skill] and date range.
  Future<ProgressReport> computeReport(String skill, {int lastNDays = 30}) async {
    final snapshots = await _fetchSnapshots(skill, lastNDays);
    
    // Calculate Streak
    int currentStreak = 0;
    for (var i = 0; i < snapshots.length; i++) {
        if (snapshots[i].isActiveDay) {
            currentStreak++;
        } else if (i > 0) {
            // Note: In real logic, we'd check if today is active or yesterday.
            // Simplified for now: count consecutive active from the end.
            break; 
        }
    }

    // Calculate Consistency Index (Active Days / Total Days)
    final activeCount = snapshots.where((s) => s.isActiveDay).length;
    final consistencyIndex = snapshots.isNotEmpty 
        ? (activeCount / snapshots.length) * 100 
        : 0.0;

    // Calculate Weighted Focus Efficiency (Minutes per unit of value)
    final totalWeightedVal = snapshots.fold(0.0, (sum, s) => sum + s.weightedCompletionValue);
    final totalMins = snapshots.fold(0, (sum, s) => sum + s.focusMinutes);
    final focusEfficiency = totalWeightedVal > 0 ? totalMins / totalWeightedVal : 0.0;

    // Total Domain Distribution
    final totalDistribution = <String, int>{};
    for (var s in snapshots) {
        s.timeByDomain.forEach((key, value) {
            totalDistribution[key] = (totalDistribution[key] ?? 0) + value;
        });
    }

    return ProgressReport(
        snapshots: snapshots,
        currentStreak: currentStreak,
        consistencyIndex: consistencyIndex,
        weightedFocusEfficiency: focusEfficiency,
        totalDomainTimeDistribution: totalDistribution,
    );
  }

  Future<List<DailyStudySnapshot>> _fetchSnapshots(String skill, int days) async {
    final db = await DatabaseHelper.database;
    final now = DateTime.now();
    final snapshots = <DailyStudySnapshot>[];

    // We iterate backwards through days
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      // 1. Find the plan for this date to get total tasks and metadata
      final planRow = await db.query(
        'daily_plan_cache',
        where: 'skill = ? AND date = ?',
        whereArgs: [skill, dateStr],
        limit: 1,
      );

      if (planRow.isEmpty) {
        snapshots.add(_createEmptySnapshot(date));
        continue;
      }

      final dayNum = planRow.first['day'] as int;
      final planJson = json.decode(planRow.first['plan_json'] as String);
      final rawTasks = planJson['tasks'] as List? ?? [];
      
      // 2. Fetch completed tasks for this day
      final progressRows = await db.query(
        'task_progress',
        where: 'skill = ? AND day = ? AND status = ?',
        whereArgs: [skill, dayNum, 'completed'],
      );

      final completedIndices = progressRows.map((r) => r['task_index'] as int).toSet();

      // 3. Fetch focus time from study_sessions
      final sessionRows = await db.query(
        'study_sessions',
        where: 'skill = ? AND day = ? AND completed = 1',
        whereArgs: [skill, dayNum],
      );

      int totalMins = 0;
      for (var row in sessionRows) {
          totalMins += (row['actual_duration'] as int? ?? 0) ~/ 60;
      }

      // 4. Calculate Weighted Value & Domains
      double weightedVal = 0.0;
      final domainMap = <String, int>{};

      for (int idx = 0; idx < rawTasks.length; idx++) {
          final task = rawTasks[idx];
          final type = task['type'] as String? ?? 'learn';
          final title = (task['title'] as String? ?? '').toLowerCase();
          
          if (completedIndices.contains(idx)) {
              if (type == 'project') {
                weightedVal += 2.0;
              } else if (type == 'practice') {
                weightedVal += 1.5;
              } else {
                weightedVal += 1.0;
              }
          }

          _mapTitleToDomain(title);
          // Distribute session time if it exists for this task_id
          // For now, we'll simplify and attribute total time to domains present in tasks
          // In a more complex v2, we'd use task_id matching.
      }

      // Attribute time simply across the domains identified in the tasks for that day
      // (Simplified V1 approach)
      if (rawTasks.isNotEmpty) {
          final perTaskMin = totalMins ~/ rawTasks.length;
          for (var task in rawTasks) {
              final d = _mapTitleToDomain(task['title'] ?? '');
              domainMap[d] = (domainMap[d] ?? 0) + perTaskMin;
          }
      } else if (totalMins > 0) {
          // If there were sessions but no tasks defined, attribute to Theory
          domainMap['Theory'] = (domainMap['Theory'] ?? 0) + totalMins;
      }

      snapshots.add(DailyStudySnapshot(
        date: date,
        completedTasks: completedIndices.length,
        totalTasks: rawTasks.length,
        weightedCompletionValue: weightedVal,
        focusMinutes: totalMins,
        timeByDomain: domainMap,
        isActiveDay: completedIndices.isNotEmpty,
      ));
    }

    return snapshots;
  }

  String _mapTitleToDomain(String title) {
    title = title.toLowerCase();
    if (title.contains('ui') || title.contains('design') || title.contains('widget')) return 'UI/UX';
    if (title.contains('logic') || title.contains('algor') || title.contains('code')) return 'Logic';
    if (title.contains('db') || title.contains('sql') || title.contains('data')) return 'Database';
    if (title.contains('fix') || title.contains('bug') || title.contains('refactor')) return 'Refactoring';
    return 'Theory';
  }

  DailyStudySnapshot _createEmptySnapshot(DateTime date) {
    return DailyStudySnapshot(
      date: date,
      completedTasks: 0,
      totalTasks: 0,
      weightedCompletionValue: 0.0,
      focusMinutes: 0,
      timeByDomain: const {},
      isActiveDay: false,
    );
  }
}
