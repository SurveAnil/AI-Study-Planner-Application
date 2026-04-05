import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../bloc/plan_draft_bloc.dart';
import '../../bloc/plan_draft_event.dart';
import '../manual_plan_form_screen.dart';

/// The Offline Planning Wall dictated by SKILL v2.0
/// Shown immediately when `isOnline == false` during AI Plan Request.
class OfflinePlanningWall extends StatefulWidget {
  const OfflinePlanningWall({super.key});

  @override
  State<OfflinePlanningWall> createState() => _OfflinePlanningWallState();
}

class _OfflinePlanningWallState extends State<OfflinePlanningWall> {
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Start polling every 5 seconds to auto-dismiss when reconnected
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isChecking && mounted) {
        _isChecking = true;
        context.read<PlanDraftBloc>().add(RetryConnectivityEvent());
        _isChecking = false;
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Offline Radar Animation Icon
          Icon(
            Icons.signal_wifi_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.space6),
          
          Text(
            "You're currently offline",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          
          Text(
            "AI Plan Generation needs an internet connection to build your personalized study plan.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),

          // Primary Auto-Wait Button
          FilledButton.icon(
            onPressed: () {
               // The timer handles this automatically, but allows manual pulse
               context.read<PlanDraftBloc>().add(RetryConnectivityEvent());
            },
            icon: const Icon(Icons.public_rounded),
            label: const Text("Go Online — I'll wait"),
            style: FilledButton.styleFrom(
              backgroundColor: colors.surfaceContainerHighest,
              foregroundColor: colors.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Secondary Manual Button (Always works)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PlanDraftBloc>(),
                  child: const ManualPlanFormScreen(),
                ),
              ),
            ),
            icon: const Icon(Icons.edit_document),
            label: const Text("Build Plan Manually"),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Back Button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "← Back",
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
