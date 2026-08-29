import 'parsing.dart';

/// Un turno de la conversación. Flutter mantiene la lista completa y la
/// reenvía entera en cada request (Claude API es stateless).
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  const ChatMessage.user(this.content) : role = 'user';
  const ChatMessage.assistant(this.content) : role = 'assistant';

  /// `"user"` | `"assistant"`.
  final String role;
  final String content;

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: jStr(json['role'], 'user'),
        content: jStr(json['content']),
      );

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}
