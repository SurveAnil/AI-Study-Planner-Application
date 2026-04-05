import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/ai_chat_repository.dart';
import 'ai_chat_state.dart';
import 'package:flutter/foundation.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final AiChatRepository _repository;
  final String _userId;

  AiChatCubit(this._repository, this._userId) : super(AiChatInitial());

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    emit(AiChatLoading());
    debugPrint('[AI Chat] Sending message: $message');

    try {
      final result = await _repository.generateChatPlan(message, _userId);
      
      result.fold(
        (failure) {
          debugPrint('[AI Chat] Error: ${failure.message}');
          emit(AiChatError(failure.message));
        },
        (response) {
          debugPrint('[AI Chat] Response received');
          debugPrint('[AI Chat] Blocks parsed: ${response.blocks.length}');
          emit(AiChatSuccess(response));
        },
      );
    } catch (e) {
      debugPrint('[AI Chat] Unexpected Error: $e');
      emit(AiChatError(e.toString()));
    }
  }

  /// Phase 1 — Generate a structured roadmap for [skill].
  Future<void> generateRoadmap(String skill) async {
    if (skill.trim().isEmpty) return;

    emit(AiChatLoading());
    debugPrint('[Roadmap] Generating roadmap for: $skill');

    try {
      final result = await _repository.generateRoadmap(skill);

      result.fold(
        (failure) {
          debugPrint('[Roadmap] Error: ${failure.message}');
          emit(AiChatError(failure.message));
        },
        (roadmap) {
          debugPrint('[Roadmap] Success — ${roadmap['stages']?.length ?? 0} stages');
          emit(RoadmapSuccess(roadmap));
        },
      );
    } catch (e) {
      debugPrint('[Roadmap] Unexpected Error: $e');
      emit(AiChatError(e.toString()));
    }
  }
}
