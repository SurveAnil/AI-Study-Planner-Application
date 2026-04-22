import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/settings/data/settings_repository.dart';

/// Dio HTTP client configured for the Python FastAPI backend.
/// Injects X-OpenRouter-Key / X-OpenRouter-Model headers when
/// the user has enabled their own API key via Settings.
class DioClient {
  late final Dio dio;
  final SettingsRepository settingsRepository;

  String getBaseUrl() {
    // For Android Emulator: "http://10.0.2.2:8765"
    // For iOS/Physical Device: your computer's LAN IP
    return "https://study-planner-app-backend.onrender.com";
  }

  DioClient({required this.settingsRepository}) {
    dio = Dio(
      BaseOptions(
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Custom API key interceptor ─────────────────────────────────────
    // Reads the latest settings synchronously from the in-memory cache
    // and injects the appropriate headers on every request.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final settings = settingsRepository.currentSettings;
          if (settings.useCustomApi &&
              settings.openRouterApiKey != null &&
              settings.openRouterApiKey!.isNotEmpty) {
            options.headers['X-OpenRouter-Key'] = settings.openRouterApiKey!;
            if (settings.aiModel != 'Default (Backend)') {
              options.headers['X-OpenRouter-Model'] = settings.aiModel;
            }
            debugPrint('[DIO] Injecting custom OpenRouter headers.');
          }
          handler.next(options);
        },
      ),
    );

    // ── Logging (debug only) ───────────────────────────────────────────
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
    }
  }

  /// Wake up the backend (Render cold start)
  Future<void> warmup() async {
    try {
      await dio.get('/');
    } catch (_) {
      // Ignored: just a ping
    }
  }

  /// Global safe wrapper with 1 automatic retry
  Future<Response<T>> safeRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } catch (e) {
      debugPrint("API failed, retrying in 2 seconds... ($e)");
      await Future.delayed(const Duration(seconds: 2));
      return await request();
    }
  }

  /// Global error string mapper
  static String mapErrorToMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return "Server waking up... please wait.";
      }
      if (error.type == DioExceptionType.connectionError) {
        return "Check your internet connection.";
      }
      if (error.response?.statusCode == 521 ||
          error.response?.statusCode == 522 ||
          error.response?.statusCode == 503) {
        return "Server waking up... please wait.";
      }
    }
    return "Something went wrong. Please try again.";
  }
}
