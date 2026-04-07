class ChatMessage {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.data,
  });
}