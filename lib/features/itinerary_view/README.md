# feature: itinerary_view  (rama `feature/ui`)

Muestra el itinerario guardado como **timeline visual** — la pantalla que más debe brillar.

- `data/trip_repository.dart` —
  - `Stream<Trip> watchTrip(String tripId)`
  - `Stream<Trip?> watchCurrentTrip()` → `trips.where('profileId', isEqualTo: kProfileId)
    .orderBy('updatedAt', descending: true).limit(1)` (índice compuesto ya desplegado).
    Esta es la que usa la app al arrancar: **siempre muestra el último viaje de la DB**, aguanta reloads.
- `presentation/itinerary_screen.dart` — header (destino, fechas, presupuesto, vibe tags) + días.
- `presentation/widgets/timeline_day.dart` — sección por día.
- `presentation/widgets/activity_card.dart` — foto (`cached_network_image` sobre `location.photoUrl`),
  hora, título, descripción, costo, tip. Un solo widget parametrizado.

Construir contra `trips/demo-seed` (seed de FASE 1.4) sin esperar al backend.
Consume: `core/models` (Trip, Day, Activity…), `core/config.dart`. Ver `phases.md` (TRACK B).
