import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio HTTP client configured for the local Python FastAPI backend.
/// Real device / local network: uses the host PC LAN IP.
class DioClient {
  late final Dio dio;

  String getBaseUrl() {
    return "https://study-planner-app-backend.onrender.com";
  }

  DioClient() {
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

    // Logging interceptor for debug builds
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ),
    );
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
