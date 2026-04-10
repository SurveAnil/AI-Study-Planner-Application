import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/roadmap/data/roadmap_local_service.dart';
import '../../../features/roadmap/presentation/roadmap_input_screen.dart';
import '../bloc/plan_draft_bloc.dart';
import '../../schedule/bloc/schedule_cubit.dart';
import 'manual_plan_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTask {
  String title;
  String type; // learn | practice | project
  String description;
  int durationMinutes;
  String? taskId;        // Preserved from JSON
  int originalDuration;  // To detect changes

  _DailyTask({
    required this.title,
    required this.type,
    required this.description,
    required this.durationMinutes,
    this.taskId,
    this.originalDuration = 0,
  });

  factory _DailyTask.fromJson(Map<String, dynamic> json) {
    final duration = (json['duration_minutes'] as num?)?.toInt() ?? 30;
    return _DailyTask(
      title: json['title'] as String? ?? 'Task',
      type: json['type'] as String? ?? 'learn',
      description: json['description'] as String? ?? '',
      durationMinutes: duration,
      taskId: json['task_id'] as String?,
      originalDuration: duration,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Phase 1.6 — DayPlanEditorScreen (CRITICAL FIX)
/// Receives a [roadmap] from RoadmapScreen, auto-generates a daily plan.
/// Supports checking cache, generating plan, editing plan, and saving.
class DayPlanEditorScreen extends StatefulWidget {
  final String skill;
  final int initialDay;
  final Map<String, dynamic>? roadmap; // Optional fallback

  const DayPlanEditorScreen({
    super.key,
    required this.skill,
    this.initialDay = 1,
    this.roadmap,
  });

  @override
  State<DayPlanEditorScreen> createState() => _DayPlanEditorScreenState();
}

class _DayPlanEditorScreenState extends State<DayPlanEditorScreen> {
  // State
  bool _loading = true;
  String? _error;
  List<_DailyTask> _tasks = [];
  String _skill = '';
  String? _warning;
  int _day = 1;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _skill = widget.skill;
    _fetchDailyPlan(day: widget.initialDay);
  }

  // ── API Call ────────────────────────────────────────────────────────────────

  Future<void> _fetchDailyPlan({int day = 1, int hours = 4}) async {
    print("DayPlanEditor: Loading day $day");
    setState(() {
      _loading = true;
      _error = null;
      _day = day;
    });

    try {
      // 1. Ensure we have a roadmap (fetch from DB if missing from constructor)
      Map<String, dynamic>? roadmap = widget.roadmap;
      if (roadmap == null) {
        roadmap = await RoadmapLocalService.instance.getRoadmapForSkill(_skill);
      }

      if (roadmap == null) {
        setState(() {
          _error = "Roadmap not found for $_skill";
          _loading = false;
        });
        return;
      }

      // 2. Check SQLite cache
      final cached = await RoadmapLocalService.instance.getDailyPlan(
        _skill,
        day,
      );
      if (cached != null) {
        print("Plan exists: true");
        final rawTasks = cached['tasks'] as List? ?? [];
        if (mounted) {
          setState(() {
            _tasks = rawTasks
                .whereType<Map<String, dynamic>>()
                .map((t) => _DailyTask.fromJson(t))
                .toList();
            _warning = cached['_warning'] as String?;
            _loading = false;
          });
        }
        return;
      }

      print("Plan exists: false");
      print("Generating plan from API");

      // 3. No cache — call backend
      final dioClient = DioClient();
      final dio = dioClient.dio;
      await dioClient.warmup();

      final response = await dioClient.safeRequest(
        () => dio.post<Map<String, dynamic>>(
          '/daily-plan/generate',
          data: {'roadmap': roadmap, 'day': day, 'hours': hours},
        ),
      );

      final data = response.data ?? {};

      // Calculate date from learning state (NO DateTime.now() fallback for logic)
      final state = await RoadmapLocalService.instance.getLearningState(_skill);
      String dateStr = '';
      if (state != null) {
        final startDateStr = state['start_date'] as String;
        dateStr = RoadmapLocalService.instance.calculateDate(startDateStr, day);
      } else {
        // Strict rule: DO NOT use DateTime.now() if state is missing.
        // We'll use a placeholder or error out if critical.
        dateStr = "2000-01-01"; // Safety placeholder
      }

      await RoadmapLocalService.instance.saveDailyPlan(
        _skill,
        day,
        data,
        date: dateStr,
        generationStatus: 'success',
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading plan: $e';
          _loading = false;
        });
      }
    }
  }

  // ── Task Edit ─────────────────────────────────────────────────────────────

  void _onEditTask(int index) async {
    final task = _tasks[index];
    final titleController = TextEditingController(text: task.title);
    final durationController = TextEditingController(
      text: task.durationMinutes.toString(),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Duration (min)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newDuration =
                  int.tryParse(durationController.text.trim()) ??
                  task.durationMinutes;
              if (newTitle.isNotEmpty) {
                // Check if duration changed
                if (newDuration != task.originalDuration && task.taskId != null) {
                   // User edited time -> Mark as paused to allow Resume
                   final dbSvc = RoadmapLocalService.instance;
                   // Re-fetch current status
                   final progress = await dbSvc.getDailyPlan(widget.skill, _day);
                   final currentStatus = progress?['status'] as String? ?? 'pending';
                   
                   // Update status specifically in task_progress table
                   await dbSvc.updateTaskStatus(
                     widget.skill, 
                     _day, 
                     index, 
                     task.taskId!, 
                     'paused', // Set to paused so UI shows "Resume"
                   );
                }

                setState(() {
                  task.title = newTitle;
                  task.durationMinutes = newDuration;
                });
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      _saveCurrentTasksToCache();
    }
  }

  Future<void> _saveCurrentTasksToCache() async {
    final tasksJson = _tasks
        .map(
          (t) => {
            'title': t.title,
            'type': t.type,
            'description': t.description,
            'duration_minutes': t.durationMinutes,
          },
        )
        .toList();

    final data = {
      'tasks': tasksJson,
      if (_warning != null) '_warning': _warning,
    };

    // Calculate date from learning state
    final state = await RoadmapLocalService.instance.getLearningState(_skill);
    String dateStr = '2000-01-01';
    if (state != null) {
      dateStr = RoadmapLocalService.instance.calculateDate(
        state['start_date'],
        _day,
      );
    }

    await RoadmapLocalService.instance.saveDailyPlan(
      _skill,
      _day,
      data,
      date: dateStr,
      generationStatus: 'success',
    );
  }

  // ── Save Plan & Execute ───────────────────────────────────────────────────

  Future<void> _savePlanAndExecute() async {
    print("Saving plan");
    await _saveCurrentTasksToCache();
    await RoadmapLocalService.instance.finalizePlan(_skill, _day);

    // Sync with Schedule screen
    if (mounted) {
      context.read<ScheduleCubit>().loadCurrentDay();
    }

    print("Navigating to ScheduleScreen");
    if (!mounted) return;

    // Use specific path or pop until main nav
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved! Go to Schedule.')),
    );
  }

  // ── Next/Previous Day ──────────────────────────────────────────────────────

  void _goToPreviousDay() async {
    if (_day > 1) {
      await _saveCurrentTasksToCache();
      _fetchDailyPlan(day: _day - 1);
    }
  }

  Future<void> _generateNextDay() async {
    await _saveCurrentTasksToCache();
    _fetchDailyPlan(day: _day + 1);
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
      ),
      body: _buildBody(context, cs),
      bottomNavigationBar: (!_loading && _error == null)
          ? _BottomActionBar(
              day: _day,
              onSavePlan: _savePlanAndExecute,
              onPreviousDay: _day > 1 ? _goToPreviousDay : null,
              onNextDay: _generateNextDay,
            )
          : null,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
                    onEdit: () => _onEditTask(index),
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
  final int day;
  final VoidCallback onSavePlan;
  final VoidCallback? onPreviousDay;
  final VoidCallback onNextDay;

  const _BottomActionBar({
    required this.day,
    required this.onSavePlan,
    this.onPreviousDay,
    required this.onNextDay,
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
        child: Row(
          children: [
            if (onPreviousDay != null) ...[
              ElevatedButton(
                onPressed: onPreviousDay,
                child: const Text("← Prev"),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: onSavePlan,
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Save Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onNextDay, child: const Text("Next →")),
          ],
        ),
      ),
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
  final VoidCallback onEdit;

  const _TaskCard({required this.task, required this.onEdit});

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(128), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow or Edit Icon
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
