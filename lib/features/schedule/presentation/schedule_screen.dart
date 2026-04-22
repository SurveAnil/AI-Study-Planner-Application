import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/schedule_cubit.dart';
import '../../roadmap/data/roadmap_local_service.dart';
import '../../plan_draft/presentation/day_plan_editor_screen.dart';
import '../../session/presentation/active_session_screen.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late PageController _pageController;
  String? _startDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ScheduleCubit>().loadCurrentDay();
    final state = context.read<ScheduleCubit>().state;
    if (state.skill.isNotEmpty) {
      final lState = await RoadmapLocalService.instance.getLearningState(state.skill);
      if (mounted) {
        setState(() {
          _startDate = lState?['start_date'] as String?;
        });
        
        // Sync page controller to current active day on initial load
        if (_pageController.hasClients) {
          _pageController.jumpToPage(state.activeDay - 1);
        }
      }
    }
  }

  Future<void> _navigateToEditor(String skill, int day) async {
    final roadmap = await RoadmapLocalService.instance.getRoadmapForSkill(skill);
    if (roadmap == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayPlanEditorScreen(
          skill: skill,
          roadmap: roadmap,
          initialDay: day,
        ),
      ),
    ).then((_) {
      if (mounted) context.read<ScheduleCubit>().loadDay(skill, day, activeDay: context.read<ScheduleCubit>().state.activeDay);
    });
  }

  void _onCompleteDay(String skill, int day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Today?'),
        content: const Text('Amazing work! Are you ready to wrap up today and move forward?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.rocket_launch, size: 18),
            label: const Text('Finish Day'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<ScheduleCubit>().markDayComplete(skill, day);
    
    final nextDay = day + 1;
    await RoadmapLocalService.instance.updateCurrentDay(skill, nextDay);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Day completed!')));
      _refresh();
    }
  }

  Future<void> _generateTomorrow(String skill, int tomorrowDay) async {
    final roadmap = await RoadmapLocalService.instance.getRoadmapForSkill(skill);
    if (roadmap == null) return;

    // Show loading
    context.read<ScheduleCubit>().loadDay(skill, tomorrowDay, activeDay: context.read<ScheduleCubit>().state.activeDay);

    try {
      final dioClient = di.sl<DioClient>();
      await dioClient.warmup();
      await dioClient.safeRequest(
        () => dioClient.dio.post(
          '/daily-plan/generate',
          data: {'roadmap': roadmap, 'day': tomorrowDay, 'hours': 4},
        ),
      );
      if (mounted) {
        context.read<ScheduleCubit>().loadDay(skill, tomorrowDay, activeDay: context.read<ScheduleCubit>().state.activeDay);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate plan: $e')));
        context.read<ScheduleCubit>().loadDay(skill, tomorrowDay, activeDay: context.read<ScheduleCubit>().state.activeDay);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.skill.isEmpty ? 'Schedule' : 'Day ${state.selectedDay} — ${state.skill}'),
            centerTitle: false,
          ),
          body: _buildBody(state),
          bottomNavigationBar: _buildBottomAction(state),
        );
      },
    );
  }

  Widget? _buildBottomAction(ScheduleState state) {
    if (state.isLoading || state.skill.isEmpty || !state.isPlanFinalized) return null;
    
    // Only show "Finish Day" button if we are looking at Today
    if (state.selectedDay != state.activeDay) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _navigateToEditor(state.skill, state.selectedDay),
              icon: const Icon(Icons.edit_note),
              label: const Text('Review Plan'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: state.progress >= 1.0 ? () => _onCompleteDay(state.skill, state.activeDay) : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finish Day'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScheduleState state) {
    if (state.skill.isEmpty) {
      return const Center(child: Text("No active skill selected. Go to Home."));
    }

    return Column(
      children: [
        _buildDayNavigator(state),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final targetDay = index + 1;
              context.read<ScheduleCubit>().changeDay(targetDay);
            },
            itemCount: state.totalDays,
            itemBuilder: (context, index) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildDayContent(state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayNavigator(ScheduleState state) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: state.totalDays,
        itemBuilder: (context, index) {
          final int dayNum = index + 1;
          final bool isSelected = state.selectedDay == dayNum;
          final bool isActive = state.activeDay == dayNum;

          final dateStr = _startDate != null 
              ? RoadmapLocalService.instance.calculateDate(_startDate!, dayNum)
              : '';
          
          String formattedDate = '';
          if (dateStr.isNotEmpty) {
            try {
              final dt = DateTime.parse(dateStr);
              formattedDate = DateFormat('MMM d').format(dt);
            } catch (_) {}
          }

          return GestureDetector(
            onTap: () {
              context.read<ScheduleCubit>().changeDay(dayNum);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 110,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? cs.primary 
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Stack(
                children: [
                   Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isActive ? 'Today' : 'Day $dayNum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (isSelected || isActive) ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? cs.primary 
                              : (isActive ? cs.secondary : cs.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected 
                              ? cs.primary.withOpacity(0.8) 
                              : cs.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (dayNum < state.activeDay)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(Icons.check_circle, size: 14, color: AppColors.success),
                    ),
                  if (isSelected && isActive)
                     const Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(Icons.local_fire_department, size: 14, color: AppColors.warning),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayContent(ScheduleState state) {
    final cs = Theme.of(context).colorScheme;
    if (!state.isPlanFinalized && state.tasks.isEmpty) {
      final isFuture = state.selectedDay > state.activeDay;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isFuture ? Icons.event_note : Icons.history, 
                  size: 64, 
                  color: cs.onSurface.withOpacity(0.15)),
              const SizedBox(height: 16),
              Text(
                isFuture ? "Plan not generated yet" : "No plan records for this day",
                style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: cs.onSurface.withOpacity(0.9)),
              ),
              const SizedBox(height: 8),
              Text(
                isFuture 
                  ? "Ready to keep the momentum? Generate your next focus tasks."
                  : "You didn't have a plan generated for this day.",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              if (isFuture)
                FilledButton.icon(
                  onPressed: () => _generateTomorrow(state.skill, state.selectedDay),
                  icon: const Icon(Icons.bolt),
                  label: const Text("Generate Day Plan"),
                ),
            ],
          ),
        ),
      );
    }
    
    if (!state.isPlanFinalized && state.tasks.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_document, size: 56, color: cs.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              "Your plan for Day ${state.selectedDay} is not finalized.",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _navigateToEditor(state.skill, state.selectedDay),
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Go to Plan Editor"),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildProgressBar(state),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _TaskCard(
              task: state.tasks[index],
              day: state.selectedDay,
              onTaskComplete: () => context.read<ScheduleCubit>().completeTask(
                    state.skill,
                    state.selectedDay,
                    state.tasks[index]['original_index'] as int? ?? index,
                    (state.tasks[index]['task_id'] ?? '').toString(),
                  ),
              onTaskSkip: () => context.read<ScheduleCubit>().skipTask(
                    state.skill,
                    state.selectedDay,
                    state.tasks[index]['original_index'] as int? ?? index,
                    (state.tasks[index]['task_id'] ?? '').toString(),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ScheduleState state) {
    final cs = Theme.of(context).colorScheme;
    final pct = (state.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
              Text(
                '$pct%',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final int day;
  final VoidCallback onTaskComplete;
  final VoidCallback onTaskSkip;

  const _TaskCard({
    required this.task,
    required this.day,
    required this.onTaskComplete,
    required this.onTaskSkip,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = widget.task['status'] as String? ?? 'pending';
    final isDone = status == 'completed' || status == 'skipped';
    final isPaused = status == 'paused';
    final isCompleted = status == 'completed';
    
    // Day Locking Logic
    final activeDay = context.read<ScheduleCubit>().state.activeDay;
    final isFutureDay = widget.day > activeDay;
    final isLocked = isFutureDay && !isDone;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isDone 
            ? Colors.white.withOpacity(0.02) 
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(isDone ? 0.04 : 0.08),
          width: 1,
        ),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLocked 
                      ? cs.surfaceContainerHighest
                      : (isCompleted
                          ? AppColors.success.withAlpha(30)
                          : (status == 'skipped' ? Colors.grey.withAlpha(30) : (isPaused ? AppColors.warning.withAlpha(30) : cs.primaryContainer))),
                  child: Icon(
                    isLocked ? Icons.lock_outline : (isCompleted ? Icons.check : (status == 'skipped' ? Icons.block : (isPaused ? Icons.pause_rounded : Icons.book))),
                    color: isLocked ? cs.outline : (isCompleted ? AppColors.success : (status == 'skipped' ? Colors.grey : (isPaused ? AppColors.warning : cs.primary))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task['title'] as String? ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                        ),
                      ),
                      Text(
                        '${widget.task['duration_minutes'] ?? 30} min • ${widget.task['type'] ?? 'learn'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "LOCKED",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.outline,
                        letterSpacing: 1.1,
                      ),
                    ),
                  )
                else if (isDone)
                  Chip(
                    label: Text(
                      isCompleted ? 'DONE' : 'SKIPPED',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    side: BorderSide.none,
                    backgroundColor: isCompleted ? AppColors.success.withAlpha(30) : Colors.grey.withAlpha(30),
                  ),
              ],
            ),
            if (!isDone && !isLocked) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!mounted) return;
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveSessionScreen(
                              taskId: widget.task['task_id'] as String? ?? '',
                              taskTitle: widget.task['title'] as String? ?? 'Focus Session',
                              plannedDurationMinutes: widget.task['duration_minutes'] as int? ?? 30,
                              skill: context.read<ScheduleCubit>().state.skill,
                              day: widget.day,
                              isResume: isPaused,
                            ),
                          ),
                        ).then((_) {
                           if (!mounted) return;
                           // Ensure schedule updates if session finished
                           context.read<ScheduleCubit>().loadDay(
                             context.read<ScheduleCubit>().state.skill,
                             widget.day,
                             activeDay: context.read<ScheduleCubit>().state.activeDay,
                           );
                        });
                      },
                      icon: Icon(isPaused ? Icons.play_circle_outline : Icons.play_arrow_rounded),
                      label: Text(isPaused ? 'Resume Focus' : 'Start Focus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onTaskSkip,
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
