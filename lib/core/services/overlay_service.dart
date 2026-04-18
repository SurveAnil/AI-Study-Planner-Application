import 'package:flutter/material.dart';
import '../../features/session/presentation/widgets/floating_focus_overlay.dart';

/// Singleton service to manage global UI overlays without context-drifting.
class OverlayService {
  OverlayService._internal();
  static final OverlayService instance = OverlayService._internal();

  OverlayEntry? _overlayEntry;

  /// Shows the floating focus bubble on the current screen.
  void showMinimizedFocus({
    required BuildContext context,
    required String taskTitle,
    required int plannedMinutes,
    String? taskId,
    String? skill,
    int? day,
  }) {
    if (_overlayEntry != null) return; // Already showing

    _overlayEntry = OverlayEntry(
      builder: (context) => FloatingFocusOverlay(
        taskId: taskId,
        taskTitle: taskTitle,
        plannedMinutes: plannedMinutes,
        skill: skill,
        day: day,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Removes the floating focus bubble.
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
