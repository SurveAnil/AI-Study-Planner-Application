import '../data/models/chat_generate_response.dart';

abstract class AiChatState {}

class AiChatInitial extends AiChatState {}

class AiChatLoading extends AiChatState {}

class AiChatSuccess extends AiChatState {
  final ChatGenerateResponse response;
  AiChatSuccess(this.response);
}

/// Phase 1 — emitted after a roadmap is successfully generated.
class RoadmapSuccess extends AiChatState {
  final Map<String, dynamic> roadmap;
  RoadmapSuccess(this.roadmap);
}

class AiChatError extends AiChatState {
  final String message;
  AiChatError(this.message);
}
