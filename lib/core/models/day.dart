import 'activity.dart';
import 'parsing.dart';

/// Un día del itinerario. `date` = string ISO 8601 (`"2026-09-18"`).
class Day {
  const Day({
    this.dayNumber = 0,
    this.date = '',
    this.theme = '',
    this.activities = const [],
  });

  final int dayNumber;
  final String date;
  final String theme;
  final List<Activity> activities;

  factory Day.fromJson(Map<String, dynamic> json) => Day(
        dayNumber: jInt(json['dayNumber']),
        date: jStr(json['date']),
        theme: jStr(json['theme']),
        activities: (json['activities'] as List?)
                ?.map((e) => Activity.fromJson(jMap(e)))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'date': date,
        'theme': theme,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}
