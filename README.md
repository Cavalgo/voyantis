# Voyantis

Agente conversacional que diagnostica el perfil de un viajero y genera un itinerario de viaje
visual y estructurado (vuelos, hospedaje, actividades día por día, presupuesto). Demo de hackathon.

## Empezar por aquí
- [`phases.md`](phases.md) — fases por dependencia + qué se paraleliza.
- [`auditoria.md`](auditoria.md) — hallazgos y decisiones.
- [`CLAUDE.md`](CLAUDE.md) — contexto para agentes / resumen del stack.
- [`mymds/rules.md`](mymds/rules.md) — convenciones y decisiones fijas.

## Stack
Flutter Web + Riverpod (sin codegen) · Firebase (Firestore + Hosting + Cloud Functions, plan Blaze) ·
Cloud Function Node 20 como proxy hacia Claude API (`claude-opus-5`, tool use) y Google Places.

## Correr
```bash
flutter pub get
flutter run -d chrome

# backend
cd functions && npm install
cp .secret.local.example .secret.local   # rellenar con las keys reales (gitignored, solo emulador)
firebase emulators:start --only functions
```
