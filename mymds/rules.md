# Rules — Convenciones para hoy

## Riverpod: SIN code generation
Usen `NotifierProvider` / `StreamProvider` / `Provider` escritos a mano, **no** `@riverpod` con `build_runner`. Razón: con 7 personas commiteando en paralelo, los archivos `.g.dart` generados causan conflictos de merge constantes y `build_runner watch` es una fricción que hoy no vale la pena. Ejemplo del patrón esperado:

```dart
final tripProvider = StreamProvider.family<Trip, String>((ref, tripId) {
  return FirestoreService.instance.tripStream(tripId);
});

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => ChatState.initial();

  Future<void> sendMessage(String text) async {
    state = state.copyWith(isLoading: true);
    // ...
  }
}
```

## Arquitectura
Ver `flutter-architecture-features.md` para la estructura de carpetas por feature. Regla simple: **no llamar Firestore/HTTP directamente desde un widget** — siempre pasa por un repository, consumido por un provider/notifier.

## Manejo de loading/error
Todo dato que venga de Firestore o del backend se maneja como `AsyncValue` (loading / data / error) en Riverpod. Nunca dejar una pantalla en blanco sin feedback — mínimo un `CircularProgressIndicator` o mensaje de error.

## Naming
- Archivos: `snake_case.dart` (ej: `chat_screen.dart`, `trip_repository.dart`)
- Clases: `PascalCase`
- Sufijos claros: `_screen.dart` (pantallas), `_provider.dart` (providers/notifiers), `_repository.dart`, `_model.dart`

## Git — flujo simplificado para hoy
- Una rama por squad: `feature/agente`, `feature/ui`, `feature/datos` (o las que definan)
- Commits pequeños y frecuentes, mensajes cortos y claros
- Merge a `main` en cuanto algo funcione localmente — **no hay PR review formal hoy**, solo prueben antes de mergear
- Si algo rompe `main`, revertir el commit inmediatamente, no debuggear en vivo sobre la rama compartida

## Secrets
La API key de Claude y la de Google Places viven **solo** en las variables de entorno de la Cloud Function. Nunca en código Flutter, nunca en un commit.

## Qué NO hacer hoy
No tests unitarios exhaustivos, no CI/CD, no capas de abstracción extra que no aporten (ej. use-cases si el repository ya es suficientemente simple), no manejo de auth complejo (usen Auth anónimo o un usuario fijo).
