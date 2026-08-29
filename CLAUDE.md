# CLAUDE.md

## Qué es este proyecto
Agente conversacional que diagnostica el perfil de un viajero y genera un itinerario de viaje visual y estructurado (vuelos, hospedaje, actividades día por día, presupuesto). Construido en un hackathon de ~4 horas con demo/pitch al final del día.

## Contexto de tiempo — MUY IMPORTANTE
Esto es un demo de hackathon, no producción. La prioridad #1 es **una demo funcional y visualmente pulida**, no código perfecto. Ante la duda entre "hacerlo bien" y "hacerlo funcionar hoy", elige funcionar hoy — pero sin romper la estructura de carpetas definida (eso sí importa para que 7 personas puedan trabajar en paralelo sin pisarse).

## Stack
- Flutter Web + Riverpod (sin codegen) + Clean Architecture ligera
- Firebase: Firestore + Hosting
- Cloud Function (Node/Express) como proxy hacia Claude API (tool use) y Google Places API
- Ver detalle completo en `02-technical-architecture.md`

## Estructura del repo
```
lib/
  core/            → modelos compartidos (Trip, etc), servicio de Firestore, tema/estilos
  features/
    chat_agent/     → data / domain / presentation
    itinerary_view/ → data / domain / presentation
functions/          → Cloud Function (backend del agente)
```

## Comandos clave
```bash
flutter run -d chrome          # correr en desarrollo
flutter build web              # build de producción
firebase deploy --only hosting # deploy
firebase deploy --only functions
```

## Documentos de referencia (leer el que aplique a tu squad)
- `rules.md` — convenciones de código, Riverpod, git
- `skills.md` — recetas rápidas para tareas comunes de hoy
- `flutter-architecture-features.md` — arquitectura de features + templates
- `ai-agent-design.md` — diseño del agente: fases, schema, tools, system prompt
- `02-technical-architecture.md` — schema de Firestore y flujo de datos completo

## Explícitamente fuera de alcance hoy
No implementar: autenticación real, pagos, compra de vuelos/hoteles reales, tests automatizados exhaustivos, CI/CD, soporte mobile nativo. Si algo de esto surge, es una nota para "fase 2", no una tarea de hoy.
