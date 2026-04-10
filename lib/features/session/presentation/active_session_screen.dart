import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../bloc/session_bloc.dart';

class ActiveSessionScreen extends StatefulWidget {
  final String? taskId;
  final String taskTitle;
  final int plannedDurationMinutes;
  final String? skill;
  final int? day;
  final bool isResume;

  const ActiveSessionScreen({
    super.key,
    this.taskId,
    required this.taskTitle,
    required this.plannedDurationMinutes,
    this.skill,
    this.day,
    this.isResume = false,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.isResume) {
      context.read<SessionBloc>().add(
            ResumeSessionEvent(
              widget.taskId ?? 'quick-focus',
              widget.plannedDurationMinutes * 60,
              skill: widget.skill,
              day: widget.day,
            ),
          );
    } else {
      context.read<SessionBloc>().add(
            StartSessionEvent(
              widget.taskId ?? 'quick-focus',
              widget.plannedDurationMinutes * 60,
              skill: widget.skill,
              day: widget.day,
            ),
          );
    }
    
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = context.read<SessionBloc>().state;
      int currentElapsed = 0;
      if (state is SessionRunning) {
        currentElapsed = state.elapsedSeconds;
      } else if (state is SessionPaused) {
        currentElapsed = state.elapsedSeconds;
      } else if (state is SessionOvertime) {
        currentElapsed = state.session.plannedDuration + state.overtimeSeconds;
      }

      if (state is SessionRunning || state is SessionOvertime) {
        context.read<SessionBloc>().add(TickEvent(currentElapsed + 1));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _handleManualEnd() async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Your focus progress will be saved. Are you sure you want to wrap up early?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<SessionBloc>().add(const EndSessionEvent(isManual: true));
      Navigator.pop(context); // Directly back to Schedule
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: cs.error));
        }
      },
      builder: (context, state) {
        if (state is SessionComplete) {
          return _OutcomeScreen(session: state.session);
        }

        bool isRunning = state is SessionRunning;
        bool isPaused = state is SessionPaused;
        bool isOvertime = state is SessionOvertime;
        
        int elapsed = 0;
        int overtimeSec = 0;
        int pauses = 0;
        
        if (state is SessionRunning) {
          elapsed = state.elapsedSeconds;
          pauses = state.pauseCount;
        } else if (state is SessionPaused) {
          elapsed = state.elapsedSeconds;
          pauses = state.pauseCount;
        } else if (state is SessionOvertime) {
          elapsed = state.session.plannedDuration;
          overtimeSec = state.overtimeSeconds;
          pauses = state.pauseCount;
        }

        final int totalPlannedSec = widget.plannedDurationMinutes * 60;
        final progress = (elapsed / totalPlannedSec).clamp(0.0, 1.0);
        final remainingSec = math.max(0, totalPlannedSec - elapsed);
        
        // --- Label Logic ---
        String statusLabel = "Deep Focus Mode";
        Color statusColor = cs.primary;
        if (isPaused) {
          statusLabel = "Paused — Stay Sharp";
          statusColor = AppColors.warning;
        } else if (isOvertime) {
          statusLabel = "Overtime — Keep Going 🚀";
          statusColor = Colors.green;
        } else if (progress > 0.75) {
          statusLabel = "Final Sprint 🔥";
          statusColor = cs.error;
        }

        // --- Ring Logic ---
        Color ringColor = cs.primary;
        if (isPaused) ringColor = AppColors.warning;
        else if (isOvertime) ringColor = Colors.green;
        else if (progress > 0.75) ringColor = cs.error;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _handleManualEnd,
            ),
            title: const Text('Focus Engine'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Column(
              children: [
                Text(
                  widget.taskTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // --- The Ring (Countdown Anti-Clockwise) ---
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: (progress > 0.75 && isRunning)
                            ? [
                                BoxShadow(
                                  color: cs.error.withAlpha((_pulseController.value * 40).toInt()),
                                  blurRadius: 20 + (_pulseController.value * 20),
                                  spreadRadius: 5 + (_pulseController.value * 5),
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(250, 250),
                            painter: _CountdownPainter(
                              progress: isOvertime ? 1.0 : (1.0 - progress),
                              color: ringColor,
                              backgroundColor: cs.surfaceContainerHighest.withAlpha(100),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(isOvertime ? overtimeSec : remainingSec),
                                style: GoogleFonts.dmMono(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                isOvertime ? "Extra Time" : "Remaining",
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),

                // --- Micro Stats ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: "Pauses", value: "$pauses", icon: Icons.pause_circle_outline),
                    _StatItem(
                        label: "Efficiency",
                        value: "${(( ( (elapsed + overtimeSec) / totalPlannedSec ) * (1.0 - (pauses * 0.1)) ) * 100).toInt()}%",
                        icon: Icons.bolt),
                    _StatItem(
                        label: "Goal",
                        value: "${widget.plannedDurationMinutes}m",
                        icon: Icons.flag_outlined),
                  ],
                ),
                const Spacer(),

                // --- Controls ---
                if (isOvertime)
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton.icon(
                      onPressed: () => context.read<SessionBloc>().add(const EndSessionEvent()),
                      icon: const Icon(Icons.check_circle_rounded, size: 28),
                      label: const Text("Complete Session", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            onPressed: _handleManualEnd,
                            icon: const Icon(Icons.stop_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: cs.surfaceContainerHighest,
                              foregroundColor: cs.error,
                              fixedSize: const Size(56, 56),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("End early", style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 48),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: FloatingActionButton(
                          heroTag: "play_pause_fab",
                          onPressed: () {
                            if (isRunning) {
                              context.read<SessionBloc>().add(const PauseSessionEvent());
                            } else if (isPaused) {
                              context.read<SessionBloc>().add(const ResumeStartedSessionEvent());
                            }
                          },
                          backgroundColor: isPaused ? cs.primary : AppColors.warning,
                          elevation: 6,
                          shape: const CircleBorder(),
                          child: Icon(
                            isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CountdownPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;
    double sweepAngle = -2 * math.pi * progress; // Negative for anti-clockwise

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) => true;
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}

class _OutcomeScreen extends StatefulWidget {
  final dynamic session;
  const _OutcomeScreen({required this.session});

  @override
  State<_OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<_OutcomeScreen> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = (widget.session.focusScore * 100).toInt();

    return Scaffold(
      backgroundColor: cs.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "Great Focus!",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                "Returning to schedule in $_countdown...",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(label: "Focus Score", value: "$score", color: score > 75 ? Colors.green : Colors.orange),
                        _StatBox(label: "Duration", value: "${widget.session.actualDuration ~/ 60}m", color: cs.primary),
                      ],
                    ),
                    const Divider(height: 48),
                    Text(
                      "Section progress has been synchronized.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cs.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Go to Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Take a Break"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
