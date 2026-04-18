import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../data/roadmap_local_service.dart';
import 'roadmap_screen.dart';
import 'roadmap_history_screen.dart';
import 'roadmap_input_screen.dart';
import '../../../../core/constants/app_spacing.dart';

/// The main entry point for the AI Roadmap feature.
/// Provides access to history, current roadmap, and generation of new ones.
class AiRoadmapMainScreen extends StatefulWidget {
  const AiRoadmapMainScreen({super.key});

  @override
  State<AiRoadmapMainScreen> createState() => _AiRoadmapMainScreenState();
}

class _AiRoadmapMainScreenState extends State<AiRoadmapMainScreen> {
  Map<String, dynamic>? _latestRoadmap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final latest = await RoadmapLocalService.instance.getLatestRoadmap();
    if (mounted) {
      setState(() {
        _latestRoadmap = latest;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('AI Roadmap'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header Section ───────────────────────────────────────────
                _buildHeader(context, cs),
                const SizedBox(height: AppSpacing.space8),

                // ─── History Button ───────────────────────────────────────────
                _buildHistoryButton(context, cs),
                const SizedBox(height: AppSpacing.space6),

                // ─── Latest Roadmap ───────────────────────────────────────────
                if (_latestRoadmap != null) ...[
                   _buildLatestCard(context, cs),
                   const SizedBox(height: AppSpacing.space8),
                ],

                // ─── Create New Section ───────────────────────────────────────
                if (_latestRoadmap == null) _buildEmptyState(context, cs),
                
                const SizedBox(height: AppSpacing.space4),
                _buildNewRoadmapButton(context, cs),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Symbols.auto_awesome_motion_rounded, 
            color: cs.primary, 
            size: 48,
            fill: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          'Personalized Growth',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          'AI-powered learning paths tailored for you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryButton(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoadmapHistoryScreen()),
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: cs.outlineVariant.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: cs.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCompactCard),
              ),
              child: Icon(Symbols.history_rounded, color: cs.secondary, size: 24),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Roadmap History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Browse your past learning journeys',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Symbols.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestCard(BuildContext context, ColorScheme cs) {
    final skill = _latestRoadmap!['skill'] ?? 'Unknown Skill';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ACTIVE ADVENTURE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RoadmapScreen(skill: skill)),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusHeroCard),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withAlpha(180),
                  cs.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusHeroCard),
              border: Border.all(color: cs.primary.withAlpha(80)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Icon(Symbols.rocket_launch_rounded, color: cs.primary, size: 28, fill: 1),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Pick up where you left off and master this skill.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer.withAlpha(200),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Row(
                  children: [
                    Text(
                      'Continue Roadmap',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Icon(Symbols.arrow_forward_rounded, color: cs.primary, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: cs.outlineVariant, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Symbols.explore_rounded, color: cs.onSurfaceVariant.withAlpha(100), size: 48),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'No Active Roadmap',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Start your journey by generating a new roadmap below.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewRoadmapButton(BuildContext context, ColorScheme cs) {
    return FilledButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoadmapInputScreen()),
      ),
      icon: const Icon(Symbols.add_circle_rounded, fill: 1),
      label: const Text('Generate New Roadmap'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space5),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shadowColor: cs.primary.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
      ),
    );
  }
}
