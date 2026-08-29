# feature: chat_agent  (rama `feature/ui`)

UI de conversación con el agente (diagnóstico + ajustes posteriores).

## Estructura
- `data/chat_repository.dart` — `ChatRepository.sendMessage({String? tripId, required List<ChatMessage> messages})`
  → `ApiClient.postChat({ profileId: kProfileId, tripId, messages })`. Manda el **historial completo**
  (Claude es stateless). Devuelve `ChatResponse { reply, tripId, itinerarySaved, error }`.
- `presentation/chat_notifier.dart` — `chatNotifierProvider` (`NotifierProvider<ChatNotifier, ChatState>`).
  `ChatState` guarda la lista completa de mensajes (solo turnos reales — el saludo es UI), `isLoading`,
  `tripId` (null hasta el primer save) y `lastSaveAt` (para que el shell reaccione una sola vez).
  `send()`, `retryLast()`, `reset()`.
- `presentation/chat_screen.dart` — burbujas + input. Estado vacío con sugerencias del demo.
  Barra de error con "Reintentar". Auto-scroll al fondo.
- `presentation/widgets/`
  - `message_bubble.dart` — burbuja user (sienna, derecha) / assistant (tarjeta, izquierda).
  - `thinking_indicator.dart` — loading **muy visible**: el agente tarda ~30s en responder y ~55s
    en guardar. Cicla el texto de estado según el tiempo y muestra los segundos.

## Contrato con el itinerario
Cuando `ChatResponse.itinerarySaved == true`, `ChatState.lastSaveAt` se actualiza; `HomeShell`
(en `main.dart`) lo escucha, salta a la pestaña del itinerario (layout angosto) y muestra un snackbar.
El timeline ya se actualiza solo vía el stream de Firestore.

## Base URL (`core/services/api_client.dart`)
- Release (Hosting): `/api` (rewrite mismo-origen).
- Dev (`flutter run -d chrome`): URL cruda de la función deployada. CORS resuelto en el backend.

Consume: `core/models`, `core/config.dart`, `core/services/api_client.dart`. Ver `phases.md` (TRACK B).
