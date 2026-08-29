import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/models/models.dart';

/// Lee/escucha la colección `trips` de Firestore. Único punto de contacto con
/// Firestore para la feature `itinerary_view` (los widgets nunca hacen la query).
///
/// Providers expuestos:
///  - [currentTripProvider]  → el "viaje actual" (último por `updatedAt` del perfil fijo).
///  - [tripByIdProvider]     → un viaje concreto por id (lo usará B4 tras `save_itinerary`).
class TripRepository {
  TripRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static final TripRepository instance = TripRepository();

  CollectionReference<Map<String, dynamic>> get _trips => _db.collection('trips');

  /// El viaje que la app muestra al arrancar. No depende de tener un `tripId` en
  /// memoria → sobrevive a recargas de página. Requiere el índice compuesto
  /// `profileId ASC, updatedAt DESC` (ya desplegado en `firestore.indexes.json`).
  Stream<Trip?> watchCurrentTrip() {
    return _trips
        .where('profileId', isEqualTo: kProfileId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : _trip(snap.docs.first));
  }

  /// Un viaje puntual por id, en tiempo real (para reflejar ediciones del agente).
  Stream<Trip> watchTrip(String tripId) {
    return _trips.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) {
        throw StateError('El viaje "$tripId" no existe en Firestore.');
      }
      return _trip(doc);
    });
  }

  Trip _trip(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    // Inyecta el id del documento como tripId si el doc no lo trae dentro.
    return Trip.fromJson({'tripId': doc.id, ...data});
  }
}

/// El repositorio, inyectable en tests con `overrideWithValue`.
final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository.instance,
);

/// Viaje actual (perfil fijo, último por `updatedAt`). Es lo que pinta la home.
final currentTripProvider = StreamProvider<Trip?>(
  (ref) => ref.watch(tripRepositoryProvider).watchCurrentTrip(),
);

/// Viaje por id — para navegar a un itinerario concreto (B4).
final tripByIdProvider = StreamProvider.family<Trip, String>(
  (ref, tripId) => ref.watch(tripRepositoryProvider).watchTrip(tripId),
);
