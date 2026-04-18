import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../models/draft_models.dart';

/// Compact card for a single [DraftBlock] in the draft list.
/// Displays: time range | type icon | title & subject chip | drag handle.
class DraftBlockCard extends StatelessWidget {
  final DraftBlock block;
  final Key itemKey;
  /// Index within the ReorderableListView — required for drag handle.
  final int index;

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
    
    // Design System: Accent usages strictly Primary or Secondary
    final color = block.type == 'break' ? cs.onSurfaceVariant : cs.primary;
    final icon = _typeIcons[block.type] ?? Icons.menu_book_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
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
                        color: cs.onSurfaceVariant,
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
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      )),
                  if (block.subject != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(block.subject!,
                          style: tt.labelSmall?.copyWith(color: cs.primary)),
                    ),
                ],
              ),
            ),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('${block.durationMinutes}m',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(width: AppSpacing.space2),

            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
