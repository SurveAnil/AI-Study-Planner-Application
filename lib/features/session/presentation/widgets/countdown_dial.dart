import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CountdownDial extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isComplete;

  const CountdownDial({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isComplete = false,
  });

  String get formattedTime {
    final minutes = (remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero and cap progress between 0 and 1
    final progress = totalSeconds > 0 
        ? max(0.0, min(1.0, 1.0 - (remainingSeconds / totalSeconds))) 
        : 0.0;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Track
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 16,
              color: Theme.of(context).colorScheme.surfaceContainerHighest, // Replaced surfaceVariant
            ),
          ),

          // Foreground Progress
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: isComplete ? 1.0 : progress,
              strokeWidth: 16,
              color: isComplete ? const Color(0xFF10B981) : AppColors.primary, // Green if done
              strokeCap: StrokeCap.round,
            ),
          ),

          // Timer Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isComplete ? '00:00' : formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [
                        // Enable tabular lining for monospace numbers
                        FontFeature.tabularFigures()
                      ]
                    ),
              ),
              if (isComplete)
                Text(
                  'Session Complete!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
