import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// Resource item — PDF, video, PPT, or link attached to study tasks.
class Resource {
  final String id;
  final String title;
  final String type;        // pdf | video | ppt | link | practice_set
  final String? filePath;
  final String? url;
  final String? subject;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const Resource({
    required this.id,
    required this.title,
    required this.type,
    this.filePath,
    this.url,
    this.subject,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
    this.isDeleted = false,
  });
}

/// Abstract resources repository.
abstract class ResourcesRepository {
  Future<Either<Failure, List<Resource>>> loadAll();
  Future<Either<Failure, List<Resource>>> filterByType(String type);
  Future<Either<Failure, Unit>> addResource(Resource resource);
  Future<Either<Failure, Unit>> deleteResource(String resourceId);
}
