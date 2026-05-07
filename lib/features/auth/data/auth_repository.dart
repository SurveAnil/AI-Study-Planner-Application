import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// User profile model.
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String deviceId;
  final List<String> subjects;
  final int dailyGoalHours;
  final bool spacedRepetitionEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool isDeleted;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    required this.deviceId,
    this.subjects = const [],
    this.dailyGoalHours = 3,
    this.spacedRepetitionEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
    this.isDeleted = false,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    List<String>? subjects,
    int? dailyGoalHours,
    bool? spacedRepetitionEnabled,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      deviceId: deviceId,
      subjects: subjects ?? this.subjects,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      spacedRepetitionEnabled: spacedRepetitionEnabled ?? this.spacedRepetitionEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted,
    );
  }
}

/// Setup data for first-time profile creation.
class ProfileSetupData {
  final String name;
  final String? email;
  final List<String> subjects;
  final int dailyGoalHours;
  final bool spacedRepetitionEnabled;
  final String studyWindowStart;
  final String studyWindowEnd;

  const ProfileSetupData({
    required this.name,
    this.email,
    required this.subjects,
    required this.dailyGoalHours,
    this.spacedRepetitionEnabled = true,
    required this.studyWindowStart,
    required this.studyWindowEnd,
  });
}

/// Abstract auth repository.
abstract class AuthRepository {
  Future<Either<Failure, UserProfile>> setupProfile(ProfileSetupData data);
  Future<Either<Failure, UserProfile?>> loadProfile();
  Future<Either<Failure, bool>> isProfileSetup();
  
  // New methods for the Login Function
  Future<Either<Failure, UserProfile>> login(String email, String password);
  Future<Either<Failure, UserProfile>> signUp(String name, String email, String password);
  Future<Either<Failure, UserProfile>> signInWithGoogle();
  Future<void> logout();
}
