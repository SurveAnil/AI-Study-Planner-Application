import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/chat_generate_response.dart';

class AiChatRepository {
  final DioClient _dioClient;

  AiChatRepository(this._dioClient);

  Future<Either<Failure, ChatGenerateResponse>> generateChatPlan(String message, String userId) async {
    try {
      final response = await _dioClient.dio.post(
        '/plan/chat-generate',
        data: {
          'message': message,
          'user_id': userId,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      return Right(ChatGenerateResponse.fromJson(response.data));
    } catch (e) {
      return Left(CloudAIFailure('Chat Error: $e', statusCode: 500));
    }
  }

  /// Phase 1 — Generate a structured learning roadmap for [skill].
  Future<Either<Failure, Map<String, dynamic>>> generateRoadmap(String skill) async {
    try {
      final response = await _dioClient.dio.post(
        '/roadmap/generate',
        data: {'skill': skill},
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      return Right(Map<String, dynamic>.from(response.data as Map));
    } catch (e) {
      return Left(CloudAIFailure('Roadmap Error: $e', statusCode: 500));
    }
  }
}

