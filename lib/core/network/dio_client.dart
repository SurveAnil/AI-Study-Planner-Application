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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
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
}
