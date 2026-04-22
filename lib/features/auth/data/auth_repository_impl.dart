import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../../../core/database/database_helper.dart';
import '../../../core/error/failures.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, bool>> isProfileSetup() async {
    try {
      final db = await DatabaseHelper.database;
      final result = await db.query('users', limit: 1);
      return Right(result.isNotEmpty);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> loadProfile() async {
    try {
      final db = await DatabaseHelper.database;
      final result = await db.query('users', limit: 1);
      if (result.isEmpty) return const Right(null);
      return Right(_mapToUserProfile(result.first));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> setupProfile(ProfileSetupData data) async {
    try {
      final db = await DatabaseHelper.database;
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final userMap = {
        'id': id,
        'name': data.name,
        'email': data.email,
        'device_id': 'MOCK_DEVICE_ID', // In a real app, use device_info_plus
        'subjects': jsonEncode(data.subjects),
        'daily_goal_hours': data.dailyGoalHours.toDouble(),
        'study_window_start': data.studyWindowStart,
        'study_window_end': data.studyWindowEnd,
        'onboarding_complete': 1,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
        'is_deleted': 0,
      };

      await db.insert('users', userMap);
      return Right(_mapToUserProfile(userMap));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> login(String email, String password) async {
    try {
      final db = await DatabaseHelper.database;
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (result.isEmpty) {
        return const Left(AuthFailure('Invalid email or password'));
      }

      return Right(_mapToUserProfile(result.first));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> signUp(String name, String email, String password) async {
    try {
      final db = await DatabaseHelper.database;
      
      // Check if email already exists
      final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
      if (existing.isNotEmpty) {
        return const Left(AuthFailure('Email already registered'));
      }

      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final userMap = {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'device_id': 'MOCK_DEVICE_ID',
        'created_at': now,
        'updated_at': now,
        'sync_status': 'local',
        'is_deleted': 0,
        'subjects': '[]',
        'daily_goal_hours': 2.0,
        'study_window_start': '09:00',
        'study_window_end': '21:00',
        'onboarding_complete': 0,
      };

      await db.insert('users', userMap);
      return Right(_mapToUserProfile(userMap));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  UserProfile _mapToUserProfile(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      deviceId: map['device_id'] as String,
      subjects: List<String>.from(jsonDecode(map['subjects'] as String? ?? '[]')),
      dailyGoalHours: (map['daily_goal_hours'] as num? ?? 2).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'local',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
