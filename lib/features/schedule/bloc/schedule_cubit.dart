import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../roadmap/data/roadmap_local_service.dart';
import '../data/study_plan_repository.dart';

class ScheduleState {
  final bool isLoading;
  final List<Map<String, dynamic>> tasks;

  const ScheduleState({this.isLoading = false, this.tasks = const []});
}

class ScheduleCubit extends Cubit<ScheduleState> {
  final StudyPlanRepository repository;
  ScheduleCubit({required this.repository}) : super(const ScheduleState());

  Future<void> loadDay(DateTime date) async {
    emit(const ScheduleState(isLoading: true));

    final dateStr = date.toIso8601String().split('T')[0];

    // ── 1. Load manual plan tasks (existing) ──────────────────────────────
    final List<Map<String, dynamic>> allTasks = [];
    final res = await repository.getTasksForDate(
        AppConstants.kDevUserId, dateStr);
    res.fold(
      (l) {},
      (r) => allTasks.addAll(r),
    );

    // ── 2. Load AI-generated daily plans filtered by active skill ─────────
    try {
      final svc = RoadmapLocalService.instance;
      final activeSkill = await svc.getActiveSkill();

      List<Map<String, dynamic>> aiPlans;
      if (activeSkill != null) {
        // Filter to only the active skill's plans
        aiPlans = await svc.getPlansForDateAndSkill(dateStr, activeSkill);
      } else {
        // Fallback: show all AI plans for this date
        aiPlans = await svc.getPlansForDate(dateStr);
      }

      for (final planRow in aiPlans) {
        final skill = planRow['skill'] as String? ?? '';
        final planJson = planRow['plan_json'] as String?;
        if (planJson == null) continue;

        final planData =
            json.decode(planJson) as Map<String, dynamic>? ?? {};
        final tasks = planData['tasks'] as List? ?? [];

        for (final t in tasks) {
          if (t is Map<String, dynamic>) {
            final duration = t['duration_minutes'] ?? 30;
            allTasks.add({
              'title': t['title'] ?? 'AI Task',
              'subject': skill,
              'start_time': '', // AI tasks are fluid
              'end_time': '$duration min',
              'status': 'pending',
              'block_type': 'ai_roadmap',
              'type': t['type'] ?? 'learn',
            });
          }
        }
      }
    } catch (_) {
      // Non-critical — don't block schedule load
    }

    emit(ScheduleState(isLoading: false, tasks: allTasks));
  }
}
