import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
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
    _loadReport();
  }

  @override
  void didUpdateWidget(ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skill != widget.skill) _loadReport();
  }

  void _loadReport() =>
      context.read<ProgressCubit>().loadSkillReport(widget.skill);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      // ── Custom header matching Settings screen style ────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'Intelligence',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                ),
                InkWell(
                  onTap: _loadReport,
                  borderRadius: BorderRadius.circular(100),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Symbols.refresh_rounded,
                        color: cs.onSurfaceVariant, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }

          if (state.errorMessage != null) {
            return _buildError(state.errorMessage!, cs);
          }

          final report = state.report;
          if (report == null) {
            return Center(
              child: Text(
                "No analytics data yet.\nKeep studying!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: cs.onSurfaceVariant,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () =>
                context.read<ProgressCubit>().loadSkillReport(widget.skill),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                // 1. Snapshot
                ProgressStatisticsCard(
                  consistencyIndex: report.consistencyIndex,
                  streak: report.currentStreak,
                  efficiency: report.weightedFocusEfficiency,
                ),
                const SizedBox(height: 20),

                // 2. Heatmap
                StudyHeatmap(snapshots: report.snapshots),
                const SizedBox(height: 20),

                // 3. Focus Radar
                _FocusRadarCard(
                    distribution: report.totalDomainTimeDistribution, cs: cs),
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
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadReport,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Focus Radar Card ─────────────────────────────────────────────────────────

class _FocusRadarCard extends StatelessWidget {
  final Map<String, int> distribution;
  final ColorScheme cs;

  const _FocusRadarCard({required this.distribution, required this.cs});

  @override
  Widget build(BuildContext context) {
    final maxVal = distribution.values.fold(1, (a, b) => a > b ? a : b);
    // Accent cycle: primary → secondary → tertiary
    final accents = [cs.primary, cs.secondary, cs.tertiary];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Symbols.radar_rounded,
                  size: 18, color: cs.primary, fill: 1),
              const SizedBox(width: 8),
              Text(
                'Focus Radar',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (distribution.isEmpty)
            Center(
              child: Text(
                "Not enough data to map domains.",
                style: TextStyle(
                    fontFamily: 'Inter', color: cs.onSurfaceVariant),
              ),
            )
          else
            ...distribution.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final domain = entry.value.key;
              final mins = entry.value.value;
              final color = accents[i % accents.length];
              final ratio = (mins / maxVal).clamp(0.0, 1.0);

              return _DomainCard(
                domain: domain,
                mins: mins,
                ratio: ratio,
                color: color,
                cs: cs,
              );
            }),
        ],
      ),
    );
  }
}

class _DomainCard extends StatefulWidget {
  final String domain;
  final int mins;
  final double ratio;
  final Color color;
  final ColorScheme cs;

  const _DomainCard({
    required this.domain,
    required this.mins,
    required this.ratio,
    required this.color,
    required this.cs,
  });

  @override
  State<_DomainCard> createState() => _DomainCardState();
}

class _DomainCardState extends State<_DomainCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.color.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.domain,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${widget.mins} min",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: widget.ratio,
                    minHeight: 5,
                    backgroundColor:
                        widget.cs.outlineVariant.withOpacity(0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
