import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../progress/bloc/subject_analytics_cubit.dart';
import '../../../../features/ai_chat/presentation/ai_chat_screen.dart';

/// Banner displaying weak subjects based on ML K-Means clustering.
class AIBanner extends StatelessWidget {
  const AIBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectAnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        if (state.isLoading) {
          // Silent — don't show a spinner while ML backend is loading
          return const SizedBox.shrink();
        }

        if (state.errorMessage != null) {
          // Display silent failure or nothing if offline
          return const SizedBox.shrink();
        }

        final weakSubjects = state.clusters.weak;

        if (weakSubjects.isEmpty) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiChatScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: _BannerCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.smart_toy_rounded,
                    fill: 1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendation',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Focus on ${weakSubjects.first} today.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Widget child;
  const _BannerCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest, // FilledCard token
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
