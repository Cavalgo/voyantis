import 'parsing.dart';

/// Resumen de cabecera del itinerario (lo que muestra el header del timeline).
/// `startDate` / `endDate` = strings ISO 8601 (`"2026-09-18"`).
class Summary {
  const Summary({
    this.destination = '',
    this.startDate = '',
    this.endDate = '',
    this.totalDays = 0,
    this.vibeTags = const [],
    this.estimatedBudgetTotal = 0,
    this.currency = '',
  });

  final String destination;
  final String startDate;
  final String endDate;
  final int totalDays;
  final List<String> vibeTags;
  final num estimatedBudgetTotal;
  final String currency;

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        destination: jStr(json['destination']),
        startDate: jStr(json['startDate']),
        endDate: jStr(json['endDate']),
        totalDays: jInt(json['totalDays']),
        vibeTags: jStrList(json['vibeTags']),
        estimatedBudgetTotal: jNum(json['estimatedBudgetTotal']),
        currency: jStr(json['currency']),
      );

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'startDate': startDate,
        'endDate': endDate,
        'totalDays': totalDays,
        'vibeTags': vibeTags,
        'estimatedBudgetTotal': estimatedBudgetTotal,
        'currency': currency,
      };
}
