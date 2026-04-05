class ChatPlanBlock {
  final String title;
  final String subject;
  final String startTime;
  final String endTime;
  final String type;

  ChatPlanBlock({
    required this.title,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory ChatPlanBlock.fromJson(Map<String, dynamic> json) {
    return ChatPlanBlock(
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      type: json['type'] ?? '',
    );
  }
}
