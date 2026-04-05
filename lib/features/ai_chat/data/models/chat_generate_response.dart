import 'chat_plan_block.dart';

class ChatGenerateResponse {
  final String human;
  final List<ChatPlanBlock> blocks;

  ChatGenerateResponse({
    required this.human,
    required this.blocks,
  });

  factory ChatGenerateResponse.fromJson(Map<String, dynamic> json) {
    return ChatGenerateResponse(
      human: json['human'] ?? '',
      blocks: (json['blocks'] as List? ?? [])
          .map((i) => ChatPlanBlock.fromJson(i))
          .toList(),
    );
  }
}
