import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../bloc/plan_draft_bloc.dart';
import '../bloc/plan_draft_event.dart';

/// S04-style form — the "Build Plan Manually" path.
/// Collects date, time slots, subjects, priorities → fires [RequestManualPlanEvent].
class ManualPlanFormScreen extends StatefulWidget {
  const ManualPlanFormScreen({super.key});

  @override
  State<ManualPlanFormScreen> createState() => _ManualPlanFormScreenState();
}

class _ManualPlanFormScreenState extends State<ManualPlanFormScreen> {
  // ── Date ────────────────────────────────────────────────────────────────
  DateTime _planDate = DateTime.now();

  // ── Time Slots ──────────────────────────────────────────────────────────
  /// Each entry is a (startTime, endTime) pair; starts with one blank row.
  final List<_TimeSlotRow> _timeSlots = [_TimeSlotRow()];

  // ── Subjects ────────────────────────────────────────────────────────────
  static const List<String> _presetSubjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Computer Science',
  ];
  final List<String> _allSubjects = List.from(_presetSubjects);
  final Set<String> _selectedSubjects = {};

  // ── Priorities ─────────────────────────────────────────────────────────
  final Map<String, int> _priorities = {}; // subject → 1(High)/2(Med)/3(Low)

  // ── Session Length ─────────────────────────────────────────────────────
  int _sessionLength = 45;

  // ── Helpers ─────────────────────────────────────────────────────────────
  bool get _canGenerate => _selectedSubjects.isNotEmpty;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _planDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _planDate = picked);
  }

  Future<void> _pickTime({required int slotIndex, required bool isStart}) async {
    final slot = _timeSlots[slotIndex];
    final initial = isStart
        ? (slot.start ?? TimeOfDay.now())
        : (slot.end ?? TimeOfDay.now());
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _timeSlots[slotIndex].start = picked;
        } else {
          _timeSlots[slotIndex].end = picked;
        }
      });
    }
  }

  void _addSubjectDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusDialog)),
        ),
        title: const Text('Add Subject'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Economics'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty && !_allSubjects.contains(name)) {
                setState(() => _allSubjects.add(name));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
        _priorities.remove(subject);
      } else {
        _selectedSubjects.add(subject);
        _priorities[subject] = 2; // default Medium
      }
    });
  }

  void _onGenerate() {
    // Build time-slot list (skip incomplete rows)
    final slots = _timeSlots
        .where((s) => s.start != null && s.end != null)
        .map((s) => [_fmt(s.start!), _fmt(s.end!)])
        .toList();

    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set at least one time slot.')),
      );
      return;
    }

    context.read<PlanDraftBloc>().add(RequestManualPlanEvent(
          date: '${_planDate.year}-${_planDate.month.toString().padLeft(2, '0')}-${_planDate.day.toString().padLeft(2, '0')}',
          subjects: _selectedSubjects.toList(),
          timeSlots: slots,
          priorities: Map<String, int>.from(_priorities),
          sessionLength: _sessionLength,
        ));

    Navigator.of(context).pop(); // Return to PlanDraftScreen (which shows PlanDraft state)
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Build Plan Manually'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space4),
            child: FilledButton.icon(
              onPressed: _canGenerate ? _onGenerate : null,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Generate Plan'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
          // ── Date ──────────────────────────────────────────────────────
          _SectionLabel('Plan Date'),
          const SizedBox(height: AppSpacing.space2),
          _TappableField(
            icon: Icons.calendar_today,
            label:
                '${_planDate.year}-${_planDate.month.toString().padLeft(2, '0')}-${_planDate.day.toString().padLeft(2, '0')}',
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.space6),

          // ── Time Slots ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel('Time Slots'),
              TextButton.icon(
                onPressed: () => setState(() => _timeSlots.add(_TimeSlotRow())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add slot'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ..._timeSlots.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: Row(
                children: [
                  Expanded(
                    child: _TappableField(
                      icon: Icons.access_time,
                      label: slot.start != null ? _fmt(slot.start!) : 'From',
                      onTap: () => _pickTime(slotIndex: i, isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: _TappableField(
                      icon: Icons.access_time_filled,
                      label: slot.end != null ? _fmt(slot.end!) : 'To',
                      onTap: () => _pickTime(slotIndex: i, isStart: false),
                    ),
                  ),
                  if (_timeSlots.length > 1)
                    IconButton(
                      icon: Icon(Icons.close, color: cs.error),
                      onPressed: () => setState(() => _timeSlots.removeAt(i)),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.space6),

          // ── Session Length ────────────────────────────────────────────
          _SectionLabel('Session Length'),
          const SizedBox(height: AppSpacing.space2),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 30, label: Text('30 min')),
              ButtonSegment(value: 45, label: Text('45 min')),
              ButtonSegment(value: 60, label: Text('60 min')),
            ],
            selected: {_sessionLength},
            onSelectionChanged: (s) => setState(() => _sessionLength = s.first),
          ),
          const SizedBox(height: AppSpacing.space6),

          // ── Subjects ──────────────────────────────────────────────────
          _SectionLabel('Subjects'),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              ..._allSubjects.map((s) => FilterChip(
                    label: Text(s),
                    selected: _selectedSubjects.contains(s),
                    onSelected: (_) => _toggleSubject(s),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.primary,
                    side: _selectedSubjects.contains(s)
                        ? BorderSide(color: cs.primary, width: 1.5)
                        : null,
                  )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Custom'),
                onPressed: _addSubjectDialog,
              ),
            ],
          ),

          // ── Per-subject priority ──────────────────────────────────────
          if (_selectedSubjects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            _SectionLabel('Priority per Subject'),
            const SizedBox(height: AppSpacing.space2),
            ..._selectedSubjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(subject, style: tt.titleSmall),
                      ),
                      DropdownButton<int>(
                        value: _priorities[subject] ?? 2,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('🔴 High')),
                          DropdownMenuItem(value: 2, child: Text('🟡 Medium')),
                          DropdownMenuItem(value: 3, child: Text('🟢 Low')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _priorities[subject] = v);
                        },
                      ),
                    ],
                  ),
                )),
          ],

          // ── Guard hint ────────────────────────────────────────────────
          if (!_canGenerate)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space4),
              child: Text(
                'Select at least one subject to generate a plan.',
                style: tt.bodySmall?.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: AppSpacing.space16),
        ],
        ),
      ),
    );
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _TimeSlotRow {
  TimeOfDay? start;
  TimeOfDay? end;
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

class _TappableField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TappableField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.space2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
