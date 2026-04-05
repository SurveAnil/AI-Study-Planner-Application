import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';

/// User settings/preferences model.
class UserSettings {
  final int dailyGoalHours;
  final int sessionLengthMinutes;   // 30 | 45 | 60
  final int breakDurationMinutes;   // 5 | 10 | 15
  final String studyWindowStart;    // HH:MM
  final String studyWindowEnd;      // HH:MM
  final bool dailyReminderEnabled;
  final String? dailyReminderTime;
  final bool revisionAlertsEnabled;
  final bool weeklyReportEnabled;
  final bool nlpInputEnabled;
  final bool performancePredictionEnabled;
  final bool weakSubjectDetectionEnabled;
  final bool darkModeEnabled;

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
  }) {
    return UserSettings(
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      sessionLengthMinutes: sessionLengthMinutes ?? this.sessionLengthMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      studyWindowStart: studyWindowStart ?? this.studyWindowStart,
      studyWindowEnd: studyWindowEnd ?? this.studyWindowEnd,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      revisionAlertsEnabled: revisionAlertsEnabled ?? this.revisionAlertsEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      nlpInputEnabled: nlpInputEnabled ?? this.nlpInputEnabled,
      performancePredictionEnabled: performancePredictionEnabled ?? this.performancePredictionEnabled,
      weakSubjectDetectionEnabled: weakSubjectDetectionEnabled ?? this.weakSubjectDetectionEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }
}

/// Abstract settings repository.
abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> loadSettings();
  Future<Either<Failure, Unit>> updateSettings(UserSettings settings);
}
