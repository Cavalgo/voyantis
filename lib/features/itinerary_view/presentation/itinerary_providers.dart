import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../data/trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository.instance,
);

/// El itinerario que se muestra en pantalla: el último trip del perfil fijo.
/// Se re-suscribe solo tras un reload y refleja en vivo cada `save_itinerary`.
final currentTripProvider = StreamProvider<Trip?>(
  (ref) => ref.watch(tripRepositoryProvider).watchCurrentTrip(),
);

/// Un trip puntual por id (por si se quiere fijar la vista a uno concreto).
final tripByIdProvider = StreamProvider.family<Trip?, String>(
  (ref, tripId) => ref.watch(tripRepositoryProvider).watchTrip(tripId),
);
