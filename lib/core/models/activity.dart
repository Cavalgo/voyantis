import 'location.dart';
import 'parsing.dart';

/// Una parada del itinerario dentro de un día. `time` es un string libre
/// (`"09:00"`, `"Mañana"`, …), no una fecha.
class Activity {
  const Activity({
    this.time = '',
    this.title = '',
    this.description = '',
    this.location = const Location(),
    this.estimatedCost = 0,
    this.tip = '',
  });

  final String time;
  final String title;
  final String description;
  final Location location;
  final num estimatedCost;
  final String tip;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        time: jStr(json['time']),
        title: jStr(json['title']),
        description: jStr(json['description']),
        location: Location.fromJson(jMap(json['location'])),
        estimatedCost: jNum(json['estimatedCost']),
        tip: jStr(json['tip']),
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'description': description,
        'location': location.toJson(),
        'estimatedCost': estimatedCost,
        'tip': tip,
      };
}
