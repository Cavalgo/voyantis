/// Formateo de fechas y dinero para el timeline. Sin `intl` a propósito: las
/// fechas de contenido son strings ISO (`"2026-09-18"` o con hora/offset) y no
/// queremos depender de cargar datos de locale para el demo.
library;

const List<String> _mesCorto = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// `"2026-09-18"` → `"18 sep"` (o `"18 sep 2026"` con [withYear]).
/// Devuelve el string original si no se puede parsear.
String prettyDate(String iso, {bool withYear = false}) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final base = '${d.day} ${_mesCorto[d.month - 1]}';
  return withYear ? '$base ${d.year}' : base;
}

/// Rango legible entre dos fechas ISO: `"18–20 sep 2026"` si comparten mes,
/// si no `"28 sep – 3 oct 2026"`.
String prettyRange(String startIso, String endIso) {
  final s = DateTime.tryParse(startIso);
  final e = DateTime.tryParse(endIso);
  if (s == null || e == null) {
    return [startIso, endIso].where((x) => x.isNotEmpty).join(' – ');
  }
  if (s.year == e.year && s.month == e.month) {
    return '${s.day}–${e.day} ${_mesCorto[e.month - 1]} ${e.year}';
  }
  return '${prettyDate(startIso)} – ${prettyDate(endIso, withYear: true)}';
}

/// `1250, "MXN"` → `"$1,250 MXN"`. Redondea; sin decimales (montos estimados).
String money(num value, String currency) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final sign = rounded < 0 ? '-' : '';
  final suffix = currency.isEmpty ? '' : ' $currency';
  return '$sign\$$buf$suffix';
}

/// Costo de una actividad: `"Gratis"` cuando es 0.
String activityCost(num value, String currency) =>
    value <= 0 ? 'Gratis' : money(value, currency);
