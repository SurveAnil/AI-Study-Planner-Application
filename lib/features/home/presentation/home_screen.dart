import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../features/roadmap/data/roadmap_local_service.dart';
import '../../ai_chat/presentation/ai_chat_screen.dart';
import 'widgets/greeting_card.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/quick_action_grid.dart';
import 'package:ai_study_planner/features/home/presentation/main_nav_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const MainNavScreen(initialIndex: 3)),
                  (route) => false,
                );
              },
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D1FF), Color(0xFF007BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profile_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Symbols.person_filled_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'KanMantr AI',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Symbols.notifications_active_rounded,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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

                const QuickStatsRow(),
                const SizedBox(height: AppSpacing.space6),

                // ── Active Skill (Compact, AFTER stats) ──────────────────
                if (!_loadingResume && _allSkills.isNotEmpty)
                  _ActiveSkillSelector(
                    skills: _allSkills,
                    activeSkill: _activeSkill,
                    onChanged: _onSkillChanged,
                  ),
                if (!_loadingResume && _allSkills.isNotEmpty)
                  const SizedBox(height: AppSpacing.space8),

                // ── Continue Learning card (PRIORITY) ──────────────────────
                if (!_loadingResume && _savedRoadmap != null)
                  _ContinueLearningCard(
                    roadmap: _savedRoadmap!,
                    resumeDay: _resumeDay,
                  ),
                if (!_loadingResume && _savedRoadmap != null)
                  const SizedBox(height: AppSpacing.space8),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_rounded,
                color: cs.primary.withAlpha(120),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Focusing on',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant.withAlpha(200),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: (activeSkill != null && skills.contains(activeSkill))
                    ? activeSkill
                    : (skills.isNotEmpty ? skills.first : null),
                isDense: true,
                isExpanded: true,
                alignment: Alignment.centerRight,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: cs.primary,
                  size: 20,
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: cs.surfaceContainerHigh,
                items: skills
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        alignment: Alignment.centerRight,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      ),
                    )
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

  const _ContinueLearningCard({required this.roadmap, required this.resumeDay});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final skill = roadmap['skill'] as String? ?? 'Your Roadmap';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        gradient: LinearGradient(
          colors: [cs.primary.withAlpha(40), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainNavScreen(initialIndex: 1)),
            (route) => false,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTINUE LEARNING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          skill,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withAlpha(100),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Day $resumeDay',
                  ),
                  _InfoChip(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Personalized',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
