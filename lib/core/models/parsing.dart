/// Helpers de parseo tolerante para los modelos de `core/models/`.
///
/// Regla de FASE 1: los modelos **nunca** deben crashear por un campo ausente,
/// nulo o con el tipo "equivocado" (int donde se esperaba double, string de
/// Firestore, etc). Estos helpers absorben esa variabilidad.
library;

/// String con fallback (`''` por defecto).
String jStr(dynamic v, [String fallback = '']) {
  if (v is String) return v;
  if (v == null) return fallback;
  return v.toString();
}

/// String que puede ser `null` (campo genuinamente opcional).
String? jStrN(dynamic v) => v is String ? v : null;

/// `num` (int o double) con fallback.
num jNum(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? fallback;
  return fallback;
}

/// `int` con fallback. Trunca doubles, parsea strings.
int jInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
  return fallback;
}

/// `double` con fallback.
double jDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

/// `bool` con fallback. Acepta `"true"`/`"false"` y números (0 = false).
bool jBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is num) return v != 0;
  return fallback;
}

/// Lista de strings; ignora nulos y vacíos. `[]` si el valor no es una lista.
List<String> jStrList(dynamic v) {
  if (v is! List) return const [];
  return v
      .map((e) => e?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}

/// Mapa `String -> dynamic`. `{}` si el valor no es un mapa.
Map<String, dynamic> jMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Fecha desde varios formatos: ISO 8601 string, millis (int), `DateTime`,
/// o un `Timestamp` de Firestore (duck-typing sobre `.toDate()` para no
/// depender de `cloud_firestore` acá). `null` si no se puede interpretar.
DateTime? jDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  try {
    final d = (v as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {
    // no era un Timestamp
  }
  return null;
}
