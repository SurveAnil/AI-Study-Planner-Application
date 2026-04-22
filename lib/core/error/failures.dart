import 'package:equatable/equatable.dart';

/// Base failure class. Every repository method returns `Either<Failure, T>`.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Data Failures ─────────────────────────────────────────────────────────

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class SyncConflictFailure extends Failure {
  final String localId;
  const SyncConflictFailure(super.message, {required this.localId});

  @override
  List<Object?> get props => [message, localId];
}

// ─── Algorithm Failures ────────────────────────────────────────────────────

class InsufficientTimeFailure extends Failure {
  final int availableMinutes;
  const InsufficientTimeFailure(super.message, {required this.availableMinutes});

  @override
  List<Object?> get props => [message, availableMinutes];
}

class InsufficientDataFailure extends Failure {
  final int sessionCount;
  const InsufficientDataFailure(super.message, {required this.sessionCount});

  @override
  List<Object?> get props => [message, sessionCount];
}

class NoSubjectsFailure extends Failure {
  const NoSubjectsFailure(super.message);
}

// ─── AI / LLM Failures ────────────────────────────────────────────────────

class InvalidBlockFailure extends Failure {
  final int? blockIndex;
  const InvalidBlockFailure(super.message, {this.blockIndex});

  @override
  List<Object?> get props => [message, blockIndex];
}

class LLMTimeoutFailure extends Failure {
  final int elapsedMs;
  const LLMTimeoutFailure(super.message, {required this.elapsedMs});

  @override
  List<Object?> get props => [message, elapsedMs];
}

class LLMParseFailure extends Failure {
  final String rawOutput;
  const LLMParseFailure(super.message, {required this.rawOutput});

  @override
  List<Object?> get props => [message, rawOutput];
}

class CloudAIFailure extends Failure {
  final int statusCode;
  const CloudAIFailure(super.message, {required this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}
