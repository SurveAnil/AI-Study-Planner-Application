import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/roadmap_local_service.dart';
import 'roadmap_screen.dart';

/// Displays a chronological list of all previously generated roadmaps.
///
/// Each entry shows the skill name and creation date.  Tapping an entry
/// navigates to [RoadmapScreen] with the full decoded roadmap data.
class RoadmapHistoryScreen extends StatefulWidget {
  const RoadmapHistoryScreen({super.key});

  @override
  State<RoadmapHistoryScreen> createState() => _RoadmapHistoryScreenState();
}

class _RoadmapHistoryScreenState extends State<RoadmapHistoryScreen> {
  List<Map<String, dynamic>> _roadmaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await RoadmapLocalService.instance.getAllRoadmaps();
    if (mounted) {
      setState(() {
        _roadmaps = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Roadmap History'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _roadmaps.isEmpty
              ? _buildEmpty(cs)
              : _buildList(cs),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined,
                size: 72, color: cs.primary.withAlpha(89)),
            const SizedBox(height: 20),
            Text(
              'No Roadmaps Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate your first roadmap to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────

  Widget _buildList(ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _roadmaps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final row = _roadmaps[index];
          return _HistoryCard(
            row: row,
            isLatest: index == 0,
            onTap: () => _openRoadmap(row),
          );
        },
      ),
    );
  }

  void _openRoadmap(Map<String, dynamic> row) async {
    final skill = row['skill'] as String? ?? 'Unknown';
    Map<String, dynamic> decoded;
    try {
      decoded =
          json.decode(row['roadmap_json'] as String) as Map<String, dynamic>;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not decode roadmap data.')),
      );
      return;
    }

    // Set this as the active skill
    await RoadmapLocalService.instance.setActiveSkill(skill);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoadmapScreen(skill: skill, roadmap: decoded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isLatest;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.row,
    required this.isLatest,
    required this.onTap,
  });

  static const List<Color> _cardColors = [
    Color(0xFF6C63FF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final skill = row['skill'] as String? ?? 'Unknown';
    final createdAt = row['created_at'] as int? ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
    final color = _cardColors[skill.hashCode.abs() % _cardColors.length];

    return Card(
      elevation: isLatest ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLatest ? color.withAlpha(153) : cs.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Skill initial badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withAlpha(77)),
                ),
                child: Center(
                  child: Text(
                    skill.isNotEmpty ? skill[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Skill name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLatest)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LATEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
