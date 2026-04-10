import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../features/roadmap/data/roadmap_local_service.dart';
import '../../../features/plan_draft/presentation/day_plan_editor_screen.dart';
import '../../ai_chat/presentation/ai_chat_screen.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/ai_banner.dart';
import 'package:ai_study_planner/features/home/presentation/main_nav_screen.dart';

/// Screen S03: Home Dashboard
///
/// Phase 1.7 changes:
/// - Active Skill selector (dropdown chip) at top
/// - Smart Continue Learning: uses active skill → getRoadmapForSkill()
/// - Shows "Continue Learning" only when roadmap exists AND days remain
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ───────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _savedRoadmap;
  bool _loadingResume = true;
  int _resumeDay = 1;

  // Active skill system
  String? _activeSkill;
  List<String> _allSkills = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final svc = RoadmapLocalService.instance;

    // 1. Load all distinct skills for the dropdown
    final skills = await svc.getDistinctSkills();

    // 2. Determine active skill
    String? activeSkill = await svc.getActiveSkill();
    if (activeSkill == null && skills.isNotEmpty) {
      // No active skill set → default to latest
      activeSkill = skills.first;
      await svc.setActiveSkill(activeSkill);
    }

    // 3. Load roadmap for active skill
    Map<String, dynamic>? roadmap;
    int resumeDay = 1;
    if (activeSkill != null) {
      roadmap = await svc.getRoadmapForSkill(activeSkill);
      if (roadmap != null) {
        // getNextPendingDay() correctly skips both completed AND skipped days.
        resumeDay = await svc.getNextPendingDay(activeSkill);
      }
    }

    if (mounted) {
      setState(() {
        _allSkills = skills;
        _activeSkill = activeSkill;
        _savedRoadmap = roadmap;
        _resumeDay = resumeDay;
        _loadingResume = false;
      });
    }
  }

  Future<void> _onSkillChanged(String skill) async {
    setState(() => _loadingResume = true);
    await RoadmapLocalService.instance.setActiveSkill(skill);
    await _loadSavedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSavedData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space4),
                const GreetingCard(),
                const SizedBox(height: AppSpacing.space6),

                // ── Active Skill Selector ─────────────────────────────────
                if (!_loadingResume && _allSkills.isNotEmpty)
                  _ActiveSkillSelector(
                    skills: _allSkills,
                    activeSkill: _activeSkill,
                    onChanged: _onSkillChanged,
                  ),
                if (!_loadingResume && _allSkills.isNotEmpty)
                  const SizedBox(height: AppSpacing.space4),
                // ──────────────────────────────────────────────────────────

                const QuickStatsRow(),
                const SizedBox(height: AppSpacing.space6),
                const AIBanner(),
                const SizedBox(height: AppSpacing.space6),

                // ── Continue Learning card ─────────────────────────────────
                if (!_loadingResume && _savedRoadmap != null)
                  _ContinueLearningCard(
                    roadmap: _savedRoadmap!,
                    resumeDay: _resumeDay,
                  ),
                if (!_loadingResume && _savedRoadmap != null)
                  const SizedBox(height: AppSpacing.space6),
                // ──────────────────────────────────────────────────────────

                const QuickActionGrid(),
                const SizedBox(height: AppSpacing.space16),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_chat_fab',
        tooltip: 'AI Chat',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Skill Selector
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveSkillSelector extends StatelessWidget {
  final List<String> skills;
  final String? activeSkill;
  final ValueChanged<String> onChanged;

  const _ActiveSkillSelector({
    required this.skills,
    required this.activeSkill,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            'Active Skill',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: (activeSkill != null && skills.contains(activeSkill))
                    ? activeSkill
                    : (skills.isNotEmpty ? skills.first : null),
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: cs.primary, size: 20),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                borderRadius: BorderRadius.circular(12),
                items: skills
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Continue Learning Card
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueLearningCard extends StatelessWidget {
  final Map<String, dynamic> roadmap;
  final int resumeDay;

  const _ContinueLearningCard({
    required this.roadmap,
    required this.resumeDay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final skill = roadmap['skill'] as String? ?? 'Your Roadmap';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MainNavScreen(initialIndex: 1),
              ),
              (route) => false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue Learning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skill,
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Day $resumeDay',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
