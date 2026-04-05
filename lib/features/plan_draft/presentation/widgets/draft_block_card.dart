import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../models/draft_models.dart';

/// Compact card for a single [DraftBlock] in the draft list.
/// Displays: time range | type icon | title & subject chip | drag handle.
class DraftBlockCard extends StatelessWidget {
  final DraftBlock block;
  final Key itemKey;
  /// Index within the ReorderableListView — required for drag handle.
  final int index;

  // Colors per block type (from SKILL.md §9.2)
  static const _typeColors = {
    'study': AppColors.primary,
    'break': AppColors.onSurfaceVariant,
    'practice': AppColors.practiceOrange,
    'review': AppColors.revisionBlue,
  };

  static const _typeIcons = {
    'study': Icons.menu_book_rounded,
    'break': Icons.coffee_rounded,
    'practice': Icons.bolt_rounded,
    'review': Icons.repeat_rounded,
  };

  const DraftBlockCard({
    required this.block,
    required this.itemKey,
    required this.index,
  }) : super(key: itemKey);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _typeColors[block.type] ?? AppColors.primary;
    final icon = _typeIcons[block.type] ?? Icons.menu_book_rounded;
    final isBreak = block.type == 'break';

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
      color: isBreak ? AppColors.surfaceVariant : cs.surface,
      elevation: isBreak ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCompactCard),
        side: isBreak
            ? BorderSide.none
            : BorderSide(color: AppColors.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3, vertical: AppSpacing.space3),
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.startTime,
                      style: tt.labelMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(block.endTime,
                      style: tt.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppColors.onSurfaceVariant,
                      )),
                ],
              ),
            ),

            // Vertical accent line
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Type icon
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.space2),

            // Title & subject
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                  if (block.subject != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(block.subject!,
                          style: tt.labelSmall?.copyWith(color: AppColors.primary)),
                    ),
                ],
              ),
            ),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('${block.durationMinutes}m',
                  style: tt.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ),
            const SizedBox(width: AppSpacing.space2),

            // Drag handle (ReorderableListView needs this)
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  size: 20, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
