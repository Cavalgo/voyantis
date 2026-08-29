# feature: itinerary_view  (rama `feature/ui`)

Muestra el itinerario guardado como **timeline visual** — la pantalla que más debe brillar.
Estado: **B1 + B3 implementados** (contra `trips/demo-seed`, sin depender del backend).

## Archivos

- `data/trip_repository.dart`
  - `TripRepository.watchCurrentTrip()` → `trips.where('profileId', == kProfileId)
    .orderBy('updatedAt', desc).limit(1)` (índice compuesto ya desplegado). Aguanta reloads.
  - `TripRepository.watchTrip(tripId)` → un viaje puntual en tiempo real.
  - Providers: **`currentTripProvider`** (`StreamProvider<Trip?>`, lo usa la home),
    `tripByIdProvider` (`StreamProvider.family<Trip, String>`, para B4), `tripRepositoryProvider`.
- `presentation/itinerary_screen.dart` — `ConsumerWidget`; `currentTripProvider.when(loading/error/data)`;
  estados: spinner · error con reintento · "aún no hay viaje" · itinerario. FAB → ruta `/chat`
  (placeholder en `main.dart` hasta que B2 haga `chat_agent`).
- `presentation/widgets/itinerary_header.dart` — hero: destino, fechas (`prettyRange`), vibe tags,
  presupuesto total, y línea de logística (vuelos + hospedaje).
- `presentation/widgets/timeline_day.dart` — sección por día: badge + tema + fecha + riel vertical
  con las `ActivityCard`.
- `presentation/widgets/activity_card.dart` — un solo widget parametrizado: foto
  (`cached_network_image` sobre `location.photoUrl`, con fallback si viene vacía), hora, categoría,
  título, descripción, costo (`"Gratis"` si 0), tip, marca `instagrammable`.
- `presentation/widgets/budget_breakdown_card.dart` — barra apilada + leyenda del `budgetBreakdown`.
- `presentation/formatters.dart` — `prettyDate` / `prettyRange` / `money` (sin `intl`, fechas ISO).

## Consume
`core/models` (Trip, Summary, Day, Activity, Location, Flight, Accommodation, BudgetBreakdown),
`core/config.dart` (`kProfileId`), `core/theme/app_theme.dart` (`AppColors`).

## Expone hacia afuera
`currentTripProvider` y `tripByIdProvider` (los usará `chat_agent` en B4 para navegar al itinerario
recién guardado). Ver `phases.md` (TRACK B).
