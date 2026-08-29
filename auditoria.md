# Auditoría — Errores y discrepancias

> Revisión de los docs de planeación + el estado real del repo, hecha antes de arrancar.
> **Estado:** hallazgos reportados. En la sección **D**, las correcciones a `mymds/rules.md`,
> `mymds/skills.md` y `CLAUDE.md` **ya se aplicaron** (2026-08-29); el resto **espera autorización**.

Entorno verificado (2026-08-29): Flutter 3.47.1 / Dart 3.13.1 instalados · `node`, `firebase`,
`flutterfire` **no** instalados · repo era el scaffold `flutter create` por defecto (app contador) ·
`pubspec.yaml` sin dependencias del stack.

---

## A. Bloqueantes de setup — resolver en FASE 0

### A1 · Toolchain incompleto
`functions/` necesita **Node 20+**; el deploy necesita **Firebase CLI**; `firebase_options.dart` necesita
**FlutterFire CLI**. Ninguno está instalado. Sin esto no hay backend ni deploy.
→ FASE 0, frente 0.B.

### A2 · El repo es el scaffold por defecto
`pubspec.yaml` no tiene `flutter_riverpod`, `firebase_core`, `cloud_firestore` ni `http`.
`lib/main.dart` y `test/widget_test.dart` son el contador de `flutter create`.
→ FASE 0, frente 0.C.

### A3 · Google Places requiere billing
La Places API responde 403 si el proyecto de GCP no tiene **billing habilitado**. Bloqueo clásico de hackathon.
→ FASE 0, paso 0.A.4.

### A4 · Límite de versión de Dart
`pubspec.yaml` declara `environment: sdk: ^3.13.1` y el Dart instalado es exactamente 3.13.1.
Cualquier paquete que exija Dart > 3.13 va a fallar en `pub get`.
→ Al añadir deps (0.C.1), fijarse en las restricciones de SDK; si hace falta, subir la versión de Flutter.

### A5 · Cloud Functions requiere plan Blaze
En el plan gratuito (Spark) las Cloud Functions **no pueden hacer llamadas de red salientes** fuera de
Google — ni a `api.anthropic.com`, ni a la Places API. **Todo el backend del agente depende de esto.**
→ Upgrade a **plan Blaze** en FASE 0 (paso 0.A.1) + budget alert (~5 USD). Tier gratuito generoso;
el gasto real del demo es de centavos.

---

## B. Discrepancias y contratos sin definir entre docs — resolver en FASE 1

### B5 · Nadie es dueño del historial de conversación
`mymds/flutter-architecture-features.md` define `sendMessage(String tripId, String text)` — solo manda el
**texto nuevo**. Pero Claude API es **stateless**: no recuerda los turnos anteriores. Ningún doc dice
quién guarda el historial ni cómo se reconstruye.
→ **Decisión:** Flutter mantiene la lista completa de mensajes en `ChatState` y la reenvía entera en
cada request (`messages: [{role, content}, ...]`). El backend antepone el system prompt.
→ Afecta la firma de `sendMessage` y el contrato HTTP (ver 1.2 en `phases.md`).

### B6 · El `tripId` recién creado no vuelve a Flutter
El flujo de `mymds/02-technical-architecture.md` termina en "Cloud Function devuelve la respuesta del agente
a Flutter", pero **no** dice que devuelva el `tripId` que `save_itinerary` acaba de generar.
`ChatNotifier` lo necesita ("`tripId` actual — null hasta que se crea el primer draft") para poder
suscribirse a `watchTrip(tripId)` y mostrar el itinerario.
→ **Decisión:** `ChatResponse` siempre incluye `tripId` y un flag `itinerarySaved`.

### B7 · Vocabulario inconsistente: trip vs itinerary
Colección Firestore = `trips`; tool = `save_itinerary`; modelo Dart = `Trip`; feature = `itinerary_view`.
No es un bug, pero conviene fijar "**trip = itinerario**" y no introducir una colección `itineraries` por error.

### B8 · Identidad del "dueño" de un viaje — DECIDIDO: perfil fijo, sin auth
`mymds/rules.md` y `CLAUDE.md` dicen "Auth anónimo o usuario fijo"; el diseño no define cómo un usuario
vuelve a su viaje tras recargar (el `tripId` vive solo en memoria de Flutter). En Flutter **Web no
existe un device-id confiable**.
→ **Decisión (opción 1):** **sin auth**. Un **perfil fijo único** — constante `PROFILE_ID` en
`lib/core/config.dart` (ej. `"voyantis-demo"`). Todo `trip` lleva `profileId`. Al recargar, el
itinerario se recupera con `trips.where(profileId == PROFILE_ID).orderBy(updatedAt desc).limit(1)`.
Opcional: `localStorage` para la continuidad del chat durante la fase de diagnóstico.
→ **Impacto:** `ChatRequest` gana `profileId`; el doc `trips` gana `profileId` (top-level, lo escribe
el **backend**, no el modelo); hace falta un índice compuesto Firestore `profileId + updatedAt`.
→ Auth real + "mis viajes" (varios) = Fase 2. Detalle en `phases.md` § "Identidad y no romperse al recargar".

### B9 · `save_itinerary` no obliga a flights / accommodation / budget
El `input_schema` del tool tiene `required: ["summary", "days"]`. `flights`, `accommodation` y
`budgetBreakdown` son opcionales. Pero `mymds/01-business-overview.md` promete "vuelos, hospedaje, actividades
día por día y presupuesto estimado" y el header del itinerario (`itinerary_screen`) muestra el presupuesto total.
→ **Decisión:** el system prompt instruye al agente a **incluir siempre** los 4 bloques; la UI debe
tolerar que falten (no crashear si `flights == null`).

### B10 · La URL de foto de Google Places expone la API key en el cliente
`mymds/02-technical-architecture.md` construye la URL de foto como
`.../place/photo?...&key={API_KEY}` **en el backend**, y guarda esa URL en `location.photoUrl`.
Esa URL se guarda en Firestore y la renderiza el navegador → **la key de Places viaja al cliente**
dentro de la URL de la imagen. `mymds/rules.md` ("nunca en código Flutter, nunca en un commit") se cumple
literalmente (no está en el código ni en un commit), pero la key sí queda expuesta en la red.
→ **Decisión para el demo:** una sola key restringida a la **Places API** (no se puede restringir por
IP — Cloud Functions gen 2 no tiene IP fija) + **budget alert** bajo en GCP. La exposición vía URL de
foto es tolerable para el hackathon. Alternativa limpia si sobra tiempo: endpoint proxy
`/api/photo?ref=...` en la función (la key nunca llega al cliente), o una 2ª key solo-fotos restringida
por referrer HTTP al dominio de Hosting.

### B11 · Formato de la Places Photo API: legacy vs new
`mymds/02-technical-architecture.md` usa el endpoint **legacy**:
`https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference={ref}&key={KEY}`.
La "**Places API (New)**" usa otro endpoint y otro formato de referencia:
`https://places.googleapis.com/v1/{photo_name}/media?maxWidthPx=800&key={KEY}`.
Además, "Text Search" tiene versión legacy y nueva, con respuestas distintas.
→ **Decisión:** habilitar la **"Places API"** (legacy) y que `search_places` use Text Search legacy +
Photo legacy, para que coincida con el doc. Si se elige la nueva, actualizar **ambos** (search y photo).

### B12 · CORS no está contemplado
Flutter Web servido desde Hosting llamando a una Cloud Function es **cross-origin**. Ningún doc lo menciona.
Sin manejo, el navegador bloquea la llamada.
→ **Decisión:** rewrite `"/api/**"` → función en `firebase.json` (Flutter llama a `/api/chat`, mismo
origen, **sin CORS**). Alternativa: middleware `cors` en Express con allowlist del dominio de Hosting + `localhost`.

### B13 · Timeout de la Cloud Function
El loop del agente = llamada a Claude + 2–3 round trips de tools + llamadas a Places. Puede pasar
fácilmente los **60s** de timeout por defecto de las Cloud Functions.
→ **Decisión:** `timeoutSeconds: 300`, `memory: 512MiB` (o más) en la config de la función.

### B14 · Reanudar una edición tras recargar la página
`mymds/ai-agent-design.md` Fase 3: "el usuario vuelve y pide algo distinto". Tras un reload, la lista de
mensajes que Flutter tenía en memoria **se pierde**. El agente necesita contexto para editar bien.
→ **Decisión:** el campo `conversationContext` del doc `trips` (que el agente mantiene) es el mecanismo.
Al reabrir un `tripId` existente sin historial local, Flutter manda `{tripId, messages: [<nuevo mensaje>]}`
y el backend carga `conversationContext` del doc y lo inyecta como contexto.

---

## C. Menores / limpieza

| # | Hallazgo | Acción sugerida |
|---|---|---|
| C15 | `mymds/01-business-overview.md` dice "[Nombre del Proyecto]" y lista opciones de nombre. El nombre es **Voyantis** (repo `voyantis`; la carpeta local `voyanties` es un typo). | Fijar "**Voyantis**", quitar la lista. |
| C16 | `test/widget_test.dart` prueba el contador → romperá `flutter analyze` / `flutter test` al reescribir `main.dart`. `mymds/rules.md` dice sin tests hoy. | Borrarlo o dejar un stub trivial. |
| C17 | `README.md` y `pubspec.yaml` (`description:`) siguen en "A new Flutter project". | Actualizar con una línea real del proyecto. |
| C18 | `mymds/rules.md` propone ramas `feature/agente`, `feature/ui`, `feature/datos`. Squad A cubre "Agente & Datos" → `feature/agente` y `feature/datos` son el mismo squad, se solapan. | Alinear a `feature/agent` + `feature/ui`; Squad C trabaja en `main` (solo docs). |
| C19 | `mymds/flutter-architecture-features.md` marca `domain/` como "opcional"; `mymds/skills.md` receta 1 dice crearla siempre. | Menor: dejar `domain/` vacía u omitirla. No bloquea. |
| C20 | Ningún doc fija el modelo de Claude. | **Decidido: `claude-opus-5`.** |
| C21 | El scaffold trae `android/ ios/ macos/ linux/ windows/`; el proyecto es solo Web. | Opcional: dejarlos (ruido inofensivo) o borrarlos. No bloquea. |

---

## D. Plan de corrección de los otros docs

**Ya aplicado (2026-08-29):** D.2 `mymds/rules.md`, D.6 `CLAUDE.md`, y D.8 `mymds/skills.md`.
**Pendiente de autorización:** D.1, D.3, D.4, D.5, D.7.
Los cambios al código (C16, C17, A2) son parte de FASE 0.

### D.1 · `mymds/01-business-overview.md`  *(resuelve C15)* — PENDIENTE
- Título: `# Business Overview — [Nombre del Proyecto]` → `# Business Overview — Voyantis`.
- Borrar la línea de "*Ideas de nombre (opcionales...)*".

### D.2 · `mymds/rules.md`  *(resuelve C18, B8)* — ✅ APLICADO
- Ramas alineadas a `feature/agent` / `feature/ui`; Squad C en `main`.
- "Qué NO hacer": Auth fuera; perfil fijo `PROFILE_ID`.
- "Secrets": `functions/.env` local + `firebase functions:secrets:set` para deploy.
- Añadidas secciones de contrato del backend, fechas ISO, y config de la Cloud Function.

### D.3 · `mymds/02-technical-architecture.md`  *(resuelve B8, B10, B11, B12, B13, A5)* — PENDIENTE
- En "Google Places — nota técnica": aclarar que se usa la **Places API legacy** (Text Search + Photo),
  y añadir la advertencia de que la URL de foto lleva la key → restringir la key a la Places API +
  budget alert (o proxear por la función).
- Nueva subsección "Cloud Function — config": **plan Blaze obligatorio** (sin él no hay egress a
  Claude/Places); rewrite `/api/**` en `firebase.json` para evitar CORS; `timeoutSeconds: 300`,
  `memory: 512MiB`; secrets vía `defineSecret` + Secret Manager.
- En el schema de `trips`: añadir `profileId: string` (top-level) y `updatedAt`; fijar la convención de
  fechas (ISO string vs `Timestamp`); nota del índice compuesto `profileId + updatedAt`.

### D.4 · `mymds/ai-agent-design.md`  *(resuelve B5, B6, B9, B14)* — PENDIENTE
- En "Tools": documentar que la Cloud Function recibe `{profileId, tripId?, messages[]}` y devuelve
  `{reply, tripId, itinerarySaved, error?}`; el backend inyecta `profileId` en el doc, el modelo no lo ve.
- En el esqueleto del system prompt: añadir "incluye **siempre** vuelos, hospedaje y desglose de
  presupuesto en `save_itinerary`, aunque sean estimaciones".
- En "Fase 3 — Guardado y edición": describir el caso "resume" vía `conversationContext`.

### D.5 · `mymds/flutter-architecture-features.md`  *(resuelve B5)* — PENDIENTE
- `chat_repository.dart`: cambiar la firma de
  `sendMessage(String tripId, String text) → Future<ChatResponse>` a
  `sendMessage({String? tripId, required List<ChatMessage> messages}) → Future<ChatResponse>`.
- `chat_notifier.dart`: notar que `ChatState` guarda la lista completa de mensajes y es lo que se reenvía.

### D.6 · `CLAUDE.md`  *(resuelve A1, A5, C20)* — ✅ APLICADO
- Modelo `claude-opus-5` fijado. Sección "Prerequisitos" (Node 20+, Firebase/FlutterFire CLI, plan Blaze).
- Sección "Decisiones ya tomadas" (perfil fijo, historial completo, `/api/**`, fechas ISO).
- Punteros a `phases.md` y `auditoria.md`; rutas de `mymds/` corregidas.

### D.7 · `mymds/00-plan-equipo-timeline.md`  *(alineación con `phases.md`)* — PENDIENTE
- Añadir una línea al inicio: "El desglose por dependencias y qué se paraleliza está en `phases.md` (raíz del repo)".

### D.8 · `mymds/skills.md` — ✅ APLICADO
- Receta 3 (tool call) reescrita con el loop manual real + `claude-opus-5` + `defineSecret`.
- Nuevas recetas: secrets de la Cloud Function, contrato chat, recuperar "viaje actual" sin auth, deploy.
