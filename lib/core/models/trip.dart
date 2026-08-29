import 'accommodation.dart';
import 'budget_breakdown.dart';
import 'day.dart';
import 'flight.dart';
import 'parsing.dart';
import 'summary.dart';
import 'traveler_profile.dart';

/// Un `trip` = un itinerario completo. Espejo del schema de la colección
/// `trips` de Firestore (ver `mymds/02-technical-architecture.md`).
///
/// - `profileId` y `updatedAt` van **top-level**. Los escribe el backend, pero
///   el modelo los lee/escribe para no perderlos en un round-trip.
/// - Fechas de contenido (`summary.startDate`, `day.date`, …) = strings ISO 8601.
/// - `createdAt` / `updatedAt` llegan como `Timestamp` de Firestore; `jDate`
///   los normaliza a `DateTime`. `toJson` los emite como ISO 8601 string
///   (el repo/backend puede convertir a `Timestamp` al escribir si hace falta).
/// - Tolera que falten `travelerProfile`, `summary`, `flights`,
///   `accommodation`, `days`, `budgetBreakdown`.
class Trip {
  const Trip({
    this.tripId,
    this.profileId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.travelerProfile,
    this.summary,
    this.flights = const [],
    this.accommodation = const [],
    this.days = const [],
    this.budgetBreakdown,
    this.conversationContext,
  });

  final String? tripId;
  final String? profileId;

  /// `"draft"` | `"confirmed"`.
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TravelerProfile? travelerProfile;
  final Summary? summary;
  final List<Flight> flights;
  final List<Accommodation> accommodation;
  final List<Day> days;
  final BudgetBreakdown? budgetBreakdown;

  /// Resumen libre que el agente mantiene para reanudar ediciones tras recarga.
  final String? conversationContext;

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        tripId: jStrN(json['tripId']),
        profileId: jStrN(json['profileId']),
        status: jStrN(json['status']),
        createdAt: jDate(json['createdAt']),
        updatedAt: jDate(json['updatedAt']),
        travelerProfile: json['travelerProfile'] == null
            ? null
            : TravelerProfile.fromJson(jMap(json['travelerProfile'])),
        summary: json['summary'] == null
            ? null
            : Summary.fromJson(jMap(json['summary'])),
        flights: (json['flights'] as List?)
                ?.map((e) => Flight.fromJson(jMap(e)))
                .toList() ??
            const [],
        accommodation: (json['accommodation'] as List?)
                ?.map((e) => Accommodation.fromJson(jMap(e)))
                .toList() ??
            const [],
        days: (json['days'] as List?)
                ?.map((e) => Day.fromJson(jMap(e)))
                .toList() ??
            const [],
        budgetBreakdown: json['budgetBreakdown'] == null
            ? null
            : BudgetBreakdown.fromJson(jMap(json['budgetBreakdown'])),
        conversationContext: jStrN(json['conversationContext']),
      );

  /// Espejo de `fromJson`. Omite las claves ausentes (no escribe `null`).
  /// Fechas como ISO 8601 UTC string.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (tripId != null) map['tripId'] = tripId;
    if (profileId != null) map['profileId'] = profileId;
    if (status != null) map['status'] = status;
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toUtc().toIso8601String();
    }
    if (travelerProfile != null) {
      map['travelerProfile'] = travelerProfile!.toJson();
    }
    if (summary != null) map['summary'] = summary!.toJson();
    map['flights'] = flights.map((f) => f.toJson()).toList();
    map['accommodation'] = accommodation.map((a) => a.toJson()).toList();
    map['days'] = days.map((d) => d.toJson()).toList();
    if (budgetBreakdown != null) {
      map['budgetBreakdown'] = budgetBreakdown!.toJson();
    }
    if (conversationContext != null) {
      map['conversationContext'] = conversationContext;
    }
    return map;
  }

  Trip copyWith({
    String? tripId,
    String? profileId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    TravelerProfile? travelerProfile,
    Summary? summary,
    List<Flight>? flights,
    List<Accommodation>? accommodation,
    List<Day>? days,
    BudgetBreakdown? budgetBreakdown,
    String? conversationContext,
  }) =>
      Trip(
        tripId: tripId ?? this.tripId,
        profileId: profileId ?? this.profileId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        travelerProfile: travelerProfile ?? this.travelerProfile,
        summary: summary ?? this.summary,
        flights: flights ?? this.flights,
        accommodation: accommodation ?? this.accommodation,
        days: days ?? this.days,
        budgetBreakdown: budgetBreakdown ?? this.budgetBreakdown,
        conversationContext: conversationContext ?? this.conversationContext,
      );
}
