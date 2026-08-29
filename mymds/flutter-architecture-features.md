# Flutter — Arquitectura por Feature

## Principio general
Clean Architecture **ligera**: 3 carpetas por feature, sin capa de use-cases separada (los notifiers llaman al repository directo — para hoy es suficiente separación).

```
lib/
  core/
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

- `data/chat_repository.dart`: método `sendMessage(String tripId, String text) → Future<ChatResponse>` que llama a la Cloud Function
- `presentation/chat_notifier.dart`: `Notifier<ChatState>` con lista de mensajes, estado de loading, y el `tripId` actual (null hasta que se crea el primer draft)
- `presentation/chat_screen.dart`: lista de burbujas de mensaje + input de texto. Cuando el backend indica que el itinerario fue guardado/actualizado, navegar o mostrar link a `itinerary_view`

## Feature: `itinerary_view`
**Objetivo:** mostrar el itinerario guardado como timeline visual — esta es la pantalla que más debe brillar hoy.

- `data/trip_repository.dart`: `Stream<Trip> watchTrip(String tripId)` sobre Firestore
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
