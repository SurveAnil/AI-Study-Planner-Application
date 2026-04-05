import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:material_symbols_icons/symbols.dart';

class SessionControls extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onTogglePause;
  final VoidCallback onEndSession;
  final VoidCallback onAddFiveMinutes;

  const SessionControls({
    super.key,
    required this.isPaused,
    required this.onTogglePause,
    required this.onEndSession,
    required this.onAddFiveMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Add 5 Mins
        IconButton.filled(
          onPressed: onAddFiveMinutes,
          icon: const Icon(Symbols.more_time_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface, // ElevatedCard equivalent style locally
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 24),

        // Play/Pause (Dominant)
        IconButton.filled(
          onPressed: onTogglePause,
          icon: Icon(
            isPaused ? Symbols.play_arrow_rounded : Symbols.pause_rounded, 
            size: 40,
            fill: 1,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.all(24),
          ),
        ),
        const SizedBox(width: 24),

        // End Session
        IconButton.filled(
          onPressed: onEndSession,
          icon: const Icon(Symbols.stop_circle_rounded, fill: 1),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
