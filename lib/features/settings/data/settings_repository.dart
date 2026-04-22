import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/failures.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

/// User settings/preferences model.
class UserSettings {
  final int dailyGoalHours;
  final int sessionLengthMinutes; // 30 | 45 | 60
  final int breakDurationMinutes; // 5 | 10 | 15
  final String studyWindowStart; // HH:MM
  final String studyWindowEnd; // HH:MM
  final bool dailyReminderEnabled;
  final String? dailyReminderTime;
  final bool revisionAlertsEnabled;
  final bool weeklyReportEnabled;
  final bool nlpInputEnabled;
  final bool performancePredictionEnabled;
  final bool weakSubjectDetectionEnabled;
  final bool darkModeEnabled;
  final String aiModel;
  final bool useCustomApi;
  final String? openRouterApiKey;

  const UserSettings({
    this.dailyGoalHours = 3,
    this.sessionLengthMinutes = 45,
    this.breakDurationMinutes = 10,
    this.studyWindowStart = '09:00',
    this.studyWindowEnd = '21:00',
    this.dailyReminderEnabled = true,
    this.dailyReminderTime,
    this.revisionAlertsEnabled = true,
    this.weeklyReportEnabled = true,
    this.nlpInputEnabled = true,
    this.performancePredictionEnabled = true,
    this.weakSubjectDetectionEnabled = true,
    this.darkModeEnabled = false,
    this.aiModel = 'Default (Backend)',
    this.useCustomApi = false,
    this.openRouterApiKey,
  });

  UserSettings copyWith({
    int? dailyGoalHours,
    int? sessionLengthMinutes,
    int? breakDurationMinutes,
    String? studyWindowStart,
    String? studyWindowEnd,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    bool? revisionAlertsEnabled,
    bool? weeklyReportEnabled,
    bool? nlpInputEnabled,
    bool? performancePredictionEnabled,
    bool? weakSubjectDetectionEnabled,
    bool? darkModeEnabled,
    String? aiModel,
    bool? useCustomApi,
    String? openRouterApiKey,
  }) {
    return UserSettings(
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      sessionLengthMinutes: sessionLengthMinutes ?? this.sessionLengthMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      studyWindowStart: studyWindowStart ?? this.studyWindowStart,
      studyWindowEnd: studyWindowEnd ?? this.studyWindowEnd,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      revisionAlertsEnabled:
          revisionAlertsEnabled ?? this.revisionAlertsEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      nlpInputEnabled: nlpInputEnabled ?? this.nlpInputEnabled,
      performancePredictionEnabled:
          performancePredictionEnabled ?? this.performancePredictionEnabled,
      weakSubjectDetectionEnabled:
          weakSubjectDetectionEnabled ?? this.weakSubjectDetectionEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      aiModel: aiModel ?? this.aiModel,
      useCustomApi: useCustomApi ?? this.useCustomApi,
      openRouterApiKey: openRouterApiKey ?? this.openRouterApiKey,
    );
  }

  // ─── JSON serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'dailyGoalHours': dailyGoalHours,
        'sessionLengthMinutes': sessionLengthMinutes,
        'breakDurationMinutes': breakDurationMinutes,
        'studyWindowStart': studyWindowStart,
        'studyWindowEnd': studyWindowEnd,
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderTime': dailyReminderTime,
        'revisionAlertsEnabled': revisionAlertsEnabled,
        'weeklyReportEnabled': weeklyReportEnabled,
        'nlpInputEnabled': nlpInputEnabled,
        'performancePredictionEnabled': performancePredictionEnabled,
        'weakSubjectDetectionEnabled': weakSubjectDetectionEnabled,
        'darkModeEnabled': darkModeEnabled,
        'aiModel': aiModel,
        'useCustomApi': useCustomApi,
        'openRouterApiKey': openRouterApiKey,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        dailyGoalHours: json['dailyGoalHours'] as int? ?? 3,
        sessionLengthMinutes: json['sessionLengthMinutes'] as int? ?? 45,
        breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 10,
        studyWindowStart: json['studyWindowStart'] as String? ?? '09:00',
        studyWindowEnd: json['studyWindowEnd'] as String? ?? '21:00',
        dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? true,
        dailyReminderTime: json['dailyReminderTime'] as String?,
        revisionAlertsEnabled: json['revisionAlertsEnabled'] as bool? ?? true,
        weeklyReportEnabled: json['weeklyReportEnabled'] as bool? ?? true,
        nlpInputEnabled: json['nlpInputEnabled'] as bool? ?? true,
        performancePredictionEnabled:
            json['performancePredictionEnabled'] as bool? ?? true,
        weakSubjectDetectionEnabled:
            json['weakSubjectDetectionEnabled'] as bool? ?? true,
        darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
        aiModel: json['aiModel'] as String? ?? 'Default (Backend)',
        useCustomApi: json['useCustomApi'] as bool? ?? false,
        openRouterApiKey: json['openRouterApiKey'] as String?,
      );
}

// ─── Abstract contract ───────────────────────────────────────────────────────

/// Abstract settings repository.
abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> loadSettings();
  Future<Either<Failure, Unit>> updateSettings(UserSettings settings);

  /// Synchronous read — used by the DioClient interceptor at request time.
  UserSettings get currentSettings;
}

// ─── SharedPreferences-backed implementation ─────────────────────────────────

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _kSettingsKey = 'user_settings_v1';

  /// In-memory cache so the Dio interceptor never has to await.
  UserSettings _cache = const UserSettings();

  @override
  UserSettings get currentSettings => _cache;

  @override
  Future<Either<Failure, UserSettings>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSettingsKey);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        _cache = UserSettings.fromJson(decoded);
      }
      return Right(_cache);
    } catch (e) {
      return Left(CacheFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateSettings(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSettingsKey, json.encode(settings.toJson()));
      _cache = settings;
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save settings: $e'));
    }
  }
}
