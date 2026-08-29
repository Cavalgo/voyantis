# feature: chat_agent  (rama `feature/ui`)

UI de conversación con el agente (diagnóstico + ajustes posteriores).

- `data/chat_repository.dart` — `sendMessage({String? tripId, required List<ChatMessage> messages})`
  → POST `/api/chat` con `{ profileId: kProfileId, tripId, messages }`. Devuelve
  `{ reply, tripId, itinerarySaved, error }`. Manda el **historial completo** (Claude es stateless).
- `presentation/chat_notifier.dart` — `Notifier<ChatState>` con la lista completa de mensajes, loading, `tripId`.
- `presentation/chat_screen.dart` — burbujas + input. Al recibir `itinerarySaved`, ir a `itinerary_view`.

Consume: `core/models` (ChatMessage, ChatResponse), `core/config.dart`, `core/services/api_client.dart`.
Ver `mymds/flutter-architecture-features.md` y `phases.md` (TRACK B).
