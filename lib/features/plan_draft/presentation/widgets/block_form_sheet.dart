import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../models/draft_models.dart';

/// Shared bottom sheet for Add and Edit block operations.
/// Returns a [DraftBlock] via [Navigator.pop] on save, or null on cancel.
class BlockFormSheet extends StatefulWidget {
  /// If non-null, the sheet opens in Edit mode pre-filled with this block.
  final DraftBlock? existingBlock;
  final List<String> availableSubjects;

  const BlockFormSheet({
    super.key,
    this.existingBlock,
    required this.availableSubjects,
  });

  /// Show the sheet modally. Returns the resulting [DraftBlock] or null.
  static Future<DraftBlock?> show(
    BuildContext context, {
    DraftBlock? existingBlock,
    required List<String> subjects,
  }) {
    return showModalBottomSheet<DraftBlock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlockFormSheet(
        existingBlock: existingBlock,
        availableSubjects: subjects,
      ),
    );
  }

  @override
  State<BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<BlockFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;

  late String _type;
  late String? _subject;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBlock;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _type = b?.type ?? 'study';
    _subject = b?.subject ?? (widget.availableSubjects.isNotEmpty ? widget.availableSubjects.first : null);
    _startTime = b != null ? _parseTime(b.startTime) : null;
    _endTime = b != null ? _parseTime(b.endTime) : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _durationMinutes() {
    if (_startTime == null || _endTime == null) return 0;
    var start = _startTime!.hour * 60 + _startTime!.minute;
    var end = _endTime!.hour * 60 + _endTime!.minute;
    if (end <= start) end += 24 * 60; // midnight crossing
    return end - start;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set start and end times.')),
      );
      return;
    }
    final dur = _durationMinutes();
    if (dur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    Navigator.pop(
      context,
      DraftBlock(
        title: _titleCtrl.text.trim(),
        subject: _type == 'break' ? null : _subject,
        type: _type,
        startTime: _fmt(_startTime!),
        endTime: _fmt(_endTime!),
        durationMinutes: dur,
      ),
    );
  }

  late final List<String> _types = ['study', 'break', 'practice', 'review'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEdit = widget.existingBlock != null;

    return Padding(
      // Push form above keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusBottomSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space6,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: AppSpacing.bottomSheetHandleWidth,
                    height: AppSpacing.bottomSheetHandleHeight,
                    margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  isEdit ? 'Edit Block' : 'Add Block',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Block title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
                ),
                const SizedBox(height: AppSpacing.space4),

                // Type chips
                Text('Type', style: tt.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  children: _types.map((t) => ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                  )).toList(),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Subject (hidden for break type)
                if (_type != 'break' && widget.availableSubjects.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: widget.availableSubjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _subject = v),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Time pickers
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerTile(
                        label: 'Start',
                        time: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: _TimePickerTile(
                        label: 'End',
                        time: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space6),

                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: Text(isEdit ? 'Update Block' : 'Add Block'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                Text(
                  time != null ? _fmt(time!) : '--:--',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
