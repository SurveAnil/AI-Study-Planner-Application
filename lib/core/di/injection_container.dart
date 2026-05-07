import 'package:get_it/get_it.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/bloc/auth_cubit.dart';

import '../database/database_helper.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../sync/sync_queue_service.dart';
import '../sync/firebase_sync_service.dart';

// ─── Data Sources ─────────────────────────────────────────────────────
import '../../features/schedule/data/local_study_plan_source.dart';
import '../../features/session/data/local_session_source.dart';
import '../../features/revision/data/local_revision_source.dart';
import '../../features/progress/data/local_performance_data_source.dart';

// ─── Repositories ─────────────────────────────────────────────────────
import '../../features/schedule/data/study_plan_repository.dart';
import '../../features/session/data/session_repository.dart';
import '../../features/session/data/session_repository_impl.dart';
import '../../features/revision/data/revision_repository.dart';
import '../../features/revision/data/revision_repository_impl.dart';
import '../../features/progress/data/performance_data_repository.dart';
import '../../features/progress/data/performance_data_repository_impl.dart';
import '../../features/progress/data/prediction_repository.dart';
import '../../features/progress/data/prediction_repository_impl.dart';
import '../../features/progress/data/subject_analytics_repository.dart';
import '../../features/progress/data/subject_analytics_repository_impl.dart';
import '../../features/plan_draft/data/plan_draft_repository.dart';
import '../../features/plan_draft/data/commit_service.dart';
import '../../features/ai_chat/data/repositories/ai_chat_repository.dart';
import '../../features/settings/data/settings_repository.dart';

import '../../features/plan_draft/bloc/plan_draft_bloc.dart';
import '../../features/schedule/bloc/schedule_cubit.dart';
import '../../features/session/bloc/session_bloc.dart';
import '../../features/revision/bloc/revision_calendar_cubit.dart';
import '../../features/progress/bloc/prediction_cubit.dart';
import '../../features/progress/bloc/subject_analytics_cubit.dart';
import '../../features/progress/data/progress_repository.dart';
import '../../features/progress/data/progress_repository_impl.dart';
import '../../features/progress/data/analytics_aggregator.dart';
import '../../features/progress/bloc/progress_cubit.dart';
import '../../features/ai_chat/bloc/ai_chat_cubit.dart';
import '../../features/settings/bloc/settings_cubit.dart';

final sl = GetIt.instance;

/// Initialize all dependency registrations.
/// Called once from main() before runApp().
Future<void> init() async {
  // ─── Core ───────────────────────────────────────────────────────────

  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // SettingsRepository must be registered before DioClient so the
  // API-key interceptor can resolve it at construction time.
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(settingsRepository: sl<SettingsRepository>()),
  );
  
  sl.registerLazySingleton<FirebaseSyncService>(() => FirebaseSyncService());

  sl.registerLazySingleton<SyncQueueService>(
    () => SyncQueueService(
      networkInfo: sl<NetworkInfo>(),
      remoteSync: sl<FirebaseSyncService>(),
    ),
  );

  // ─── Data Sources ─────────────────────────────────────────────────

  sl.registerLazySingleton<LocalStudyPlanSource>(
    () => LocalStudyPlanSource(),
  );
  sl.registerLazySingleton<LocalSessionSource>(
    () => LocalSessionSource(syncQueue: sl<SyncQueueService>()),
  );
  sl.registerLazySingleton<LocalRevisionSource>(
    () => LocalRevisionSource(syncQueue: sl<SyncQueueService>()),
  );
  sl.registerLazySingleton<LocalPerformanceDataSource>(
    () => LocalPerformanceDataSource(syncQueue: sl<SyncQueueService>()),
  );

  // ─── Repositories ─────────────────────────────────────────────────

  sl.registerLazySingleton<StudyPlanRepository>(
    () => StudyPlanRepositoryImpl(
      localSource: sl<LocalStudyPlanSource>(),
    ),
  );

  sl.registerLazySingleton<RevisionRepository>(
    () => RevisionRepositoryImpl(
      localSource: sl<LocalRevisionSource>(),
    ),
  );

  sl.registerLazySingleton<PerformanceDataRepository>(
    () => PerformanceDataRepositoryImpl(
      localSource: sl<LocalPerformanceDataSource>(),
    ),
  );

  // SessionRepository needs userId param
  sl.registerFactoryParam<SessionRepository, String, void>(
    (userId, _) => SessionRepositoryImpl(
      sessionSource: sl<LocalSessionSource>(),
      planSource: sl<LocalStudyPlanSource>(),
      revisionSource: sl<LocalRevisionSource>(),
      userId: userId,
    ),
  );

  // PredictionRepository
  sl.registerFactoryParam<PredictionRepository, String, void>(
    (userId, _) => PredictionRepositoryImpl(
      dioClient: sl<DioClient>(),
      sessionRepository: sl<SessionRepository>(param1: userId),
    ),
  );

  sl.registerLazySingleton<SubjectAnalyticsRepository>(
    () => SubjectAnalyticsRepositoryImpl(
      dioClient: sl<DioClient>(),
    ),
  );

  sl.registerLazySingleton<AnalyticsAggregator>(
    () => AnalyticsAggregator(),
  );

  sl.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(aggregator: sl<AnalyticsAggregator>()),
  );

  sl.registerLazySingleton<AiChatRepository>(
    () => AiChatRepository(sl<DioClient>()),
  );

  // AuthRepository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(syncQueue: sl<SyncQueueService>()),
  );

  // SettingsRepository is already registered above (before DioClient).

  // ─── BLoCs / Cubits — factories (new instance per route) ─────────

  // RevisionCalendarCubit needs userId param
  sl.registerFactoryParam<RevisionCalendarCubit, String, void>(
    (userId, _) => RevisionCalendarCubit(
      repository: sl<RevisionRepository>(),
      perfRepository: sl<PerformanceDataRepository>(),
      userId: userId,
    ),
  );

  // SessionBloc needs SessionRepository with userId param
  sl.registerFactoryParam<SessionBloc, String, void>(
    (userId, _) => SessionBloc(
      repository: sl<SessionRepository>(param1: userId),
    ),
  );

  // PredictionCubit needs userId param
  sl.registerFactoryParam<PredictionCubit, String, void>(
    (userId, _) => PredictionCubit(
      repository: sl<PredictionRepository>(param1: userId),
      userId: userId,
    ),
  );

  // SubjectAnalyticsCubit needs userId param
  sl.registerFactoryParam<SubjectAnalyticsCubit, String, void>(
    (userId, _) => SubjectAnalyticsCubit(
      repository: sl<SubjectAnalyticsRepository>(),
      userId: userId,
    ),
  );

  // PlanDraftRepository
  sl.registerLazySingleton<PlanDraftRepository>(
    () => PlanDraftRepositoryImpl(),
  );

  // CommitService
  sl.registerLazySingleton<CommitService>(
    () => CommitService(syncQueue: sl<SyncQueueService>()),
  );

  sl.registerFactory<ScheduleCubit>(
    () => ScheduleCubit(repository: sl<StudyPlanRepository>()),
  );

  sl.registerFactory<PlanDraftBloc>(
    () => PlanDraftBloc(
      networkInfo: sl<NetworkInfo>(),
      repository: sl<PlanDraftRepository>(),
      commitService: sl<CommitService>(),
    ),
  );

  sl.registerFactoryParam<AiChatCubit, String, void>(
    (userId, _) => AiChatCubit(sl<AiChatRepository>(), userId),
  );

  sl.registerFactory<ProgressCubit>(
    () => ProgressCubit(repository: sl<ProgressRepository>()),
  );

  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(repository: sl<SettingsRepository>()),
  );

  sl.registerFactory<AuthCubit>(
    () => AuthCubit(repository: sl<AuthRepository>()),
  );
}
