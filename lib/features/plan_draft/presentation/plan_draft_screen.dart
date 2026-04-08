import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/roadmap/data/roadmap_local_service.dart';
import '../../../features/roadmap/presentation/roadmap_input_screen.dart';
import '../bloc/plan_draft_bloc.dart';
import 'manual_plan_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTask {
  final String title;
  final String type; // learn | practice | project
  final String description;
  final int durationMinutes;
  bool completed = false;

  _DailyTask({
    required this.title,
    required this.type,
    required this.description,
    required this.durationMinutes,
  });

  factory _DailyTask.fromJson(Map<String, dynamic> json) {
    return _DailyTask(
      title: json['title'] as String? ?? 'Task',
      type: json['type'] as String? ?? 'learn',
      description: json['description'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Phase 1.6 — PlanDraftScreen
/// Receives a [roadmap] from RoadmapScreen, auto-generates a daily plan.
/// Supports stage-based learning, day completion, and date binding.
class PlanDraftScreen extends StatefulWidget {
  final String skill;
  final Map<String, dynamic> roadmap;
  final int stageIndex;
  final int initialDay;

  const PlanDraftScreen({
    super.key,
    required this.skill,
    required this.roadmap,
    this.stageIndex = 0,
    this.initialDay = 1,
  });

  @override
  State<PlanDraftScreen> createState() => _PlanDraftScreenState();
}

class _PlanDraftScreenState extends State<PlanDraftScreen> {
  // State
  bool _loading = true;
  String? _error;
  List<_DailyTask> _tasks = [];
  String _skill = '';
  String? _warning;
  int _day = 1;
  bool _dayCompleted = false;
  bool _daySkipped = false;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _skill = widget.skill;
    _fetchDailyPlan(day: widget.initialDay);
  }

  // ── API Call ────────────────────────────────────────────────────────────────

  Future<void> _fetchDailyPlan({int day = 1, int hours = 4}) async {
    setState(() {
      _loading = true;
      _error = null;
      _day = day;
    });

    final completed = await RoadmapLocalService.instance.isDayCompleted(
      _skill,
      day,
    );

    // ── 1. Check SQLite cache first ───────────────────────────────────────────
    final cached = await RoadmapLocalService.instance.getDailyPlan(_skill, day);
    
    // Also check if status is skipped
    final isSkipped = cached != null && cached['status'] == 'skipped';
    if (cached != null && mounted) {
      final rawTasks = cached['tasks'] as List? ?? [];
      final tasks = rawTasks
          .whereType<Map<String, dynamic>>()
          .map((t) => _DailyTask.fromJson(t))
          .toList();

      // ── Restore task completion state from task_progress ─────────────────
      for (int i = 0; i < tasks.length; i++) {
        final status = await RoadmapLocalService.instance.getTaskStatus(
          _skill,
          day,
          i,
        );
        if (status == 'completed') {
          tasks[i].completed = true;
        }
      }

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _warning = cached['_warning'] as String?;
          _loading = false;
          _dayCompleted = completed;
          _daySkipped = isSkipped;
        });
      }
      return; // skip API
    }

    // ── 2. No cache — call backend ────────────────────────────────────────────
    final dioClient = DioClient();
    final dio = dioClient.dio;

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/daily-plan/generate',
        data: {'roadmap': widget.roadmap, 'day': day, 'hours': hours},
      );

      final data = response.data ?? {};

      // ── 3. Save to SQLite cache with date binding ───────────────────────────
      // Day 1 = today, Day 2 = tomorrow, etc.
      final date = DateTime.now()
          .add(Duration(days: day - 1))
          .toIso8601String()
          .split('T')[0];
      await RoadmapLocalService.instance.saveDailyPlan(
        _skill,
        day,
        data,
        date: date,
        stageIndex: widget.stageIndex,
      );

      final rawTasks = data['tasks'] as List? ?? [];
      if (mounted) {
        setState(() {
          _tasks = rawTasks
              .whereType<Map<String, dynamic>>()
              .map((t) => _DailyTask.fromJson(t))
              .toList();
          _warning = data['_warning'] as String?;
          _loading = false;
          _dayCompleted = completed;
          _daySkipped = false; // Fresh plans are never skipped by default
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect to backend.\n${e.message}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _loading = false;
        });
      }
    }
  }

  // ── Task Toggle ─────────────────────────────────────────────────────────────

  void _onToggleTask(int index) async {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
    });
    final status = _tasks[index].completed ? 'completed' : 'pending';
    await RoadmapLocalService.instance.updateTaskStatus(
      _skill,
      _day,
      index,
      status,
    );
  }

  // ── Day Completion ──────────────────────────────────────────────────────────

  Future<void> _completeDayAndNext() async {
    await RoadmapLocalService.instance.markDayComplete(
      _skill,
      _day,
      stageIndex: widget.stageIndex,
    );
    // Mark as completed in daily_plan_cache too.
    final db = await RoadmapLocalService.instance.getDailyPlan(_skill, _day);
    if(db != null) {
      await RoadmapLocalService.instance.updateTaskStatus(_skill, _day, 0, 'completed'); // Just a hack to force rebuild doesn't actually update plan status
    }

    if (!mounted) return;

    final nextDay = await RoadmapLocalService.instance.getNextPendingDay(_skill);

    // Navigate to next day
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDraftScreen(
          skill: _skill,
          roadmap: widget.roadmap,
          stageIndex: widget.stageIndex,
          initialDay: nextDay,
        ),
      ),
    );
  }

  // ── Skip Day ──────────────────────────────────────────────────────────
  
  Future<void> _skipDay() async {
    await RoadmapLocalService.instance.markDaySkipped(_skill, _day);

    if (!mounted) return;

    final nextDay = await RoadmapLocalService.instance.getNextPendingDay(_skill);

    // Navigate to next day
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDraftScreen(
          skill: _skill,
          roadmap: widget.roadmap,
          stageIndex: widget.stageIndex,
          initialDay: nextDay,
        ),
      ),
    );
  }

  // ── Change Goal ─────────────────────────────────────────────────────────────

  Future<void> _changeGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Goal?'),
        content: const Text(
          'This will clear all saved plans for this skill. You can generate a new roadmap afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change Goal'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await RoadmapLocalService.instance.clearPlansForSkill(_skill);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoadmapInputScreen()),
      (route) => route.isFirst,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Day $_day — $_skill'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 0,
        actions: [
          if (!_loading)
            IconButton(
              tooltip: 'Change Goal',
              icon: const Icon(Icons.swap_horiz),
              onPressed: _changeGoal,
            ),
        ],
      ),
      body: _buildBody(context, cs),
      // ── Bottom Action Bar ──────────────────────────────────────────────────
      bottomNavigationBar: (!_loading && _error == null)
          ? _BottomActionBar(
              allDone: _tasks.isNotEmpty && _tasks.every((t) => t.completed),
              dayCompleted: _dayCompleted,
              daySkipped: _daySkipped,
              day: _day,
              onCompleteDay: _completeDayAndNext,
              onPreviousDay: _day > 1 ? _goToPreviousDay : null,
              onSkipDay: _skipDay,
            )
          : null,
    );
  }

  void _goToPreviousDay() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDraftScreen(
          skill: _skill,
          roadmap: widget.roadmap,
          stageIndex: widget.stageIndex,
          initialDay: _day - 1,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme cs) {
    if (_loading) return _buildLoading(cs);
    if (_error != null) return _buildError();
    return _buildTaskList(context, cs);
  }

  // ── Loading ─────────────────────────────────────────────────────────────────

  Widget _buildLoading(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 20),
          Text(
            'Generating Day $_day plan…',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Analysing your $_skill roadmap',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _fetchDailyPlan(day: _day),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openManualPlan,
              icon: const Icon(Icons.edit_document),
              label: const Text('Build Manually Instead'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Task List ───────────────────────────────────────────────────────────────

  Widget _buildTaskList(BuildContext context, ColorScheme cs) {
    final completedCount = _tasks.where((t) => t.completed).length;
    final totalMinutes = _tasks.fold<int>(
      0,
      (sum, t) => sum + t.durationMinutes,
    );

    return Column(
      children: [
        // Warning banner
        if (_warning != null && _warning!.isNotEmpty)
          _WarningBanner(message: _warning!),

        // Progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: cs.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: cs.onPrimaryContainer,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Day $_day • ${_tasks.length} tasks • ${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completedCount / ${_tasks.length} done',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        LinearProgressIndicator(
          value: _tasks.isEmpty ? 0 : completedCount / _tasks.length,
          backgroundColor: cs.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          minHeight: 4,
        ),

        // Task list
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks generated.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TaskCard(
                    task: _tasks[index],
                    onToggle: () => _onToggleTask(index),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Manual Plan Fallback ─────────────────────────────────────────────────────

  void _openManualPlan() {
    final planBloc = context.read<PlanDraftBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: planBloc,
          child: const ManualPlanFormScreen(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool allDone;
  final bool dayCompleted;
  final bool daySkipped;
  final int day;
  final VoidCallback onCompleteDay;
  final VoidCallback? onPreviousDay;
  final VoidCallback onSkipDay;

  const _BottomActionBar({
    required this.allDone,
    required this.dayCompleted,
    required this.daySkipped,
    required this.day,
    required this.onCompleteDay,
    this.onPreviousDay,
    required this.onSkipDay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: dayCompleted || daySkipped
            ? _buildCompletedState(context, cs)
            : _buildActiveState(context, cs),
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, ColorScheme cs) {
    final color = daySkipped ? Colors.grey : const Color(0xFF10B981);
    final icon = daySkipped ? Icons.next_plan : Icons.check_circle;
    final text = daySkipped ? 'Day $day skipped' : 'Day $day completed!';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(31),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (onPreviousDay != null) ...[
          ElevatedButton(
            onPressed: onPreviousDay,
            child: const Text("← Previous Day"),
          ),
          const SizedBox(width: 10),
        ],
        FilledButton.icon(
          onPressed: onCompleteDay,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Next Day'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveState(BuildContext context, ColorScheme cs) {
    if (allDone) {
      // All tasks done — prompt to complete day.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onPreviousDay != null) ...[
                ElevatedButton(
                  onPressed: onPreviousDay,
                  child: const Text("← Previous Day"),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCompleteDay,
                  icon: const Icon(Icons.celebration, size: 20),
                  label: Text('Complete Day $day & Next →'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Secondary: Take Day Off
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSkipDay,
              icon: Icon(Icons.beach_access_rounded,
                  size: 15, color: Colors.orange.shade600),
              label: Text(
                'Take Day Off Instead',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Tasks remain — show progress hint + Take Day Off.
    return Row(
      children: [
        if (onPreviousDay != null) ...[
          ElevatedButton(
            onPressed: onPreviousDay,
            child: const Text("← Previous Day"),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            'Complete all tasks to advance',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        TextButton.icon(
          onPressed: onSkipDay,
          icon: Icon(Icons.beach_access_rounded,
              size: 16, color: Colors.orange.shade600),
          label: Text(
            'Take Day Off',
            style: TextStyle(color: Colors.orange.shade600),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final _DailyTask task;
  final VoidCallback onToggle;

  const _TaskCard({required this.task, required this.onToggle});

  static const _typeIcons = {
    'learn': Icons.menu_book_outlined,
    'practice': Icons.code,
    'project': Icons.rocket_launch_outlined,
  };

  static const _typeColors = {
    'learn': Color(0xFF6C63FF),
    'practice': Color(0xFF10B981),
    'project': Color(0xFFF59E0B),
  };

  static const _typeLabels = {
    'learn': 'LEARN',
    'practice': 'PRACTICE',
    'project': 'PROJECT',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _typeColors[task.type] ?? AppColors.primary;
    final icon = _typeIcons[task.type] ?? Icons.task_alt;
    final label = _typeLabels[task.type] ?? task.type.toUpperCase();

    return AnimatedOpacity(
      opacity: task.completed ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: task.completed ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: task.completed ? cs.outlineVariant : color.withAlpha(128),
            width: task.completed ? 1 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.completed ? color : Colors.transparent,
                      border: Border.all(
                        color: task.completed ? color : cs.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: task.completed
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : null,
                  ),
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type chip + duration
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(31),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withAlpha(77)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${task.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.completed ? cs.onSurfaceVariant : null,
                        ),
                      ),

                      // Description
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
