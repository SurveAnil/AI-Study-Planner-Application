import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../bloc/progress_cubit.dart';
import 'widgets/progress_statistics_card.dart';
import 'widgets/study_heatmap.dart';

class ProgressScreen extends StatefulWidget {
  final String skill;

  const ProgressScreen({super.key, required this.skill});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProgressCubit>().loadSkillReport(widget.skill);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Intelligence Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return _buildError(state.errorMessage!, cs);
          }

          final report = state.report;
          if (report == null) {
            return const Center(child: Text("No analytics data yet. Keep studying!"));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProgressCubit>().loadSkillReport(widget.skill),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                // 1. Snapshot Statistics
                ProgressStatisticsCard(
                  consistencyIndex: report.consistencyIndex,
                  streak: report.currentStreak,
                  efficiency: report.weightedFocusEfficiency,
                ),
                
                const SizedBox(height: 24),

                // 2. Heatmap
                StudyHeatmap(snapshots: report.snapshots),

                const SizedBox(height: 24),

                // 3. Focus Distribution (Mock Radar Card for now)
                _buildRadarPlaceholder(report.totalDomainTimeDistribution, cs),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String message, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<ProgressCubit>().loadSkillReport(widget.skill),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarPlaceholder(Map<String, int> distribution, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              const Text("Focus Radar", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (distribution.isEmpty)
             const Center(child: Text("Not enough data to map domains.")),
          ...distribution.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(e.key, style: const TextStyle(fontSize: 12)),
                     Text("${e.value} mins", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                   ],
                 ),
                 const SizedBox(height: 6),
                 LinearProgressIndicator(
                   value: (e.value / 300).clamp(0.0, 1.0),
                   backgroundColor: cs.outlineVariant.withAlpha(50),
                   borderRadius: BorderRadius.circular(4),
                 ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
