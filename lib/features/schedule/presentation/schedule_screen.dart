import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/schedule_cubit.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Schedule'),
        centerTitle: false,
      ),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_rounded, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'No tasks planned for today.\nGenerate a study plan to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = state.tasks[index];
              final blockType = task['block_type'] as String? ?? 'study';
              final isBreak = blockType == 'break';
              final isAiTask = blockType == 'ai_roadmap';

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isAiTask
                      ? const Color(0xFF6C63FF).withAlpha(31)
                      : isBreak
                          ? Colors.green.withValues(alpha: 0.12)
                          : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    isAiTask
                        ? Icons.auto_awesome
                        : isBreak
                            ? Icons.coffee_rounded
                            : Icons.book_rounded,
                    size: 18,
                    color: isAiTask
                        ? const Color(0xFF6C63FF)
                        : isBreak
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] as String? ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isAiTask)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withAlpha(31),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF6C63FF).withAlpha(77)),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  isAiTask
                      ? '${task['subject'] ?? ''} · ${task['end_time'] ?? ''}'
                      : '${task['start_time'] ?? ''} – ${task['end_time'] ?? ''}  ·  ${task['subject'] ?? ''}',
                ),
                trailing: Chip(
                  label: Text(
                    (task['status'] as String? ?? 'pending').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
