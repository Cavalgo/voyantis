import 'parsing.dart';

/// Lugar real donde ocurre una actividad. `photoUrl` la construye el backend
/// (Google Places Photo API) — ver `mymds/02-technical-architecture.md`.
class Location {
  const Location({
    this.name = '',
    this.address = '',
    this.lat = 0,
    this.lng = 0,
    this.photoUrl = '',
    this.category = '',
    this.instagrammable = false,
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
  final String photoUrl;
  final String category;
  final bool instagrammable;

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        name: jStr(json['name']),
        address: jStr(json['address']),
        lat: jDouble(json['lat']),
        lng: jDouble(json['lng']),
        photoUrl: jStr(json['photoUrl']),
        category: jStr(json['category']),
        instagrammable: jBool(json['instagrammable']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'photoUrl': photoUrl,
        'category': category,
        'instagrammable': instagrammable,
      };
}
