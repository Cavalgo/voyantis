import 'chat_message.dart';

/// Body de `POST /api/chat`. Congelado en FASE 1 — debe cuadrar con lo que
/// lee `functions/index.js` (`const { profileId, tripId, messages } = req.body`).
class ChatRequest {
  const ChatRequest({
    required this.profileId,
    required this.messages,
    this.tripId,
  });

  /// Perfil fijo (`kProfileId`). El backend lo escribe en el doc `trips`;
  /// el modelo de Claude no lo ve.
  final String profileId;

  /// `null` hasta el primer `save_itinerary`.
  final String? tripId;

  /// Historial COMPLETO de la conversación.
  final List<ChatMessage> messages;

  factory ChatRequest.fromJson(Map<String, dynamic> json) => ChatRequest(
        profileId: json['profileId'] as String? ?? '',
        tripId: json['tripId'] as String?,
        messages: (json['messages'] as List?)
                ?.map((e) =>
                    ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'tripId': tripId,
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}
