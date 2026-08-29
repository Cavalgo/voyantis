import 'parsing.dart';

/// Respuesta de `POST /api/chat`. Congelado en FASE 1 — espejo de lo que
/// devuelve `functions/index.js`: `{ reply, tripId, itinerarySaved, error }`.
class ChatResponse {
  const ChatResponse({
    this.reply,
    this.tripId,
    this.itinerarySaved = false,
    this.error,
  });

  /// Texto del agente para mostrar en el chat. `null` si hubo error.
  final String? reply;

  /// SIEMPRE presente en una respuesta OK (nuevo o existente). Flutter lo usa
  /// para `watchTrip(tripId)`.
  final String? tripId;

  /// `true` cuando el agente llamó `save_itinerary` este turno.
  final bool itinerarySaved;

  /// `null` en el happy path; string con el motivo si algo falló.
  final String? error;

  bool get hasError => error != null;
  bool get isOk => error == null && reply != null;

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
        reply: jStrN(json['reply']),
        tripId: jStrN(json['tripId']),
        itinerarySaved: jBool(json['itinerarySaved']),
        error: jStrN(json['error']),
      );

  Map<String, dynamic> toJson() => {
        'reply': reply,
        'tripId': tripId,
        'itinerarySaved': itinerarySaved,
        'error': error,
      };
}
