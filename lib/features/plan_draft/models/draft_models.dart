import 'package:equatable/equatable.dart';

class DraftBlock extends Equatable {
  final String title;
  final String? subject;
  final String type;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int? priority;

  const DraftBlock({
    required this.title,
    this.subject,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.priority,
  });

  DraftBlock copyWith({
    String? title,
    String? subject,
    String? type,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    int? priority,
  }) {
    return DraftBlock(
      title: title ?? this.title,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
    );
  }

  factory DraftBlock.fromJson(Map<String, dynamic> json) {
    return DraftBlock(
      title: json['title'],
      subject: json['subject'],
      type: json['type'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'type': type,
        'start_time': startTime,
        'end_time': endTime,
        'duration_minutes': durationMinutes,
        'priority': priority,
      };

  @override
  List<Object?> get props => [
        title,
        subject,
        type,
        startTime,
        endTime,
        durationMinutes,
        priority,
      ];
}

class PlanDraftResponse extends Equatable {
  final String planSummary;
  final List<String> warnings;
  final List<DraftBlock> blocks;

  const PlanDraftResponse({
    required this.planSummary,
    this.warnings = const [],
    required this.blocks,
  });

  factory PlanDraftResponse.fromJson(Map<String, dynamic> json) {
    return PlanDraftResponse(
      planSummary: json['plan_summary'],
      warnings: List<String>.from(json['warnings'] ?? []),
      blocks: (json['blocks'] as List).map((e) => DraftBlock.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_summary': planSummary,
        'warnings': warnings,
        'blocks': blocks.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [planSummary, warnings, blocks];
}

class PlanRequest extends Equatable {
  final List<String> subjects;
  final List<List<String>> timeSlots;
  final Map<String, int> priorities;
  final int sessionLength;
  final String date;
  final String? instruction;

  const PlanRequest({
    required this.subjects,
    required this.timeSlots,
    required this.priorities,
    this.sessionLength = 45,
    required this.date,
    this.instruction,
  });

  Map<String, dynamic> toJson() => {
        'subjects': subjects,
        'time_slots': timeSlots,
        'priorities': priorities,
        'session_length': sessionLength,
        'date': date,
        'instruction': instruction,
      };

  @override
  List<Object?> get props => [subjects, timeSlots, priorities, sessionLength, date, instruction];
}
