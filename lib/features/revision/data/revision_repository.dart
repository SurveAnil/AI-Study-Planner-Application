import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// Revision task — auto-created at Day+2/7/14/30 after EndSession.
class RevisionTask {
  final String id;
  final String userId;
  final String topic;
  final String subject;
  final String scheduledDate;
  final String revisionType; // revision | practice | test | final
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const RevisionTask({
    required this.id,
    required this.userId,
    required this.topic,
    required this.subject,
    required this.scheduledDate,
    required this.revisionType,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
    this.isDeleted = false,
  });

  RevisionTask copyWith({
    String? status,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return RevisionTask(
      id: id,
      userId: userId,
      topic: topic,
      subject: subject,
      scheduledDate: scheduledDate,
      revisionType: revisionType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted,
    );
  }
}

/// Abstract revision repository.
abstract class RevisionRepository {
  Future<Either<Failure, Unit>> createRevisionTasks(
    String userId,
    String topic,
    String subject,
    DateTime sessionDate,
  );
  Future<Either<Failure, List<RevisionTask>>> getRevisionTasksForMonth(
    DateTime month,
  );
  Future<Either<Failure, List<RevisionTask>>> getUpcomingRevisions({
    int days = 7,
  });
  Future<Either<Failure, Unit>> markRevisionDone(String revisionId);
}
