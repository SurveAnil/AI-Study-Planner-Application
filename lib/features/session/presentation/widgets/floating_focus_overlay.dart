import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/session_bloc.dart';
import '../active_session_screen.dart';
import '../../../../core/services/overlay_service.dart';
import '../../../../core/constants/app_colors.dart';

class FloatingFocusOverlay extends StatefulWidget {
  final String? taskId;
  final String taskTitle;
  final int plannedMinutes;
  final String? skill;
  final int? day;

  const FloatingFocusOverlay({
    super.key,
    this.taskId,
    required this.taskTitle,
    required this.plannedMinutes,
    this.skill,
    this.day,
  });

  @override
  State<FloatingFocusOverlay> createState() => _FloatingFocusOverlayState();
}

class _FloatingFocusOverlayState extends State<FloatingFocusOverlay> {
  Offset _offset = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset = Offset(
              (_offset.dx + details.delta.dx).clamp(0, size.width - 80),
              (_offset.dy + details.delta.dy).clamp(0, size.height - 80),
            );
          });
        },
        onTap: () {
          OverlayService.instance.hide();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveSessionScreen(
                taskId: widget.taskId,
                taskTitle: widget.taskTitle,
                plannedDurationMinutes: widget.plannedMinutes,
                skill: widget.skill,
                day: widget.day,
                isResume: true,
              ),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: BlocBuilder<SessionBloc, SessionState>(
            builder: (context, state) {
              int displaySeconds = 0;
              double progress = 0.0;
              bool isOvertime = false;

              if (state is SessionRunning) {
                displaySeconds = (widget.plannedMinutes * 60) - state.elapsedSeconds;
                progress = (state.elapsedSeconds / (widget.plannedMinutes * 60)).clamp(0.0, 1.0);
              } else if (state is SessionPaused) {
                displaySeconds = (widget.plannedMinutes * 60) - state.elapsedSeconds;
                progress = (state.elapsedSeconds / (widget.plannedMinutes * 60)).clamp(0.0, 1.0);
              } else if (state is SessionOvertime) {
                displaySeconds = state.overtimeSeconds;
                progress = 1.0;
                isOvertime = true;
              }

              if (displaySeconds < 0) displaySeconds = 0;

              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isOvertime ? Colors.green : (state is SessionPaused ? AppColors.warning : cs.primary),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      color: Colors.white,
                      strokeWidth: 4,
                      backgroundColor: Colors.white24,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(displaySeconds),
                          style: GoogleFonts.dmMono(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isOvertime)
                          const Icon(Icons.keyboard_double_arrow_up, size: 10, color: Colors.white70)
                        else
                          Icon(
                            state is SessionPaused ? Icons.pause : Icons.bolt,
                            size: 10,
                            color: Colors.white70,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}
