import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ai_chat/bloc/ai_chat_cubit.dart';
import '../../ai_chat/bloc/ai_chat_state.dart';
import '../data/roadmap_local_service.dart';
import 'roadmap_history_screen.dart';
import 'roadmap_screen.dart';

/// Standalone skill-input screen that generates a roadmap.
///
/// Flow:
///   User types skill → taps "Generate" → AiChatCubit.generateRoadmap()
///   → on RoadmapSuccess: save to SQLite, navigate to RoadmapScreen
///
/// Previously this lived as Tab 2 inside AiChatScreen (now removed).
class RoadmapInputScreen extends StatefulWidget {
  const RoadmapInputScreen({super.key});

  @override
  State<RoadmapInputScreen> createState() => _RoadmapInputScreenState();
}

class _RoadmapInputScreenState extends State<RoadmapInputScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _hasTriggeredNav = false; // guard against double navigation

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _generate() {
    final skill = _ctrl.text.trim();
    if (skill.isEmpty) return;
    _hasTriggeredNav = false;
    context.read<AiChatCubit>().generateRoadmap(skill);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<AiChatCubit, AiChatState>(
      listener: (context, state) async {
        if (state is RoadmapSuccess && !_hasTriggeredNav) {
          _hasTriggeredNav = true;

          final skill =
              state.roadmap['skill'] as String? ?? _ctrl.text.trim();

          // ── Persist to SQLite ──────────────────────────────────────────
          await RoadmapLocalService.instance.saveRoadmap(skill, state.roadmap);
          // Set this as the active skill
          await RoadmapLocalService.instance.setActiveSkill(skill);
          // Clear stale daily plans from a previous roadmap for this skill
          await RoadmapLocalService.instance.clearPlansForSkill(skill);

          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RoadmapScreen(skill: skill, roadmap: state.roadmap),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AiChatLoading;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text('Generate Roadmap'),
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Roadmap History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoadmapHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero icon ──────────────────────────────────────────
                  const SizedBox(height: 24),
                  Icon(
                    Icons.map_outlined,
                    size: 72,
                    color: cs.primary.withAlpha(89),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What do you want to learn?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter any skill and we\'ll build a complete\nlearning roadmap for you.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // ── Skill input ────────────────────────────────────────
                  TextField(
                    controller: _ctrl,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g. Flutter Developer, Machine Learning…',
                      prefixIcon:
                          Icon(Icons.school_outlined, color: cs.primary),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                  const SizedBox(height: 16),

                  // ── Generate button ────────────────────────────────────
                  FilledButton.icon(
                    onPressed: isLoading ? null : _generate,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(isLoading
                        ? 'Generating roadmap…'
                        : 'Generate Roadmap'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  // ── Error ──────────────────────────────────────────────
                  if (state is AiChatError) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: cs.onErrorContainer, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.message,
                              style: TextStyle(color: cs.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Tips ───────────────────────────────────────────────
                  if (!isLoading && state is! AiChatError) ...[
                    const SizedBox(height: 32),
                    _ExampleChips(onTap: (s) {
                      _ctrl.text = s;
                      _generate();
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Example skill chips ───────────────────────────────────────────────────────

class _ExampleChips extends StatelessWidget {
  final void Function(String) onTap;
  const _ExampleChips({required this.onTap});

  static const _examples = [
    'Flutter Developer',
    'Machine Learning',
    'Web Design',
    'Data Structures',
    'Python for AI',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try one of these',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map(
                (e) => ActionChip(
                  label: Text(e),
                  onPressed: () => onTap(e),
                  backgroundColor: cs.surfaceContainerHighest,
                  labelStyle: TextStyle(color: cs.primary),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
