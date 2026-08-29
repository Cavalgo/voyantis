# Skills — Recetas rápidas para hoy

Guías cortas para las tareas que se repiten hoy. Úsenlas como prompt base para Claude Code.
Convenciones y decisiones fijas: `rules.md`. Fases: `phases.md` (raíz).

---

## 1. Crear una nueva feature
1. Carpeta `lib/features/<nombre>/` con `data/`, `domain/`, `presentation/widgets/`.
2. `domain/`: definir el modelo/entidad si no existe ya en `core/models/`.
3. `data/`: repository que habla con Firestore o con la Cloud Function.
4. `presentation/`: pantalla + `Notifier`/`StreamProvider` (a mano, sin codegen) que consume el repository.
5. Seguir el patrón de `flutter-architecture-features.md`. Documentar la feature en 5–10 líneas.

## 2. Conectar una pantalla a un stream de Firestore
1. `StreamProvider` (o `.family` si depende de un id) definido en/junto al repository.
2. En la pantalla: `ref.watch(miProvider)` + `.when(data:, loading:, error:)` — los 3 casos, siempre.
3. Nunca la query de Firestore directo en el widget.

## 3. Recuperar "el viaje actual" (sin auth, perfil fijo)
```dart
// lib/core/config.dart
const String kProfileId = 'voyantis-demo';

// trip_repository.dart
Stream<Trip?> watchCurrentTrip() {
  return _db.collection('trips')
      .where('profileId', isEqualTo: kProfileId)
      .orderBy('updatedAt', descending: true)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : Trip.fromJson(s.docs.first.data()));
}
```
- La 1ª vez, Firestore tira un error con un **link para crear el índice compuesto** (`profileId` + `updatedAt`). Créenlo.
- Al recargar la página, este stream vuelve a emitir el último trip → el itinerario reaparece solo.

## 4. Agregar un tool call al agente (backend, Cloud Function)
1. Definir el tool en formato Claude API (`name`, `description`, `input_schema` JSON Schema).
2. Implementar la función real (Google Places, o escribir en Firestore con Admin SDK).
3. Loop manual (no el tool runner beta) en la función:
   ```js
   let messages = [...req.body.messages];
   while (true) {
     const resp = await anthropic.messages.create({
       model: 'claude-opus-5', max_tokens: 16000, system: SYSTEM_PROMPT,
       tools: TOOLS, messages,
     });
     if (resp.stop_reason === 'end_turn') break;
     const toolUses = resp.content.filter(b => b.type === 'tool_use');
     messages.push({ role: 'assistant', content: resp.content });
     const results = [];
     for (const t of toolUses) {
       const out = await runTool(t.name, t.input);      // search_places | save_itinerary
       results.push({ type: 'tool_result', tool_use_id: t.id, content: JSON.stringify(out) });
     }
     messages.push({ role: 'user', content: results });
   }
   ```
4. `save_itinerary` debe escribir `profileId` (de `req.body.profileId`) y `updatedAt` en el doc, y devolver el `tripId`.
5. Documentar el tool nuevo en `ai-agent-design.md`.

## 5. Secrets de la Cloud Function
```js
const { defineSecret } = require('firebase-functions/params');
const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');
const GOOGLE_PLACES_API_KEY = defineSecret('GOOGLE_PLACES_API_KEY');

exports.api = onRequest(
  { secrets: [ANTHROPIC_API_KEY, GOOGLE_PLACES_API_KEY], timeoutSeconds: 300, memory: '512MiB' },
  app // express
);
```
- Emulador: `functions/.secret.local` (gitignored) con `ANTHROPIC_API_KEY=...`. Copiar de `functions/.secret.local.example`.
- ⚠️ **NO** uses `functions/.env` para estas keys — se despliega como env var y choca con `defineSecret`.
- Deploy: `firebase functions:secrets:set ANTHROPIC_API_KEY` (ya hecho para las 2). Ya deployada.
- En el código: leer con `ANTHROPIC_API_KEY.value()` dentro del handler.

## 6. Evitar CORS
`firebase.json`:
```json
{ "hosting": { "rewrites": [ { "source": "/api/**", "function": "api" } ] } }
```
Flutter llama a `/api/chat` (mismo origen). En dev con `flutter run -d chrome`, usar la URL desplegada
de la función o los emuladores.

## 7. Renderizar una sección del timeline visual
1. Cada "día" = una tarjeta/sección expandible con sus actividades.
2. Cada actividad: foto (`location.photoUrl` con `cached_network_image`), título, hora, descripción corta, tip.
3. Un solo widget `ActivityCard` parametrizado — no un widget por tipo de actividad.
4. Priorizar que se vea bien con 3–4 actividades antes de casos raros (0, 20 actividades).

## 8. Deploy
```bash
flutter build web
firebase deploy --only hosting
firebase deploy --only functions
```
