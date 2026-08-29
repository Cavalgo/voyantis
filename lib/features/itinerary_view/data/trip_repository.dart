import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config.dart';
import '../../../core/models/models.dart';

/// Lee/escucha la colección `trips` de Firestore.
///
/// El doc `trips` NO guarda un campo `tripId` (el id del doc ES el tripId), así
/// que lo inyectamos antes de `Trip.fromJson`.
class TripRepository {
  TripRepository(this._db);

  final FirebaseFirestore _db;

  static final TripRepository instance =
      TripRepository(FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  /// El "viaje actual": el último `trip` de la DB con `profileId == kProfileId`.
  /// La app arranca con esto — aguanta reloads (re-corre la query). Necesita el
  /// índice compuesto `profileId + updatedAt` (ya desplegado).
  Stream<Trip?> watchCurrentTrip() {
    return _trips
        .where('profileId', isEqualTo: kProfileId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : _tripOf(snap.docs.first));
  }

  /// Un trip puntual por id (p. ej. el recién creado por el chat).
  Stream<Trip?> watchTrip(String tripId) {
    return _trips
        .doc(tripId)
        .snapshots()
        .map((doc) => doc.exists ? _tripOf(doc) : null);
  }

  Trip _tripOf(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    data.putIfAbsent('tripId', () => doc.id);
    return Trip.fromJson(data);
  }
}
