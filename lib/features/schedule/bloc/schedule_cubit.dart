import 'package:flutter_bloc/flutter_bloc.dart';
import '../../roadmap/data/roadmap_local_service.dart';
import '../data/study_plan_repository.dart';
import '../../../core/util/app_logger.dart';

class ScheduleState {
  final bool isLoading;
  final List<Map<String, dynamic>> tasks;
  final bool isPlanFinalized;
  final int activeDay;   // Today (from learning state)
  final int selectedDay; // Viewing day
  final int totalDays;    // Total roadmap duration
  final String skill;
  final double progress;

  const ScheduleState({
    this.isLoading = false,
    this.tasks = const [],
    this.isPlanFinalized = false,
    this.activeDay = 1,
    this.selectedDay = 1,
    this.totalDays = 7,  // Default to a week
    this.skill = '',
    this.progress = 0.0,
  });

  ScheduleState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? tasks,
    bool? isPlanFinalized,
    int? activeDay,
    int? selectedDay,
    int? totalDays,
    String? skill,
    double? progress,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      isPlanFinalized: isPlanFinalized ?? this.isPlanFinalized,
      activeDay: activeDay ?? this.activeDay,
      selectedDay: selectedDay ?? this.selectedDay,
      totalDays: totalDays ?? this.totalDays,
      skill: skill ?? this.skill,
      progress: progress ?? this.progress,
    );
  }
}

class ScheduleCubit extends Cubit<ScheduleState> {
  final StudyPlanRepository repository;
  ScheduleCubit({required this.repository}) : super(const ScheduleState());

  /// Initial load or refresh - syncs with active learning day.
  Future<void> loadCurrentDay() async {
    final svc = RoadmapLocalService.instance;
    final activeSkill = await svc.getActiveSkill();
    if (activeSkill == null) {
      emit(state.copyWith(isLoading: false, tasks: [], skill: '', isPlanFinalized: false));
      return;
    }

    // Ensure state progressed
    await svc.progressDayIfNeeded(activeSkill);
    final lState = await svc.getLearningState(activeSkill);
    final int today = lState?['current_day'] as int? ?? 1;

    // Fetch total days from roadmap
    int total = 7;
    final roadmap = await svc.getRoadmapForSkill(activeSkill);
    if (roadmap != null) {
      total = roadmap['total_duration_days'] as int? ?? 7;
    }

    emit(state.copyWith(totalDays: total));
    await loadDay(activeSkill, today, activeDay: today);
  }

  /// Switch the viewing day without changing the "active" learning day.
  Future<void> changeDay(int day) async {
    if (state.skill.isEmpty) return;
    await loadDay(state.skill, day, activeDay: state.activeDay);
  }

  /// Internal worker to load data for any specific day.
  Future<void> loadDay(String activeSkill, int targetDay, {required int activeDay}) async {
    emit(state.copyWith(isLoading: true, selectedDay: targetDay, activeDay: activeDay, skill: activeSkill));

    final List<Map<String, dynamic>> allTasks = [];
    final svc = RoadmapLocalService.instance;

    try {
      final isFinalized = await svc.isPlanFinalized(activeSkill, targetDay);
      final planRow = await svc.getDailyPlan(activeSkill, targetDay);
      
      if (planRow != null) {
        final dayStatus = planRow['status'] as String? ?? 'pending';
        final tasks = planRow['tasks'] as List? ?? [];

        for (int i = 0; i < tasks.length; i++) {
          final t = tasks[i];
          if (t is Map<String, dynamic>) {
            final title = t['title'] ?? 'AI Task';
            final type = t['type'] ?? 'learn';
            final taskId = RoadmapLocalService.generateTaskId(title, type, targetDay, i);
            final tStatus = await svc.getTaskStatus(activeSkill, targetDay, i, taskId) ?? 'pending';

            allTasks.add({
              'title': title,
              'subject': activeSkill,
              'start_time': '',
              'end_time': '${t['duration_minutes'] ?? 30} min',
              'duration_minutes': t['duration_minutes'] ?? 30,
              'status': (dayStatus == 'skipped' || dayStatus == 'completed') ? dayStatus : tStatus,
              'block_type': 'ai_roadmap',
              'task_id': taskId,
              'type': type,
              'original_index': i, // Critical for targeting correct DB row after sorting
            });
          }
        }
      }

      // Sort: Pending -> Completed -> Skipped
      allTasks.sort((a, b) {
        final priority = {'pending': 0, 'completed': 1, 'skipped': 2};
        return (priority[a['status']] ?? 3).compareTo(priority[b['status']] ?? 3);
      });

      // Calculate Progress
      double progress = 0;
      if (allTasks.isNotEmpty) {
        final handled = allTasks.where((t) => t['status'] == 'completed' || t['status'] == 'skipped').length;
        progress = handled / allTasks.length;
      }
      
      emit(state.copyWith(
        isLoading: false,
        tasks: allTasks,
        isPlanFinalized: isFinalized,
        progress: progress,
      ));
    } catch (e) {
      logger.e("Error loading day $targetDay: $e");
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> completeTask(String skill, int day, int originalIndex, String taskId) async {
    final svc = RoadmapLocalService.instance;
    await svc.updateTaskStatus(skill, day, originalIndex, taskId, 'completed');
    await loadDay(skill, day, activeDay: state.activeDay);
  }

  Future<void> skipTask(String skill, int day, int originalIndex, String taskId) async {
    final svc = RoadmapLocalService.instance;
    await svc.updateTaskStatus(skill, day, originalIndex, taskId, 'skipped');
    await loadDay(skill, day, activeDay: state.activeDay);
  }

  Future<void> markDayComplete(String skill, int day) async {
    final svc = RoadmapLocalService.instance;
    await svc.markDayComplete(skill, day);
    await loadCurrentDay(); // Reload to advance to next day
  }
}
