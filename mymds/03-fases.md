# Fases de Desarrollo — Voyanties

> Este documento ordena el trabajo por **dependencias** y marca qué se puede hacer **en paralelo**.
> Complementa a `00-plan-equipo-timeline.md` (que da el reloj del día); aquí está el grafo de qué
> bloquea a qué. Antes de tocar código, lee también `04-auditoria.md`.

---

## Grafo maestro

```
FASE 0 (setup) ──▶ FASE 1 (contratos) ──┬─▶ TRACK A (backend agente) ─┐
                                        ├─▶ TRACK B (Flutter UI) ──────┼─▶ FASE 2 ─▶ FASE 3 ─▶ FASE 4
        TRACK C (producto / pitch / QA) ┴──────────────────────────────┘  (integr.)  (pulido)  (deploy)
        arranca en T+0, en paralelo con todo; converge en FASE 2
```

**Regla de oro:** nada de Track A/B empieza en serio hasta que FASE 1 congele los contratos
(modelos, formato del request/response, schema de los tools). Media hora de FASE 1 ahorra
dos horas de merge hell en FASE 2.

---

## FASE 0 — Fundaciones y setup
**Bloqueante para todo. ~30–40 min. 2 personas trabajando; el resto lee los docs de su squad.**

Se divide en 3 frentes que corren **en paralelo**:

### Frente 0.A — Cuentas, servicios y API keys
**1 persona · ~25–35 min · bloquea Track A · NO bloquea Track B (usa el seed) ni Track C.**

**0.A.1 — Proyecto Firebase + GCP** (Firebase también crea el proyecto de Google Cloud):
- console.firebase.google.com → *Add project*.
- ⚠️ **Upgrade a plan Blaze** (pay-as-you-go). Obligatorio: en el plan gratuito (Spark) las Cloud
  Functions **no pueden hacer llamadas de red salientes** a `api.anthropic.com` ni a Google Maps.
  Blaze tiene tier gratuito generoso → poner un **budget alert** en ~5 USD.

**0.A.2 — Firestore:** *Firestore Database* → *Create database* → **modo test** (reglas abiertas,
caducan en 30 días — ok para hoy). Región `us-*` (ej. `nam5`); anotarla.

**0.A.3 — Hosting:** *Hosting* → *Get started* (el `firebase init` se hace en 0.D).

**0.A.4 — App Web + `firebase_options.dart`:** correr `flutterfire configure` (necesita FlutterFire
CLI de 0.B) → registra la app web y escribe `lib/firebase_options.dart`.
✅ **`firebase_options.dart` SÍ se commitea** — su "Web API key" es **pública por diseño** (identifica
el proyecto, no da acceso; la seguridad está en las reglas de Firestore).

**0.A.5 — API key de Anthropic (Claude):** Anthropic Console → *API Keys* → `sk-ant-...`.
Vive **solo** como secret de la Cloud Function (ver 0.A.8).

**0.A.6 — API key de Google (Places):**
- Google Cloud Console (mismo proyecto) → *APIs & Services* → habilitar **"Places API"** (la legacy — ver `04-auditoria.md` #11).
- *Credentials* → *Create credentials* → *API key* → `AIza...`.
- Restringir: *API restrictions* → solo "Places API". (No se puede restringir por IP: las Cloud
  Functions gen 2 no tienen IP fija → compensar con el budget alert.)
- Vive como secret de la función. Si las URLs de foto se guardan crudas en Firestore, la key queda
  visible en el cliente (`04-auditoria.md` #10) → si sobra tiempo, endpoint proxy `/api/photo`.

**0.A.7 — Billing GCP:** el upgrade a Blaze de 0.A.1 ya activa billing en el proyecto de Google Cloud,
que es lo que Places API exige. Confirmar en Cloud Console → *Billing* que el proyecto tiene cuenta ligada.

**0.A.8 — Secrets: que NO lleguen a git.**
- **Local:** Track A pone en `functions/.env` → `ANTHROPIC_API_KEY=...` y `GOOGLE_PLACES_API_KEY=...`.
  Ya está en `.gitignore`. Commitear un **`functions/.env.example`** con placeholders para que todos
  sepan qué falta.
- **Deploy (Cloud Functions v2):** `firebase functions:secrets:set ANTHROPIC_API_KEY` y
  `... GOOGLE_PLACES_API_KEY` → Google Secret Manager, inyectados en runtime; en el código se
  referencian con `defineSecret('ANTHROPIC_API_KEY')`.
- **Nunca** commitear las keys, nunca `console.log` de una key. Antes de cada push: `git status` + ojo al diff.

**Checklist 0.A:**
- [ ] Proyecto Firebase + **plan Blaze** + budget alert
- [ ] Firestore modo test + región anotada
- [ ] Hosting habilitado
- [ ] `flutterfire configure` → `firebase_options.dart` commiteado
- [ ] `sk-ant-...` de Anthropic
- [ ] `AIza...` de Google · **Places API** habilitada · key restringida a Places API
- [ ] `functions/.env` local (gitignored) + `functions/.env.example` commiteado
- [ ] secrets de deploy seteados (`firebase functions:secrets:set`)

### Frente 0.B — Toolchain local
- **0.B.1** Instalar **Node 20+** (hoy no está instalado).
- **0.B.2** Instalar **Firebase CLI** (`npm i -g firebase-tools`) y hacer `firebase login`.
- **0.B.3** Instalar **FlutterFire CLI** (`dart pub global activate flutterfire_cli`).
- **0.B.4** Verificar `flutter` (ya está: 3.47.1 / Dart 3.13.1).

### Frente 0.C — Scaffold de código
- **0.C.1** Añadir dependencias a `pubspec.yaml`:
  `flutter_riverpod`, `firebase_core`, `cloud_firestore`, `http`, `google_fonts`,
  `cached_network_image`, `intl`. Correr `flutter pub get`. (Riverpod **sin** codegen — ver `rules.md`.)
- **0.C.2** Crear el árbol de carpetas (ver `flutter-architecture-features.md`):
  ```
  lib/core/{models,services,theme}/
  lib/features/chat_agent/{data,domain,presentation/widgets}/
  lib/features/itinerary_view/{data,domain,presentation/widgets}/
  functions/
  ```
- **0.C.3** Limpiar el scaffold por defecto:
  - `lib/main.dart` → `ProviderScope` + `MaterialApp` + navegación entre las 2 pantallas (borrar el contador).
  - Borrar o dejar como stub `test/widget_test.dart` (hoy referencia el contador → rompe `flutter analyze`).
  - Actualizar `README.md` y el `description:` de `pubspec.yaml`.

### Cierre de FASE 0 (depende de 0.A + 0.B)
- **0.D.1** `git init`, primer commit, conectar remoto de GitHub, push a `main` (ver sección "Git" abajo).
- **0.D.2** Crear ramas `feature/agent` y `feature/ui`.
- **0.D.3** Desplegar una Cloud Function **"hello world"** para tener la **URL real** cuanto antes.
- **0.D.4** En `firebase.json`, configurar rewrite `"/api/**"` → la función (esto **elimina el problema de CORS**).

**Salida de FASE 0:** repo vivo en GitHub, `flutter run -d chrome` levanta un shell vacío,
`firebase deploy` funciona, y hay una URL de función conocida.

---

## FASE 1 — Contratos y modelos
**Bloqueante para la integración. ~30 min. 1 persona de Squad A + 1 de Squad B, juntas.**

Todo lo de esta fase se **congela** y no se re-discute durante el bloque de desarrollo.

- **1.1 — Modelos Dart** (`lib/core/models/`): `Trip`, `TravelerProfile`, `Summary`, `Flight`,
  `Accommodation`, `Day`, `Activity`, `Location`, `BudgetBreakdown`.
  Cada uno con `fromJson` / `toJson` **exactamente** alineados al schema de `02-technical-architecture.md`.
  Ojo con fechas (guardar como ISO string o `Timestamp` — decidir **una** convención).

- **1.2 — Contrato HTTP** Cloud Function ↔ Flutter (congelar los nombres de campos):
  ```jsonc
  // POST /api/chat  — request
  {
    "profileId": "voyanties-demo",        // perfil fijo único (ver "Identidad" abajo)
    "tripId": "abc123 | null",            // null en el primer mensaje
    "messages": [                          // historial COMPLETO, Flutter lo mantiene y lo reenvía
      { "role": "user", "content": "..." },
      { "role": "assistant", "content": "..." }
    ]
  }
  // response
  {
    "reply": "texto del agente para mostrar en el chat",
    "tripId": "abc123",                   // SIEMPRE devuelto (nuevo o existente)
    "itinerarySaved": true,               // true cuando el agente llamó save_itinerary este turno
    "error": null
  }
  ```
  > Por qué el historial completo: Claude API es *stateless*. Ver `04-auditoria.md` #5 y #6.
  > El backend escribe `profileId` en el doc `trips` (lo toma del request, **no** del modelo).
  > El doc `trips` gana un campo top-level `"profileId": "string"`.

- **1.3 — Schema de los tools** (`search_places`, `save_itinerary`): copiar los `input_schema` de
  `ai-agent-design.md` a un JSON compartido en `functions/` y usarlo como fuente de verdad.
  Confirmar qué campos devuelve `search_places` (name, address, lat, lng, rating, photoUrl, category).

- **1.4 — Seed de Firestore** (`trips/demo-seed`): crear **a mano** en la consola de Firestore un
  documento `trips` completo, con 2–3 días y 3–4 actividades con `photoUrl` real y
  `profileId: "voyanties-demo"`.
  **Esto es lo que desbloquea a Squad B**: pueden construir todo el timeline visual leyendo este doc,
  sin esperar a que el backend funcione. Además es el **escenario de respaldo** para el pitch en vivo.

**Salida de FASE 1:** modelos compilando, contrato escrito en este doc / en el repo, `trips/demo-seed` visible en Firestore.

### Identidad y "no romperse al recargar"  *(decisión tomada — opción 1: perfil fijo, sin auth)*

**No hay auth. No hay perfiles todavía.** Hay **un solo perfil**, con un ID fijo inventado una vez
y hardcodeado: constante `PROFILE_ID = "voyanties-demo"` en `lib/core/config.dart`. Al estar en el
código fuente, **cada reload usa el mismo ID** sin depender de memoria ni de `localStorage`.
Todo `trip` que crea el backend lleva ese `profileId`.

- **La app siempre muestra el viaje de la base de datos.** `TripRepository.watchCurrentTrip()` =
  `trips.where('profileId', == PROFILE_ID).orderBy('updatedAt', desc).limit(1)`. Recargar la página
  re-corre la query y el itinerario reaparece — no importa que el `tripId` en memoria se haya perdido.
  Requiere un **índice compuesto** `profileId + updatedAt` (Firestore da el link para crearlo la 1ª vez).
  - Variante aún más simple si se quiere: sin `where`, solo `orderBy('updatedAt', desc).limit(1)` →
    "el último viaje que exista". El `PROFILE_ID` no cuesta nada y deja la puerta abierta a Fase 2.
- **Continuidad del chat (opcional, ~15 min):** persistir `{tripId, messages}` en `localStorage` en
  cada turno y restaurarlo al abrir. Sin esto, recargar **durante el diagnóstico** (antes del primer
  guardado) pierde la conversación — aceptable para el demo, el itinerario ya guardado no se pierde.
- Todos los que abran la app deployada comparten ese perfil → ven el mismo "viaje actual".
  "Mis viajes" (varios) + auth real = Fase 2.

---

## A partir de aquí: 3 TRACKS EN PARALELO

`TRACK A`, `TRACK B` y `TRACK C` son **independientes** y no comparten archivos.
Convergen en FASE 2.

---

## TRACK A — Backend del agente
**Squad A · rama `feature/agent` · depende de: 0.D.3, 1.2, 1.3**

| Paso | Qué | Depende de | Paralelo con |
|---|---|---|---|
| **A1** | Proxy base: Express en la Cloud Function, `POST /chat`. Reenvía a Claude API (Messages API, **`claude-opus-5`**), devuelve `reply`. API keys **solo** en env vars de la función. | A0.D.3 | — |
| **A2** | Loop de tools (manual agentic loop): `while stop_reason == "tool_use"` → ejecutar tool → devolver `tool_result` → repetir hasta `end_turn`. Tope de seguridad (~8 iteraciones). | A1 | — |
| **A3** | `search_places`: Google Places **Text Search** + construir la URL de la foto en el backend. Devolver `{name, address, lat, lng, rating, photoUrl, category}`. | A2 | **A4** |
| **A4** | `save_itinerary`: upsert a la colección `trips` (Firebase Admin SDK). Generar `tripId` si falta, devolverlo, setear `itinerarySaved: true`. Escribir `profileId` (del request) y `updatedAt` (server timestamp) en el doc. | A2 | **A3** |
| **A5** | System prompt (de `ai-agent-design.md`) + persistir `conversationContext` en el doc para poder reanudar ediciones tras recarga. Instruir al agente a **siempre** incluir flights / accommodation / budget. | A2 | — |
| **A6** | Config de la función: **timeout 300s, memoria 512MB**. Manejo de errores (429 / 5xx de Claude) → respuesta degradada, nunca crash. | A1 | — |

**Paralelo dentro del track:** A3 ∥ A4 (una persona cada uno) una vez que A2 existe.

---

## TRACK B — Flutter UI
**Squad B · rama `feature/ui` · depende de: 0.C, 1.1 · el timeline usa el seed 1.4**

| Paso | Qué | Depende de | Paralelo con |
|---|---|---|---|
| **B1** | App shell: `ProviderScope`, tema *aesthetic* del timeline (`core/theme/`), navegación chat ↔ itinerario. | 0.C.3 | — |
| **B2** | `chat_agent`: `ChatRepository.sendMessage(...)` → `ApiClient` a la función; `ChatNotifier extends Notifier<ChatState>` (mensajes, loading, `tripId`); `ChatScreen` (burbujas + input; loading/error como `AsyncValue`). | B1, 1.1, 1.2 | **B3** |
| **B3** | `itinerary_view`: `TripRepository` con `watchTrip(tripId)` **y** `watchCurrentTrip()` (query `profileId == PROFILE_ID` ordenada por `updatedAt` desc, limit 1) → `StreamProvider`; `ItineraryScreen` (header con resumen + días); `TimelineDay`; `ActivityCard` (foto con `cached_network_image`, hora, título, descripción, costo, tip). **Construir contra `trips/demo-seed`.** | B1, 1.1, 1.4 | **B2** |
| **B4** | Wire chat → itinerario: cuando `ChatResponse.itinerarySaved == true`, navegar / mostrar link a `itinerary_view` con el `tripId`. | B2, B3 | — |
| **B5** | Pulido visual del timeline (pantalla completa / proyector). Se solapa con FASE 3. | B3 | — |

**Paralelo dentro del track:** B2 ∥ B3 (una persona cada uno) — es la división natural de Squad B.
B3 no necesita nada del backend gracias al seed.

---

## TRACK C — Producto, pitch y QA
**Squad C · sin código · desde T+0 · independiente hasta FASE 2**

| Paso | Qué | Depende de |
|---|---|---|
| **C1** | 2–3 escenarios de demo escritos como **guiones de chat literales** (persona, destino, presupuesto, perfil social, vibe esperado). Uno se designa "de respaldo". | — |
| **C2** | Deck de pitch: problema (30s) → demo en vivo (2–2.5 min) → visión / negocio fase 2 (30–45s). | C1 |
| **C3** | Poblar `trips/demo-seed` (de 1.4) con los datos reales de un escenario de C1 — junto con Squad B. Es el **fallback en vivo**. | 1.4, C1 |
| **C4** | QA end-to-end desde que arranca FASE 2: recorrer el flujo como usuario real, reportar bugs en lista **priorizada** (crítico / no-crítico). | FASE 2 |

---

## FASE 2 — Integración
**Equipo completo. Requiere Track A y Track B "funcionando localmente".**

1. Apuntar el `ApiClient` de Flutter a la **URL real** de la función (o al rewrite `/api/**`).
2. Correr el **Escenario 1** de Squad C de punta a punta:
   diagnóstico → propuesta → confirmación → `save_itinerary` → stream de Firestore → render del timeline.
3. Resolver **mismatches de contrato** (nombres de campos, formato de fechas, `tripId`).
4. Probar un **cambio conversacional** en vivo ("cámbiame el hotel") → upsert → el timeline se actualiza solo.
5. Shakeout: CORS, timeouts, fotos que no cargan, errores del modelo.

---

## FASE 3 — Pulido visual + endurecimiento del demo
**Equipo completo. Prioridad #1 según `CLAUDE.md`.**

- Pase estético del timeline: tipografía, espaciado, colores, `vibeTags`, hero del destino.
- Verificar **3–4 actividades con foto real** de Google Places (no placeholder).
- Prueba en **pantalla completa / proyector**.
- Escenario de respaldo ensayado y funcionando de punta a punta.
- **Solo bugs críticos.** Cero features nuevas.

---

## FASE 4 — Deploy y ensayo del pitch

1. `flutter build web` + `firebase deploy --only hosting`.
2. `firebase deploy --only functions` (versión final, con env vars).
3. 1–2 corridas del pitch + buffer.
4. **Plan B documentado:** si el backend falla en vivo, abrir el itinerario `trips/demo-seed` directo.

---

## Tabla resumen de paralelismo

| Se puede trabajar en paralelo | A partir de |
|---|---|
| Los 3 frentes de FASE 0 (cuentas ∥ toolchain ∥ scaffold de código) | T+0 |
| `TRACK A` ∥ `TRACK B` ∥ `TRACK C` | fin de FASE 1 |
| `A3` (search_places) ∥ `A4` (save_itinerary) | fin de A2 |
| `B2` (chat) ∥ `B3` (timeline) | fin de B1 |
| `TRACK C` completo ∥ todo lo demás | T+0 |

## Ruta crítica (lo que NO se puede paralelizar)

```
FASE 0 → FASE 1 → A1 → A2 → (A4 + A5) → FASE 2 → FASE 3 → FASE 4
```

Si algo se atrasa, es aquí donde duele. Track B y Track C tienen holgura;
el backend (A1→A2→A4→A5) es la cadena tensa.

---

## Git — flujo del repo

```bash
git init -b main
# (ver .gitignore: functions/node_modules/, .firebase/, .env, functions/.env, *.log)
git add -A
git commit -m "Scaffold inicial + docs de planeación"
git remote add origin <URL-del-repo>
git push -u origin main
git branch feature/agent
git branch feature/ui
```

- Una rama por track: `feature/agent` (Squad A), `feature/ui` (Squad B). Squad C trabaja en `main` (solo docs).
- Commits pequeños y frecuentes. Merge a `main` en cuanto algo funcione localmente — sin PR review formal hoy.
- Si algo rompe `main`: revertir el commit de inmediato, no debuggear sobre la rama compartida.
- Secrets (Anthropic, Google Places): **solo** en env vars de la Cloud Function. Nunca en un commit.
