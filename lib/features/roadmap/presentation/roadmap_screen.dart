import 'package:flutter/material.dart';
import '../../plan_draft/presentation/plan_draft_screen.dart';
import 'roadmap_history_screen.dart';
import 'roadmap_input_screen.dart';

/// RoadmapScreen — Phase 1.6
/// Receives the roadmap [Map] and renders stage cards with topics, tools and
/// projects.  Each stage has its own "Start Stage" button that navigates to
/// PlanDraftScreen with the corresponding stageIndex.
class RoadmapScreen extends StatefulWidget {
  final String skill;
  final Map<String, dynamic> roadmap;

  const RoadmapScreen({super.key, required this.skill, required this.roadmap});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Track which stage cards are expanded
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    final stages = widget.roadmap['stages'] as List? ?? [];
    _expanded = List.generate(stages.length, (i) => i == 0); // first open

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roadmap = widget.roadmap;
    final stages = roadmap['stages'] as List? ?? [];
    final skill = widget.skill;
    final overview = roadmap['overview'] as String? ?? '';
    final totalDays = roadmap['total_duration_days'] ?? '—';
    final warning = roadmap['_warning'] as String?;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ─── Header Sliver ───────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
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
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(
                  skill,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary,
                        cs.tertiary,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(20),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Body ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner (mock fallback)
                    if (warning != null && warning.isNotEmpty)
                      _WarningBanner(message: warning),

                    // Overview card
                    _OverviewCard(
                        overview: overview, totalDays: totalDays.toString()),

                    const SizedBox(height: 20),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        '📚 Learning Stages',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Stage Cards ─────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final stage =
                      stages[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: _StageCard(
                      stage: stage,
                      index: index,
                      isExpanded: _expanded[index],
                      onToggle: () => setState(
                          () => _expanded[index] = !_expanded[index]),
                      onStartStage: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanDraftScreen(
                              skill: widget.skill,
                              roadmap: widget.roadmap,
                              stageIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: stages.length,
              ),
            ),

            // ─── Generate New Roadmap Button ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoadmapInputScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Generate New Roadmap'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      // Global FAB removed — each stage now has its own "Start Stage" button
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
      margin: const EdgeInsets.only(bottom: 12),
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

class _OverviewCard extends StatelessWidget {
  final String overview;
  final String totalDays;
  const _OverviewCard({required this.overview, required this.totalDays});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withAlpha(128),
            cs.secondaryContainer.withAlpha(77),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Roadmap Overview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalDays days',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (overview.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              overview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Map<String, dynamic> stage;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onStartStage;

  const _StageCard({
    required this.stage,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
    required this.onStartStage,
  });

  static const List<Color> _stageColors = [
    Color(0xFF6C63FF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _stageColors[index % _stageColors.length];

    final title = stage['title'] as String? ?? 'Stage ${index + 1}';
    final description = stage['description'] as String? ?? '';
    final durationDays = stage['duration_days'] ?? 0;
    final topics = stage['topics'] as List? ?? [];
    final tools = (stage['tools'] as List?)?.cast<String>() ?? [];
    final projects = stage['projects'] as List? ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isExpanded ? color.withAlpha(153) : cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? color.withAlpha(20)
                    : cs.surfaceContainerLowest,
              ),
              child: Row(
                children: [
                  // Stage number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$durationDays days',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expanded body
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Topics
                  if (topics.isNotEmpty) ...[
                    _SectionLabel(label: '📖 Topics', color: color),
                    const SizedBox(height: 8),
                    ...topics.map<Widget>((t) {
                      final topic = t as Map<String, dynamic>;
                      final name = topic['name'] as String? ?? '';
                      final subs = (topic['subtopics'] as List?)
                              ?.cast<String>() ??
                          [];
                      return _TopicRow(
                          name: name, subtopics: subs, color: color);
                    }),
                    const SizedBox(height: 10),
                  ],

                  // Tools
                  if (tools.isNotEmpty) ...[
                    _SectionLabel(label: '🛠️ Tools', color: color),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: tools
                          .map((t) => _Chip(label: t, color: color))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Projects
                  if (projects.isNotEmpty) ...[
                    _SectionLabel(label: '🚀 Projects', color: color),
                    const SizedBox(height: 8),
                    ...projects.map<Widget>((p) {
                      final proj = p as Map<String, dynamic>;
                      return _ProjectTile(
                        title: proj['title'] as String? ?? '',
                        description: proj['description'] as String? ?? '',
                        color: color,
                      );
                    }),
                  ],

                  // ─── Start Stage Button ──────────────────────────────
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onStartStage,
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Start Stage'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String name;
  final List<String> subtopics;
  final Color color;
  const _TopicRow(
      {required this.name, required this.subtopics, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (subtopics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: subtopics
                    .map((s) => _Chip(label: s, color: color, small: true))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Chip({required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  const _ProjectTile(
      {required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.rocket_launch_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
