import 'parsing.dart';

/// Vuelo simulado (no se compran vuelos reales hoy). `date` = string ISO 8601.
class Flight {
  const Flight({
    this.type = '',
    this.airline = '',
    this.from = '',
    this.to = '',
    this.date = '',
    this.estimatedPrice = 0,
  });

  /// `"outbound"` | `"return"`.
  final String type;
  final String airline;
  final String from;
  final String to;
  final String date;
  final num estimatedPrice;

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
        type: jStr(json['type']),
        airline: jStr(json['airline']),
        from: jStr(json['from']),
        to: jStr(json['to']),
        date: jStr(json['date']),
        estimatedPrice: jNum(json['estimatedPrice']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'airline': airline,
        'from': from,
        'to': to,
        'date': date,
        'estimatedPrice': estimatedPrice,
      };
}
