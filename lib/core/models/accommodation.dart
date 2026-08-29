import 'parsing.dart';

/// Hospedaje simulado. `checkIn` / `checkOut` = strings ISO 8601.
class Accommodation {
  const Accommodation({
    this.name = '',
    this.area = '',
    this.checkIn = '',
    this.checkOut = '',
    this.estimatedPricePerNight = 0,
    this.style = '',
  });

  final String name;
  final String area;
  final String checkIn;
  final String checkOut;
  final num estimatedPricePerNight;

  /// `"boutique"`, `"hostal"`, `"resort"`, …
  final String style;

  factory Accommodation.fromJson(Map<String, dynamic> json) => Accommodation(
        name: jStr(json['name']),
        area: jStr(json['area']),
        checkIn: jStr(json['checkIn']),
        checkOut: jStr(json['checkOut']),
        estimatedPricePerNight: jNum(json['estimatedPricePerNight']),
        style: jStr(json['style']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'area': area,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'estimatedPricePerNight': estimatedPricePerNight,
        'style': style,
      };
}
