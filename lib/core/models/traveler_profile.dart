import 'parsing.dart';

/// Perfil del viajero que el agente arma en la fase de diagnóstico.
///
/// `goals` se deja como `Map<String, bool>` (llaves libres:
/// `instagrammable`, `salirZonaConfort`, `conocerGente`, `desconectar`, …)
/// para tolerar que el agente agregue o quite objetivos sin romper el modelo.
class TravelerProfile {
  const TravelerProfile({
    this.originCity = '',
    this.groupType = '',
    this.groupSize = 0,
    this.socialStyle = '',
    this.paceStyle = '',
    this.interests = const [],
    this.goals = const {},
    this.constraints = const [],
  });

  final String originCity;

  /// `"solo"` | `"pareja"` | `"familia"` | `"amigos"`.
  final String groupType;
  final int groupSize;

  /// `"introvertido"` | `"extrovertido"` | `"mixto"`.
  final String socialStyle;

  /// `"relajado"` | `"balanceado"` | `"intenso"`.
  final String paceStyle;
  final List<String> interests;
  final Map<String, bool> goals;
  final List<String> constraints;

  factory TravelerProfile.fromJson(Map<String, dynamic> json) => TravelerProfile(
        originCity: jStr(json['originCity']),
        groupType: jStr(json['groupType']),
        groupSize: jInt(json['groupSize']),
        socialStyle: jStr(json['socialStyle']),
        paceStyle: jStr(json['paceStyle']),
        interests: jStrList(json['interests']),
        goals: jMap(json['goals'])
            .map((key, value) => MapEntry(key, jBool(value))),
        constraints: jStrList(json['constraints']),
      );

  Map<String, dynamic> toJson() => {
        'originCity': originCity,
        'groupType': groupType,
        'groupSize': groupSize,
        'socialStyle': socialStyle,
        'paceStyle': paceStyle,
        'interests': interests,
        'goals': goals,
        'constraints': constraints,
      };
}
