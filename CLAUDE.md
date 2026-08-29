# CLAUDE.md

## Qué es este proyecto
Agente conversacional que diagnostica el perfil de un viajero y genera un itinerario de viaje visual
y estructurado (vuelos, hospedaje, actividades día por día, presupuesto). Construido en un hackathon
de ~4 horas con demo/pitch al final del día. Nombre: **Voyantis**.

## Contexto de tiempo — MUY IMPORTANTE
Esto es un demo de hackathon, no producción. La prioridad #1 es **una demo funcional y visualmente
pulida**, no código perfecto. Ante la duda entre "hacerlo bien" y "hacerlo funcionar hoy", elige
funcionar hoy — pero sin romper la estructura de carpetas definida (eso sí importa para que 7 personas
trabajen en paralelo sin pisarse).

## Empezar por aquí
- `phases.md` (raíz) — fases por dependencia + qué se paraleliza. **Léelo primero.**
- `auditoria.md` (raíz) — errores/discrepancias detectadas y decisiones. Léelo antes de tocar código.
- `mymds/rules.md` — convenciones de código, Riverpod, git, secrets, decisiones fijas.

## Stack
- Flutter Web + Riverpod (sin codegen) + Clean Architecture ligera
- Firebase: Firestore + Hosting + Cloud Functions (**plan Blaze** — sin él la función no tiene egress)
- Cloud Function (Node 20, Functions v2, Express) como proxy hacia Claude API (`claude-opus-5`, tool use) y Google Places API
- Detalle completo en `mymds/02-technical-architecture.md`

## Prerequisitos (instalar en FASE 0)
Node 20+ · Firebase CLI · FlutterFire CLI · proyecto Firebase en **plan Blaze** con budget alert.
Flutter ya está (3.47.1 / Dart 3.13.1).

## Decisiones ya tomadas (no re-discutir — ver `mymds/rules.md`)
- **Sin Auth.** Perfil fijo `PROFILE_ID = "voyantis-demo"` en `lib/core/config.dart`; la app muestra
  siempre el último `trip` de la DB con ese `profileId`.
- El chat reenvía el **historial completo** de mensajes en cada request (Claude API es stateless).
- Flutter llama a `/api/**` (rewrite de Hosting), nunca a la URL cruda de la función (CORS).
- Fechas siempre ISO 8601 string.

## Estructura del repo
```
lib/
  core/
    config.dart      → PROFILE_ID y constantes globales
    models/          → FASE 1 congelada: trip.dart, traveler_profile.dart, summary.dart, flight.dart,
                       accommodation.dart, day.dart, activity.dart, location.dart, budget_breakdown.dart,
                       chat_message/request/response.dart · models.dart (barrel) · parsing.dart (helpers)
    services/        → FirestoreService, ApiClient (Cloud Function)
    theme/           → estilos del timeline aesthetic
  features/
    chat_agent/      → data / domain / presentation   (rama feature/ui)
    itinerary_view/  → data / domain / presentation   (rama feature/ui)
functions/           → Cloud Function del agente        (rama feature/agent)
  index.js           → handler POST /chat (llama al agente, degrada errores) + GET /tools; onRequest 300s
  agent.js           → TRACK A: SYSTEM_PROMPT + runAgent() (loop manual de tool use) + save_itinerary
  tools.js           → FASE 1: input_schema de search_places / save_itinerary (fuente de verdad compartida)
  .secret.local.example → plantilla de keys (los valores van en .secret.local — solo emulador, gitignored)
scripts/
  seed_firestore.mjs → escribe trips/demo-seed (seed de FASE 1.4 + fallback del pitch)
  chat_smoke.mjs     → prueba end-to-end de /api/chat (guion de chat + verifica el doc en Firestore)
```

## Comandos clave
```bash
flutter run -d chrome                       # desarrollo
flutter build web                           # build de producción
firebase deploy --only hosting
firebase deploy --only functions            # función `api` ya deployada
firebase functions:secrets:set ANTHROPIC_API_KEY   # ya hecho (y GOOGLE_PLACES_API_KEY)
firebase emulators:start                    # Firestore + Functions locales (opcional)
```

## Documentos de referencia (leer el que aplique a tu squad)
- `mymds/skills.md` — recetas rápidas para tareas comunes de hoy
- `mymds/flutter-architecture-features.md` — arquitectura de features + templates
- `mymds/ai-agent-design.md` — diseño del agente: fases, schema, tools, system prompt
- `mymds/02-technical-architecture.md` — schema de Firestore y flujo de datos completo
- `mymds/01-business-overview.md` — business case y narrativa del pitch
- `mymds/00-plan-equipo-timeline.md` — reloj del día y squads

## Explícitamente fuera de alcance hoy
No implementar: autenticación (ni anónima), pagos, compra de vuelos/hoteles reales, tests automatizados
exhaustivos, CI/CD, soporte mobile nativo. Si algo de esto surge, es nota para "fase 2", no tarea de hoy.
