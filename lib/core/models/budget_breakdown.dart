import 'parsing.dart';

/// Desglose del presupuesto estimado. El agente lo incluye SIEMPRE, aunque
/// sea estimación (el header del itinerario lo muestra).
class BudgetBreakdown {
  const BudgetBreakdown({
    this.flights = 0,
    this.accommodation = 0,
    this.activities = 0,
    this.food = 0,
    this.buffer = 0,
    this.total = 0,
  });

  final num flights;
  final num accommodation;
  final num activities;
  final num food;
  final num buffer;
  final num total;

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) => BudgetBreakdown(
        flights: jNum(json['flights']),
        accommodation: jNum(json['accommodation']),
        activities: jNum(json['activities']),
        food: jNum(json['food']),
        buffer: jNum(json['buffer']),
        total: jNum(json['total']),
      );

  Map<String, dynamic> toJson() => {
        'flights': flights,
        'accommodation': accommodation,
        'activities': activities,
        'food': food,
        'buffer': buffer,
        'total': total,
      };
}
