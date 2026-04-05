import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'local_study_plan_source.dart';

abstract class StudyPlanRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getTasksForDate(String userId, String date);
}

class StudyPlanRepositoryImpl implements StudyPlanRepository {
  final LocalStudyPlanSource localSource;

  StudyPlanRepositoryImpl({required this.localSource});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTasksForDate(String userId, String date) async {
    try {
      final data = await localSource.getTasksForDate(userId, date);
      return Right(data);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
