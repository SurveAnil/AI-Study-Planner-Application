import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../bloc/session_bloc.dart';

class ActiveSessionScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final int plannedDurationMinutes;

  const ActiveSessionScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.plannedDurationMinutes,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Start the session immediately on screen load
    context.read<SessionBloc>().add(
          StartSessionEvent(widget.taskId, widget.plannedDurationMinutes * 60),
        );
    
    // Start local ticker which just pumps an event to BLoC every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = context.read<SessionBloc>().state;
      if (state is SessionRunning) {
        context.read<SessionBloc>().add(TickEvent(state.elapsedSeconds + 1));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionComplete) {
          _ticker?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Session completed! Focus Score: ${(state.session.focusScore! * 100).toStringAsFixed(0)}%',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop();
          }
        } else if (state is SessionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: colors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        bool isRunning = false;
        bool isPaused = false;
        int elapsed = 0;
        double progress = 0.0;
        final int totalPlannedSec = widget.plannedDurationMinutes * 60;

        if (state is SessionRunning) {
          isRunning = true;
          elapsed = state.elapsedSeconds;
        } else if (state is SessionPaused) {
          isPaused = true;
          elapsed = state.elapsedSeconds;
        }

        progress = (elapsed / totalPlannedSec).clamp(0.0, 1.0);
        final remainingSec = math.max(0, totalPlannedSec - elapsed);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _confirmExit(context), // Prevent accidental back taps
            ),
            title: const Text('Active Session'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title & Subtitle
                Text(
                  widget.taskTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  isPaused ? "Paused" : "Focusing",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPaused ? AppColors.warning : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                
                const Spacer(),

                // The Circular Timer UI
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: isPaused ? AppColors.warning : AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(remainingSec),
                          style: GoogleFonts.dmMono(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          "Remaining",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop Early Button
                    FloatingActionButton.extended(
                      heroTag: 'stop_fab',
                      onPressed: () => _confirmExit(context),
                      backgroundColor: colors.surfaceContainerHighest,
                      foregroundColor: colors.onSurface,
                      elevation: 0,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text("End Session"),
                    ),
                    
                    const SizedBox(width: AppSpacing.space6),

                    // Play/Pause Button
                    FloatingActionButton(
                      heroTag: 'play_pause_fab',
                      onPressed: () {
                        if (isRunning) {
                          context.read<SessionBloc>().add(const PauseSessionEvent());
                        } else if (isPaused) {
                          context.read<SessionBloc>().add(const ResumeSessionEvent());
                        }
                      },
                      backgroundColor: isPaused ? AppColors.primary : AppColors.warning,
                      foregroundColor: isPaused ? colors.onPrimary : colors.onPrimary, // using colorScheme
                      elevation: 4,
                      child: Icon(
                        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("End Session?"),
        content: const Text(
          "Your actual focused time will be saved, and your focus score will be calculated based on your effort.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SessionBloc>().add(const EndSessionEvent());
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Complete Now"),
          ),
        ],
      ),
    );
  }
}
