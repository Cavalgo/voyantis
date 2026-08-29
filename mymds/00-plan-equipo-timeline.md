# Plan del día — Voyantis (Agente de Planeación de Viajes)

> El desglose por dependencias y qué se paraleliza está en `phases.md` (raíz del repo).
> Problemas conocidos y decisiones: `auditoria.md` (raíz).

**Decisiones ya tomadas:**
- Plataforma: **Flutter Web** (responsive, deploy vía Firebase Hosting, sin builds nativos)
- Datos: **Google Places API** para lugares/fotos reales; vuelos y hoteles **simulados/generados por Claude** con precios estimados realistas
- Prioridad del pitch: **itinerario visual/aesthetic** — el timeline final es lo que más debe brillar en la demo

---

## Squads (ajusten nombres reales, esto es por rol)

### Squad A — Agente & Datos (2-3 personas, perfil técnico/backend)
Responsable de: prompt del agente, tools (`search_places`, `save_itinerary`), Cloud Function que conecta Flutter ↔ Claude API, schema de Firestore, integración Google Places.
→ Ver `ai-agent-design.md` y `02-technical-architecture.md`

### Squad B — Frontend/UI (2-3 personas, técnico o con ojo de diseño)
Responsable de: pantalla de chat, pantalla de itinerario (timeline visual), responsive design, conexión a Firestore vía streams.
→ Ver `flutter-architecture-features.md`

### Squad C — Producto, Negocio & Pitch (2 personas, no necesariamente técnico)
Responsable de: business case, narrativa del pitch, 2-3 escenarios/casos de prueba realistas para el demo, QA end-to-end (probar el flujo como usuario real y reportar bugs), deck de presentación.
→ Ver `01-business-overview.md`

**Nota:** repártanse por comodidad real, no por esta división exacta — lo importante es que cada squad tenga un objetivo claro y no se pisen el trabajo.

---

## Timeline (relativo al inicio, ajusten a su hora real)

| Bloque | Qué pasa |
|---|---|
| **T+0:00 – 0:20** | Kickoff: todos leen este plan + los docs de su squad. Confirman API keys (Claude, Google Places, Firebase). |
| **T+0:20 – 0:40** | Todo el equipo junto: revisan el schema de Firestore (`02-technical-architecture.md`) y el wireframe rápido de las 2 pantallas (chat + itinerario). 15-20 min, no más. |
| **T+0:40 – 2:40** | **Desarrollo en paralelo** (bloque grande). Mini check-in de 5 min a la mitad (T+1:30) — cada squad dice en una frase qué tiene y qué le falta. |
| **T+2:40 – 3:20** | **Integración**: Squad A conecta su backend con Squad B. Prueban el flujo completo con 1-2 escenarios reales del Squad C. |
| **T+3:20 – 3:45** | Pulido visual (esto es lo que más importa hoy) + fix de bugs críticos únicamente. |
| **T+3:45 – 4:00** | Ensayo del pitch (1-2 corridas) + buffer. |

---

## Checklist de "listo para pitch"

- [ ] Se puede tener una conversación completa con el agente (diagnóstico → propuesta → confirmación)
- [ ] El itinerario final se guarda en Firestore y se ve en la pantalla de itinerario
- [ ] Al menos 3-4 actividades tienen foto real (Google Places) y no placeholder
- [ ] El timeline se ve bien en pantalla completa (laptop/proyector) — esto pesa más que tener 5 features a medias
- [ ] Hay al menos 1 escenario "de respaldo" ya probado y funcionando, por si algo falla en vivo
- [ ] El pitch tiene: problema → demo en vivo → visión de negocio/fase 2 (30 seg)

## Explícitamente fuera de alcance hoy
Auth real, pagos, compra de vuelos/hoteles reales, tests automatizados, CI/CD, soporte mobile nativo. Todo esto es "fase 2" y se menciona en el pitch como visión, no se construye hoy.
