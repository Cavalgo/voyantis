import '../../../core/config.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_client.dart';

/// Habla con la Cloud Function del agente.
///
/// Manda el **historial completo** de mensajes cada turno (Claude API es
/// stateless). El `profileId` es fijo (`kProfileId`); el backend lo escribe en
/// el doc, el modelo no lo ve.
class ChatRepository {
  ChatRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<ChatResponse> sendMessage({
    String? tripId,
    required List<ChatMessage> messages,
  }) {
    return _api.postChat(
      ChatRequest(
        profileId: kProfileId,
        tripId: tripId,
        messages: messages,
      ),
    );
  }
}
