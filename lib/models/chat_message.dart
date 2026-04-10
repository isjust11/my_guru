/// Represents a single chat message in the conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isThinking;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isThinking = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isThinking,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}
