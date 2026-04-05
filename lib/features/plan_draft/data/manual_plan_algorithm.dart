import '../models/draft_models.dart';
import '../../../core/error/failures.dart';

/// Pure-Dart local planning algorithm.
/// Implements SKILL.md §2.1 rules — no I/O, no Flutter dependencies.
class ManualPlanAlgorithm {
  final List<String> subjects;
  final List<List<String>> timeSlots; // [[HH:MM, HH:MM], ...]
  final Map<String, int> priorities;  // subject → 1(High)/2(Med)/3(Low)
  final int sessionLength;            // minutes: 30 | 45 | 60
  final String date;                  // YYYY-MM-DD

  ManualPlanAlgorithm({
    required this.subjects,
    required this.timeSlots,
    required this.priorities,
    required this.sessionLength,
    required this.date,
  });

  /// Returns list of [DraftBlock] or throws [InsufficientTimeFailure] / [NoSubjectsFailure].
  List<DraftBlock> generate() {
    if (subjects.isEmpty) {
      throw const NoSubjectsFailure('No subjects provided.');
    }

    final sortedSubjects = _sortedByPriority();
    final blocks = <DraftBlock>[];

    for (final slot in timeSlots) {
      final segBlocks = _blocksForSlot(slot, sortedSubjects);
      blocks.addAll(segBlocks);
    }

    if (blocks.isEmpty) {
      throw InsufficientTimeFailure(
        'Total available time is under 15 minutes.',
        availableMinutes: 0,
      );
    }
    return blocks;
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  List<String> _sortedByPriority() {
    if (subjects.length == 1) return List.from(subjects); // skip weighting
    final sorted = List<String>.from(subjects);
    sorted.sort((a, b) => (priorities[a] ?? 2).compareTo(priorities[b] ?? 2));
    return sorted;
  }

  List<DraftBlock> _blocksForSlot(List<String> slot, List<String> sortedSubjects) {
    final start = _toMinutes(slot[0]);
    var end = _toMinutes(slot[1]);

    // Midnight-crossing guard (SKILL §2.1 rule 5)
    if (end <= start) end += 24 * 60;

    final available = end - start;
    if (available < 15) {
      throw InsufficientTimeFailure(
        'Time slot has under 15 minutes available ($available min).',
        availableMinutes: available,
      );
    }

    // Quick Review mode: available < sessionLength but >= 15
    final blockSize = (available < sessionLength) ? 15 : sessionLength;
    const breakSize = 15;

    final blocks = <DraftBlock>[];
    var cursor = start;
    int subjectIndex = 0;
    bool justHadBreak = false;

    while (cursor + blockSize <= end) {
      final subject = sortedSubjects[subjectIndex % sortedSubjects.length];
      final isQuickReview = blockSize < sessionLength;

      blocks.add(DraftBlock(
        title: isQuickReview ? 'Quick Review — $subject' : 'Study — $subject',
        subject: subject,
        type: 'study',
        startTime: _toHHMM(cursor),
        endTime: _toHHMM(cursor + blockSize),
        durationMinutes: blockSize,
        priority: priorities[subject] ?? 2,
      ));

      cursor += blockSize;
      subjectIndex++;
      justHadBreak = false;

      // Insert break if there's room and we haven't just had one
      if (!justHadBreak && cursor + breakSize <= end) {
        blocks.add(DraftBlock(
          title: 'Break',
          type: 'break',
          startTime: _toHHMM(cursor),
          endTime: _toHHMM(cursor + breakSize),
          durationMinutes: breakSize,
        ));
        cursor += breakSize;
        justHadBreak = true;
      }
    }

    return blocks;
  }

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _toHHMM(int minutes) {
    // Handle values that may exceed 24h (midnight crossing)
    final normalized = minutes % (24 * 60);
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
