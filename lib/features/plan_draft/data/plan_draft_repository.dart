import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/failures.dart';
import '../models/draft_models.dart';

abstract class PlanDraftRepository {
  Future<Either<Failure, PlanDraftResponse>> generateDraft(
    String userId,
    PlanRequest request,
  );
}

class PlanDraftRepositoryImpl implements PlanDraftRepository {
  @override
  Future<Either<Failure, PlanDraftResponse>> generateDraft(
    String userId,
    PlanRequest request,
  ) async {
    try {
      // ✅ FORCE CORRECT BASE URL (NO abstraction confusion)
      final dio = Dio(
        BaseOptions(
          baseUrl: "https://study-planner-app-backend.onrender.com",
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      print("🔥 USING FORCED BASE URL: ${dio.options.baseUrl}");

      final response = await dio.post(
        "/plan/generate-with-context",
        data: {'user_id': userId, 'request': request.toJson()},
      );

      print("✅ API Response: ${response.data}");

      final data = response.data as Map<String, dynamic>;

      final planDraft = PlanDraftResponse.fromJson(data);

      return Right(planDraft);
    } on TimeoutException catch (e) {
      print("⏱ Timeout Error: ${e.message}");
      return Left(
        LLMTimeoutFailure(
          e.message ?? 'Timeout waiting for AI plan',
          elapsedMs: 15000,
        ),
      );
    } on DioException catch (e) {
      print("❌ Dio Error: ${e.message}");

      final responseData = e.response?.data;
      String message = e.message ?? 'Unknown backend error';

      if (responseData is Map) {
        message = responseData['detail'] ?? message;
      } else if (responseData is String) {
        message = responseData;
      }

      return Left(
        CloudAIFailure(
          'Backend Error: $message',
          statusCode: e.response?.statusCode ?? 500,
        ),
      );
    } on FormatException catch (e) {
      print("❌ JSON Parse Error: ${e.message}");
      return Left(
        LLMParseFailure(
          'Invalid JSON response format: ${e.message}',
          rawOutput: '',
        ),
      );
    } catch (e) {
      print("❌ Unexpected Error: $e");
      return Left(
        CloudAIFailure(
          'Unexpected error generating draft: $e',
          statusCode: 500,
        ),
      );
    }
  }
}
