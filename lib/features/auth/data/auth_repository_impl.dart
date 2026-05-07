import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/error/failures.dart';
import '../../../core/sync/sync_queue_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SyncQueueService _syncQueue;
  final _uuid = const Uuid();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '355669280880-kn94v2t1oteilrt9500cqp0ek8p3chrv.apps.googleusercontent.com',
  );
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  AuthRepositoryImpl({required SyncQueueService syncQueue}) : _syncQueue = syncQueue;

  @override
  Future<Either<Failure, UserProfile>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return Left(AuthFailure('Google Sign-In cancelled'));

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebase_auth.User? user = userCredential.user;

      if (user == null) return Left(AuthFailure('Firebase Authentication failed'));

      final db = await DatabaseHelper.database;
      
      // Check if user already exists in local SQLite
      final existing = await db.query('users', where: 'email = ?', whereArgs: [user.email]);
      
      if (existing.isNotEmpty) {
        return Right(_mapToUserProfile(existing.first));
      }

      // Create new local profile if it doesn't exist
      final id = user.uid; // Use Firebase UID as local ID for social login
      final now = DateTime.now().toUtc().toIso8601String();
      
      final userMap = {
        'id': id,
        'name': user.displayName ?? 'Google User',
        'email': user.email,
        'device_id': 'GOOGLE_AUTH',
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
      await _syncQueue.enqueue('users', id, SyncOp.insert, userMap);

      return Right(_mapToUserProfile(userMap));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }


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
      
      // Enqueue for cloud sync
      await _syncQueue.enqueue('users', id, SyncOp.insert, userMap);

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

      // Enqueue for cloud sync
      await _syncQueue.enqueue('users', id, SyncOp.insert, userMap);

      return Right(_mapToUserProfile(userMap));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    
    // Clear local users table
    final db = await DatabaseHelper.database;
    await db.delete('users');
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
