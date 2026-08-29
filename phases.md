# Fases de Desarrollo — Voyantis

> Este documento ordena el trabajo por **dependencias** y marca qué se puede hacer **en paralelo**.
> Complementa a `mymds/00-plan-equipo-timeline.md` (que da el reloj del día); aquí está el grafo de
> qué bloquea a qué. Antes de tocar código, lee también `auditoria.md`.

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

## FASE 0 — Fundaciones y setup — ✅ CERRADA (2026-08-29)

> Todo hecho. Lo que sigue es FASE 1 (contratos) y los tracks.
> Estado: repo en GitHub (3 ramas) · Firebase `mi-viaje-11d84` (Blaze) · Firestore + reglas + índice
> `trips` desplegados · Places API habilitada · keys en `functions/.secret.local` + Secret Manager ·
> deps de Flutter (`flutter analyze` + `flutter test` limpios) · `functions/` con esqueleto **deployado**
> (`https://us-central1-mi-viaje-11d84.cloudfunctions.net/api`, devuelve 501 hasta que Track A lo implemente) ·
> árbol de carpetas `lib/` creado · scaffold del contador eliminado (shell base con tema en `lib/main.dart`).

Se dividió en 3 frentes que corrieron **en paralelo**:

### Frente 0.A — Cuentas, servicios y API keys — ✅ hecho
- [x] **0.A.1** Proyecto Firebase `mi-viaje-11d84` en **plan Blaze**. `firebase login` = cavalgo01@gmail.com.
- [x] **0.A.2** Firestore creado. Reglas abiertas hasta **2026-09-28** (`firestore.rules`, desplegado).
      Índice compuesto `trips (profileId ASC, updatedAt DESC)` desplegado (`firestore.indexes.json`).
- [x] **0.A.4** `flutterfire configure` → `lib/firebase_options.dart` (commiteado; su Web API key es pública).
- [x] **0.A.5** API key de Anthropic → `functions/.secret.local` + Secret Manager (`ANTHROPIC_API_KEY`).
- [x] **0.A.6** API key de Google Places → `functions/.secret.local` + Secret Manager (`GOOGLE_PLACES_API_KEY`).
- [x] **Places API habilitada** en GCP. La URL de foto lleva la key (ver `auditoria.md` B10) —
      *hardening opcional, no blocker:* restringir la key a "Places API" en GCP Console.
- [x] **0.A.8** `functions/.secret.local` (gitignored) + `functions/.secret.local.example` (commiteado). Secrets de deploy
      seteados. Verificado: ninguna key en el historial de git.

### Frente 0.B — Toolchain local — ✅ hecho
Node 24 · npm 11 · Firebase CLI 15.28.2 · FlutterFire CLI 1.4.1 · Flutter 3.47.1 / Dart 3.13.1.

### Frente 0.C — Scaffold de código — ✅ hecho
- [x] **0.C.1** Deps en `pubspec.yaml` (`flutter_riverpod`, `firebase_core`, `cloud_firestore`, `http`,
      `google_fonts`, `cached_network_image`, `intl`). `flutter analyze` + `flutter test` limpios.
- [x] **functions/**: `package.json` (Node 22) + `index.js` (esqueleto: `/chat`, `defineSecret`, 300s/512MiB),
      `.secret.local` local, `.secret.local.example`. `npm install` hecho.
- [x] **0.C.2** Árbol `lib/core/{config.dart, models, services, theme/app_theme.dart}` +
      `lib/features/{chat_agent,itinerary_view}/{data,domain,presentation/widgets}` (cada feature con su README).
- [x] **0.C.3** `lib/main.dart` → `ProviderScope` + `MaterialApp` + tema + shell placeholder (contador fuera);
      `test/widget_test.dart` = smoke test; `README.md` + `description:` de pubspec actualizados.

### Cierre de FASE 0 — ✅ hecho
- [x] **0.D.1** git + remoto GitHub + push. **0.D.2** ramas `feature/agent` / `feature/ui`.
- [x] **0.D.4** `firebase.json` con rewrite `"/api/**" → api` (+ SPA fallback, functions, firestore, emuladores).
- [x] **0.D.3** `firebase deploy --only functions` → **`api` deployada** (Node 22, us-central1).
      Smoke test OK: POST válido → 501 `not_implemented`; POST vacío → 400. Track A la implementa.

**Salida de FASE 0:** ✅ repo vivo, deps listas, infra Firebase lista, función deployada.

---

## FASE 1 — Contratos y modelos — ✅ CERRADA (2026-08-29) · en `main`
**Bloqueante para la integración. ~30 min. 1 persona de Squad A + 1 de Squad B, juntas.**

Todo lo de esta fase se **congela** y no se re-discute durante el bloque de desarrollo.

> **Estado:** todo en `main` (ramas `feature/agent` / `feature/ui` sincronizadas).
> - **1.1** Modelos Dart planos (sin codegen) en `lib/core/models/` — un archivo por modelo +
>   `models.dart` (barrel) + `parsing.dart` (helpers tolerantes). `fromJson`/`toJson` alineados al
>   schema de `trips`; fechas de contenido = String ISO, `createdAt`/`updatedAt` = `DateTime`
>   (tolera `Timestamp` de Firestore). `flutter analyze` limpio.
> - **1.2** Contrato HTTP: `ChatMessage` / `ChatRequest` / `ChatResponse` en `lib/core/models/`,
>   cuadran con `functions/index.js`.
> - **1.3** `functions/tools.js` = fuente de verdad de los `input_schema` de `search_places` y
>   `save_itinerary` (sub-objetos expandidos desde `02-technical-architecture.md`). `index.js` lo
>   importa; `GET /api/tools` los expone para inspección.
> - **1.4** Seed `trips/demo-seed` **escrito y visible en Firestore** (Oaxaca, 3 días × 3 actividades,
>   fotos Unsplash reales, `profileId: voyantis-demo`, `updatedAt` server timestamp). Script
>   reproducible: `node scripts/seed_firestore.mjs`.
> - **Verificación:** `flutter analyze` limpio · `test/models_roundtrip_test.dart` (9 casos, incl.
>   round-trip idempotente y tolerancia a campos ausentes) · doc visible en la consola de Firestore.

- **1.1 — Modelos Dart** (`lib/core/models/`): `Trip`, `TravelerProfile`, `Summary`, `Flight`,
  `Accommodation`, `Day`, `Activity`, `Location`, `BudgetBreakdown`.
  Cada uno con `fromJson` / `toJson` **exactamente** alineados al schema de `mymds/02-technical-architecture.md`.
  Fechas de contenido (startDate, checkIn, activity date…) = **ISO 8601 string**; `createdAt`/`updatedAt` = `Timestamp`.

- **1.2 — Contrato HTTP** Cloud Function ↔ Flutter (congelar los nombres de campos):
  ```jsonc
  // POST /api/chat  — request
  {
    "profileId": "voyantis-demo",        // perfil fijo único (ver "Identidad" abajo)
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
  > Por qué el historial completo: Claude API es *stateless*. Ver `auditoria.md` #5 y #6.
  > El backend escribe `profileId` en el doc `trips` (lo toma del request, **no** del modelo).
  > El doc `trips` gana un campo top-level `"profileId": "string"`.

- **1.3 — Schema de los tools** (`search_places`, `save_itinerary`): copiar los `input_schema` de
  `mymds/ai-agent-design.md` a un JSON compartido en `functions/` y usarlo como fuente de verdad.
  Confirmar qué campos devuelve `search_places` (name, address, lat, lng, rating, photoUrl, category).

- **1.4 — Seed de Firestore** (`trips/demo-seed`): crear **a mano** en la consola de Firestore un
  documento `trips` completo, con 2–3 días y 3–4 actividades con `photoUrl` real y
  `profileId: "voyantis-demo"`.
  **Esto es lo que desbloquea a Squad B**: pueden construir todo el timeline visual leyendo este doc,
  sin esperar a que el backend funcione. Además es el **escenario de respaldo** para el pitch en vivo.

**Salida de FASE 1:** modelos compilando, contrato escrito en este doc / en el repo, `trips/demo-seed` visible en Firestore.

### Identidad y "no romperse al recargar"  *(decisión tomada — opción 1: perfil fijo, sin auth)*

**No hay auth. No hay perfiles todavía.** Hay **un solo perfil**, con un ID fijo inventado una vez
y hardcodeado: constante `PROFILE_ID = "voyantis-demo"` en `lib/core/config.dart`. Al estar en el
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
**Squad A · rama `feature/agent` · depende de: 1.2, 1.3**

> **Pasada 1 hecha (2026-08-29):** `/api/chat` funciona end-to-end. `functions/agent.js` tiene el
> `SYSTEM_PROMPT` y `runAgent()` (loop manual de tool use, `claude-opus-5`, `effort: medium`,
> `max_tokens: 32000` vía streaming interno — sin SSE al cliente —, tope 8 iteraciones);
> `functions/index.js` llama al agente, carga `conversationContext` del doc si viene
> `tripId` (reanudar edición) y degrada errores a `200` con `error` en vez de crashear. La tool
> `save_itinerary` hace upsert a `trips` con `profileId` + `updatedAt`/`createdAt` serverTimestamp y
> devuelve el `tripId`. Probado con `node scripts/chat_smoke.mjs` (crea) y `--edit <tripId>`
> (actualiza el mismo doc). **Falta:** A3 `search_places` (el agente deja `photoUrl: ""`), reintentos
> explícitos, reinyectar el itinerario completo al editar.
> Checklist abajo: **A1 ✅ · A2 ✅ · A4 ✅ · A5 ✅(parcial) · A6 ✅(parcial) · A3 ⬜**.

Punto de partida original: `functions/index.js` tenía el esqueleto (devolvía `501`).
Recetas: `mymds/skills.md` 4–6.

| Paso | Qué | Depende de | Paralelo con |
|---|---|---|---|
| **A1** | Rellenar `/chat`: reenviar a Claude API (Messages API, **`claude-opus-5`**), devolver `reply`. Leer las keys de `ANTHROPIC_API_KEY.value()` / `GOOGLE_PLACES_API_KEY.value()`. | esqueleto | — |
| **A2** | Loop de tools (manual agentic loop): `while stop_reason == "tool_use"` → ejecutar tool → devolver `tool_result` → repetir hasta `end_turn`. Tope de seguridad (~8 iteraciones). | A1 | — |
| **A3** | `search_places`: Google Places **Text Search** (legacy) + construir la URL de la foto en el backend. Devolver `{name, address, lat, lng, rating, photoUrl, category}`. | A2 | **A4** |
| **A4** | `save_itinerary`: upsert a la colección `trips` (Firebase Admin SDK, ya inicializado en el esqueleto). Generar `tripId` si falta, devolverlo, setear `itinerarySaved: true`. Escribir `profileId` (del request) y `updatedAt` (`FieldValue.serverTimestamp()`) en el doc. | A2 | **A3** |
| **A5** | System prompt (de `mymds/ai-agent-design.md`) + persistir `conversationContext` en el doc para poder reanudar ediciones tras recarga. Instruir al agente a **siempre** incluir flights / accommodation / budget. | A2 | — |
| **A6** | Manejo de errores (429 / 5xx de Claude) → respuesta degradada, nunca crash. Primer `firebase deploy --only functions` para tener la URL real. | A1 | — |

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
2. `firebase deploy --only functions` (versión final; secrets ya en Secret Manager).
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

Repo: **https://github.com/Cavalgo/voyantis** — ya inicializado, con `main`, `feature/agent` y `feature/ui`.

```bash
git clone https://github.com/Cavalgo/voyantis.git
cd voyantis
git checkout feature/agent   # Squad A   (o feature/ui — Squad B)
```

- Una rama por track: `feature/agent` (Squad A), `feature/ui` (Squad B). Squad C trabaja en `main` (solo docs).
- Commits pequeños y frecuentes. Merge a `main` en cuanto algo funcione localmente — sin PR review formal hoy.
- Si algo rompe `main`: revertir el commit de inmediato, no debuggear sobre la rama compartida.
- Secrets (Anthropic, Google Places): `functions/.secret.local` local (gitignored) + `firebase functions:secrets:set` para deploy. Nunca en un commit. Ver `mymds/rules.md` § Secrets.
