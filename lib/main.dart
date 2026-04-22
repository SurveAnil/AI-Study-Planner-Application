import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'core/constants/app_colors.dart';
import 'core/database/database_helper.dart';
import 'core/di/injection_container.dart' as di;
import 'features/home/presentation/main_nav_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';

// Import Cubits manually right now to wrap the App
import 'features/plan_draft/bloc/plan_draft_bloc.dart';
import 'features/schedule/bloc/schedule_cubit.dart';
import 'features/session/bloc/session_bloc.dart';
import 'features/progress/bloc/prediction_cubit.dart';
import 'features/progress/bloc/subject_analytics_cubit.dart';
import 'features/revision/bloc/revision_calendar_cubit.dart';
import 'features/progress/bloc/progress_cubit.dart';
import 'features/ai_chat/bloc/ai_chat_cubit.dart';
import 'features/settings/bloc/settings_cubit.dart';
import 'features/auth/bloc/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseHelper.database;

  // Initialize dependency injection
  await di.init();

  // Check if it's the first launch
  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(StudyPlannerApp(showHome: showHome));
}

final _uuid = const Uuid();
final _testUserId = _uuid.v4(); // Temporary placeholder until Authentication sprint

class StudyPlannerApp extends StatelessWidget {
  final bool showHome;
  const StudyPlannerApp({super.key, required this.showHome});

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
        BlocProvider(create: (_) => di.sl<ProgressCubit>()),
        BlocProvider(create: (_) => di.sl<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => di.sl<AuthCubit>()..loadProfile()),
      ],
      child: MaterialApp(
      title: 'AI Study Planner',
      debugShowCheckedModeBanner: false,

      // ─── Midnight Precision Premium Theme ────────────────────────────
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        dividerColor: Colors.white.withAlpha(20), // very subtle
        
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondaryAccent,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          primaryContainer: Color(0xFF1E293B), // Elevated surface for primary containers
          outline: Color(0xFF334155),
          outlineVariant: Color(0xFF1E293B),
        ),

        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme
        ).copyWith(
          // Ensure correct text colors
          displayLarge: const TextStyle(color: AppColors.textPrimary),
          displayMedium: const TextStyle(color: AppColors.textPrimary),
          displaySmall: const TextStyle(color: AppColors.textPrimary),
          headlineLarge: const TextStyle(color: AppColors.textPrimary),
          headlineMedium: const TextStyle(color: AppColors.textPrimary),
          headlineSmall: const TextStyle(color: AppColors.textPrimary),
          titleLarge: const TextStyle(color: AppColors.textPrimary),
          titleMedium: const TextStyle(color: AppColors.textPrimary),
          titleSmall: const TextStyle(color: AppColors.textPrimary),
          bodyLarge: const TextStyle(color: AppColors.textPrimary),
          bodyMedium: const TextStyle(color: AppColors.textPrimary),
          bodySmall: const TextStyle(color: AppColors.textSecondary),
          labelLarge: const TextStyle(color: AppColors.textPrimary),
          labelMedium: const TextStyle(color: AppColors.textSecondary),
          labelSmall: const TextStyle(color: AppColors.textSecondary),
        ),

        // Default Card Theme for consistency
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        useMaterial3: true,
      ),

      themeMode: ThemeMode.dark, // Enforce Dark Theme

      // Route based on the first-time marker
      home: showHome ? const LoginScreen() : const OnboardingScreen(),
    ));
  }
}
