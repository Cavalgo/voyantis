# feature: itinerary_view  (rama `feature/ui`)

Muestra el itinerario guardado como **timeline visual** — la pantalla que más debe brillar.
Estado: **B1 + B3 implementados** (contra `trips/demo-seed`, sin depender del backend).

## Estructura
- `data/trip_repository.dart` — `TripRepository`
  - `Stream<Trip?> watchCurrentTrip()` → `trips.where('profileId', isEqualTo: kProfileId)
    .orderBy('updatedAt', descending: true).limit(1)` (índice compuesto ya desplegado).
    Es la que usa la app al arrancar: **siempre el último viaje de la DB**, aguanta reloads.
  - `Stream<Trip?> watchTrip(String tripId)` — un trip puntual en tiempo real.
  - El doc `trips` NO guarda `tripId` (el id del doc ES el tripId) → se inyecta `doc.id` antes de `Trip.fromJson`.
- `presentation/itinerary_providers.dart` — `tripRepositoryProvider`, `currentTripProvider`
  (`StreamProvider<Trip?>`, lo usa la home), `tripByIdProvider` (`StreamProvider.family`, para el wire de B4).
- `presentation/itinerary_screen.dart` — `ConsumerWidget`; `currentTripProvider.when(loading/error/data)`
  con los 4 estados (spinner · error con reintento · "aún no hay itinerario" con CTA al chat · itinerario).
  Hero + línea de perfil + timeline de días (ordenados por `dayNumber`) + vuelos + hospedaje + presupuesto.
- `presentation/widgets/`
  - `itinerary_header.dart` — hero full-bleed: destino (Fraunces), fechas, días, grupo, presupuesto, vibe tags, status.
  - `timeline_day.dart` — sección por día (badge, tema, fecha, riel vertical, actividades).
  - `activity_card.dart` — foto arriba + hora + título + dirección + descripción + costo (`"Gratis"` si 0) + tip + `instagrammable`.
  - `place_photo.dart` — `cached_network_image` sobre `location.photoUrl`; **placeholder** degradado
    con icono por categoría + nombre del lugar cuando la URL viene vacía (lo normal en itinerarios del agente hoy).
  - `trip_extras.dart` — `FlightsSection`, `AccommodationSection`, `BudgetSection` (barra apilada + desglose). Toleran datos nulos.

## Consume
`core/models` (Trip, Summary, Day, Activity, Location, Flight, Accommodation, BudgetBreakdown),
`core/config.dart` (`kProfileId`), `core/format.dart` (fechas ISO → es, dinero), `core/theme/app_theme.dart`.

## Expone hacia afuera
`currentTripProvider` y `tripByIdProvider`. `HomeShell` (en `main.dart`) los combina con `chat_agent`:
al recibir `itinerarySaved` salta al timeline, que ya se actualiza solo vía el stream de Firestore.
Ver `phases.md` (TRACK B).
