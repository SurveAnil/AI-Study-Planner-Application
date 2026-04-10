import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'core/constants/app_colors.dart';
import 'core/database/database_helper.dart';
import 'core/di/injection_container.dart' as di;
import 'features/home/presentation/main_nav_screen.dart';

// Import Cubits manually right now to wrap the App
import 'features/plan_draft/bloc/plan_draft_bloc.dart';
import 'features/schedule/bloc/schedule_cubit.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/progress/bloc/prediction_cubit.dart';
import 'features/progress/bloc/subject_analytics_cubit.dart';
import 'features/revision/bloc/revision_calendar_cubit.dart';
import 'features/ai_chat/bloc/ai_chat_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseHelper.database;

  // Initialize dependency injection
  await di.init();

  runApp(const StudyPlannerApp());
}

final _uuid = const Uuid();
final _testUserId = _uuid.v4(); // Temporary placeholder until Authentication sprint

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<PlanDraftBloc>()),
        BlocProvider(create: (_) => di.sl<ScheduleCubit>()..loadCurrentDay()),
        BlocProvider(create: (_) => di.sl<SessionBloc>(param1: _testUserId)),
        BlocProvider(create: (_) => di.sl<PredictionCubit>(param1: _testUserId)),
        BlocProvider(create: (_) => di.sl<SubjectAnalyticsCubit>(param1: _testUserId)),
        BlocProvider(create: (_) => di.sl<RevisionCalendarCubit>(param1: _testUserId)),
        BlocProvider(create: (_) => di.sl<AiChatCubit>(param1: _testUserId)),
      ],
      child: MaterialApp(
      title: 'AI Study Planner',
      debugShowCheckedModeBanner: false,

      // ─── Light Theme ────────────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),

      // ─── Dark Theme ─────────────────────────────────────────────────
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primaryDark,
          secondary: AppColors.secondaryDark,
          surface: AppColors.surfaceDark,
          error: AppColors.errorDark,
          onSurface: AppColors.onSurfaceDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          outline: AppColors.outlineDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),

      themeMode: ThemeMode.system,

      // Wrap the app with MainNavScreen
      home: const MainNavScreen(),
    ));
  }
}
