# Rules — Convenciones para hoy

Reglas cortas y no negociables para que 7 personas trabajen en paralelo sin pisarse.
El desglose de fases está en `phases.md` (raíz); los problemas conocidos en `auditoria.md` (raíz).

---

## Decisiones fijas (no re-discutir)

| Tema | Decisión |
|---|---|
| Modelo de Claude | `claude-opus-5` |
| Auth | **Ninguna.** Perfil fijo `PROFILE_ID = "voyantis-demo"` en `lib/core/config.dart` |
| Historial de chat | Flutter mantiene la lista completa de mensajes y la reenvía entera en cada request |
| Llamadas al backend | Flutter llama a `/api/**` (rewrite de Hosting), **nunca** a la URL cruda de la función |
| Fechas | ISO 8601 string (`"2026-08-29"` / `"2026-08-29T14:00:00Z"`) en todo: Firestore, JSON, modelos |
| Colección Firestore | `trips` (un doc = un itinerario). Siempre escribir `updatedAt` (server timestamp) y `profileId` |
| Cloud Function | Node 20, Functions **v2**, `timeoutSeconds: 300`, `memory: "512MiB"` |

---

## Riverpod: SIN code generation

`NotifierProvider` / `StreamProvider` / `Provider` escritos a mano, **no** `@riverpod` con `build_runner`.
Razón: con 7 personas commiteando en paralelo, los `.g.dart` generan conflictos de merge constantes.

```dart
final currentTripProvider = StreamProvider<Trip?>((ref) {
  return TripRepository.instance.watchCurrentTrip(); // query profileId == PROFILE_ID
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

Ver `flutter-architecture-features.md` para la estructura de carpetas por feature. Regla simple:
**no llamar Firestore/HTTP directamente desde un widget** — siempre pasa por un repository,
consumido por un provider/notifier.

## Manejo de loading/error

Todo dato que venga de Firestore o del backend se maneja como `AsyncValue` (loading / data / error)
en Riverpod. Nunca una pantalla en blanco sin feedback — mínimo un `CircularProgressIndicator`
o un mensaje de error.

## Naming

- Archivos: `snake_case.dart` (`chat_screen.dart`, `trip_repository.dart`)
- Clases: `PascalCase`
- Sufijos: `_screen.dart`, `_notifier.dart` / `_provider.dart`, `_repository.dart`, `_model.dart`

## Contrato del backend (congelado en FASE 1)

```jsonc
// POST /api/chat
// request
{ "profileId": "voyantis-demo", "tripId": "abc | null", "messages": [ {"role":"user","content":"..."} ] }
// response
{ "reply": "...", "tripId": "abc", "itinerarySaved": true, "error": null }
```
- El backend escribe `profileId` en el doc `trips` (lo toma del request, el modelo no lo ve).
- `tripId` **siempre** vuelve en la respuesta. `itinerarySaved: true` cuando el agente llamó `save_itinerary` ese turno.

## Git — flujo simplificado para hoy

- Ramas: `feature/agent` (Squad A / backend), `feature/ui` (Squad B). Squad C trabaja en `main` (solo docs/deck).
- Commits pequeños y frecuentes, mensajes cortos.
- Merge a `main` en cuanto algo funcione localmente — **no hay PR review formal hoy**, solo prueben antes.
- Si algo rompe `main`: **revertir el commit de inmediato**, no debuggear en vivo sobre la rama compartida.

## Secrets

- API keys (Anthropic, Google Places) viven **solo**:
  - **Emulador local:** `functions/.secret.local` (gitignored). Plantilla: `functions/.secret.local.example`.
  - **Deploy:** Secret Manager (`firebase functions:secrets:set ...`, ya hecho); en el código `defineSecret(...)` + `.value()`.
  - ⚠️ **NO** poner estas keys en `functions/.env` — Firebase lo despliega como env var y choca con `defineSecret`
    (`Secret environment variable overlaps non secret environment variable`).
- **Nunca** en código Flutter, nunca en un commit, nunca en `console.log`, nunca con `functions:config:set` en archivo commiteado.
- Las keys de este demo se compartieron en texto plano en un chat → **rotarlas después del evento**.
- `lib/firebase_options.dart` **SÍ se commitea** — su Web API key es pública por diseño (la seguridad está en las reglas de Firestore).
- Antes de cada push: `git status` + un vistazo al diff.

## Qué NO hacer hoy

- No tests unitarios exhaustivos, no CI/CD.
- **No Auth** (ni anónima ni real) — el perfil fijo `PROFILE_ID` alcanza.
- No capas de abstracción extra (use-cases si el repository ya es simple).
- No `build_runner` / codegen de ningún tipo.
- No soporte mobile nativo — es Flutter **Web**.
