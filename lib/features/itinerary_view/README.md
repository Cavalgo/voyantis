# feature: itinerary_view  (rama `feature/ui`)

Muestra el itinerario guardado como **timeline visual** — la pantalla que más debe brillar.

## Estructura
- `data/trip_repository.dart` — `TripRepository`
  - `Stream<Trip?> watchCurrentTrip()` → `trips.where('profileId', isEqualTo: kProfileId)
    .orderBy('updatedAt', descending: true).limit(1)` (índice compuesto ya desplegado).
    Es la que usa la app al arrancar: **siempre el último viaje de la DB**, aguanta reloads.
  - `Stream<Trip?> watchTrip(String tripId)` — un trip puntual.
  - El doc `trips` NO guarda `tripId` (el id del doc ES el tripId) → se inyecta `doc.id` antes de `Trip.fromJson`.
- `presentation/itinerary_providers.dart` — `currentTripProvider` (StreamProvider), `tripByIdProvider` (family).
- `presentation/itinerary_screen.dart` — maneja `AsyncValue` (loading/error/data) + estado vacío.
  Header hero + línea de perfil + timeline de días + vuelos + hospedaje + presupuesto.
- `presentation/widgets/`
  - `itinerary_header.dart` — hero (destino, fechas, presupuesto, vibe tags, status).
  - `timeline_day.dart` — sección por día (badge, tema, riel vertical, actividades).
  - `activity_card.dart` — foto + hora + título + dirección + descripción + costo + tip.
  - `place_photo.dart` — `cached_network_image` sobre `location.photoUrl`; **placeholder**
    degradado con icono por categoría cuando la URL viene vacía (lo normal hoy).
  - `trip_extras.dart` — `FlightsSection`, `AccommodationSection`, `BudgetSection` (barras). Toleran datos nulos.

Construir contra `trips/demo-seed` (seed de FASE 1.4) sin esperar al backend.
Consume: `core/models` (Trip, Day, Activity…), `core/config.dart`, `core/format.dart`. Ver `phases.md` (TRACK B).
