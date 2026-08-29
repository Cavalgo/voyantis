# Flutter — Arquitectura por Feature

## Principio general
Clean Architecture **ligera**: 3 carpetas por feature, sin capa de use-cases separada (los notifiers llaman al repository directo — para hoy es suficiente separación).

```
lib/
  core/
    config.dart      → const kProfileId = 'voyantis-demo' + constantes globales
    models/          → Trip, TravelerProfile, Activity, etc (compartidos entre features)
    services/         → FirestoreService, ApiClient (para la Cloud Function)
    theme/             → colores, tipografía, estilos del timeline aesthetic
  features/
    chat_agent/
      data/            → ChatRepository (habla con la Cloud Function)
      domain/          → (opcional) interfaces si hay más de una implementación
      presentation/    → ChatScreen, ChatNotifier, widgets del chat
    itinerary_view/
      data/            → TripRepository (lee/escucha Firestore)
      domain/
      presentation/    → ItineraryScreen, TimelineDay widget, ActivityCard widget
```

## Feature: `chat_agent`
**Objetivo:** UI de conversación con el agente (fase de diagnóstico y ajustes posteriores).

- `data/chat_repository.dart`: `sendMessage({String? tripId, required List<ChatMessage> messages}) → Future<ChatResponse>`.
  Manda a la Cloud Function `{ profileId: kProfileId, tripId, messages }` (el **historial completo** — Claude
  API es stateless). Recibe `{ reply, tripId, itinerarySaved, error }`.
- `presentation/chat_notifier.dart`: `Notifier<ChatState>` con la **lista completa de mensajes** (es lo que
  se reenvía cada turno), estado de loading, y el `tripId` actual (null hasta el primer `save_itinerary`).
  Opcional: persistir `{tripId, messages}` en `localStorage` para sobrevivir un reload durante el diagnóstico.
- `presentation/chat_screen.dart`: burbujas + input. Cuando `ChatResponse.itinerarySaved`, navegar / mostrar
  link a `itinerary_view` con el `tripId`.

## Feature: `itinerary_view`
**Objetivo:** mostrar el itinerario guardado como timeline visual — esta es la pantalla que más debe brillar hoy.

- `data/trip_repository.dart`:
  - `Stream<Trip> watchTrip(String tripId)` sobre Firestore
  - `Stream<Trip?> watchCurrentTrip()` → `trips.where('profileId', ==, kProfileId).orderBy('updatedAt', descending: true).limit(1)`.
    Esta es la que usa la app al arrancar: **siempre muestra el último viaje de la DB**, aguanta reloads.
    Necesita el índice compuesto (ya desplegado en `firestore.indexes.json`).
- `presentation/itinerary_screen.dart`: header con resumen (destino, fechas, presupuesto total, vibe tags) + lista de días expandibles
- `presentation/widgets/timeline_day.dart`: una sección por día (tema del día + lista de `ActivityCard`)
- `presentation/widgets/activity_card.dart`: foto (de Google Places), hora, título, descripción, costo estimado, tip — este widget se reutiliza para toda actividad

## Template para features nuevas (si agregan una)
```
features/<nombre>/
  data/
    <nombre>_repository.dart
  domain/            (opcional, solo si hay lógica de negocio real que aislar)
  presentation/
    <nombre>_screen.dart
    <nombre>_notifier.dart
    widgets/
```
Documenten en 5-10 líneas: qué hace la feature, qué datos consume de `core/models`, y qué provider expone hacia afuera si otra feature lo necesita.
