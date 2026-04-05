import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'local_revision_source.dart';
import 'revision_repository.dart';

/// Concrete implementation of RevisionRepository.
/// Delegates to LocalRevisionSource for all SQLite operations.
class RevisionRepositoryImpl implements RevisionRepository {
  final LocalRevisionSource _localSource;

  RevisionRepositoryImpl({required LocalRevisionSource localSource})
      : _localSource = localSource;

  @override
  Future<Either<Failure, Unit>> createRevisionTasks(
    String userId,
    String topic,
    String subject,
    DateTime sessionDate,
  ) async {
    try {
      await _localSource.createRevisionTasks(
          userId, topic, subject, sessionDate);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Failed to create revision tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RevisionTask>>> getRevisionTasksForMonth(
    DateTime month,
  ) async {
    try {
      final tasks = await _localSource.getRevisionTasksForMonth(month);
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load revision calendar: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RevisionTask>>> getUpcomingRevisions({
    int days = 7,
  }) async {
    try {
      final tasks = await _localSource.getUpcomingRevisions(days: days);
      return Right(tasks);
    } catch (e) {
      return Left(DatabaseFailure('Failed to load upcoming revisions: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markRevisionDone(String revisionId) async {
    try {
      await _localSource.markRevisionDone(revisionId);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Failed to mark revision done: $e'));
    }
  }
}
