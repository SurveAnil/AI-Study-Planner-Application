import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio HTTP client configured for the local Python FastAPI backend.
/// Physical device (USB): uses adb reverse → 127.0.0.1
/// Android emulator:       uses 10.0.2.2 (host alias)
class DioClient {
  late final Dio dio;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8765"; // Android emulator → host machine
    } else {
      return "http://192.168.0.100:8765"; // Replace with actual PC IP (192.168.0.100)
    }
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
