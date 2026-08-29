/// Helpers de formato para la UI (fechas ISO -> legible en español, dinero).
library;

import 'package:intl/intl.dart';

const List<String> _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const List<String> _weekdays = [
  'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom',
];

/// Parsea una fecha de contenido (string ISO 8601). `null` si no se puede.
DateTime? parseIso(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso);
}

/// `"2026-09-18"` -> `"jue 18 sep"`. Devuelve el string crudo si no parsea.
String formatDayLabel(String iso) {
  final d = parseIso(iso);
  if (d == null) return iso;
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

/// `"2026-09-18"` -> `"18 sep"`.
String formatShortDate(String iso) {
  final d = parseIso(iso);
  if (d == null) return iso;
  return '${d.day} ${_months[d.month - 1]}';
}

/// Rango: `"18 – 20 sep 2026"` (mismo mes) o `"28 sep – 3 oct 2026"`.
String formatDateRange(String startIso, String endIso) {
  final a = parseIso(startIso);
  final b = parseIso(endIso);
  if (a == null || b == null) {
    return [startIso, endIso].where((s) => s.isNotEmpty).join(' – ');
  }
  final year = b.year;
  if (a.month == b.month && a.year == b.year) {
    return '${a.day} – ${b.day} ${_months[b.month - 1]} $year';
  }
  return '${a.day} ${_months[a.month - 1]} – ${b.day} ${_months[b.month - 1]} $year';
}

/// `18000, "MXN"` -> `"$18,000 MXN"`. Sin decimales.
String formatMoney(num amount, String currency) {
  final n = NumberFormat.decimalPattern('en_US').format(amount.round());
  final cur = currency.trim();
  return cur.isEmpty ? '\$$n' : '\$$n $cur';
}

/// `650` -> `"$650"` (montos pequeños, sin la divisa).
String formatCost(num amount) {
  if (amount <= 0) return 'Gratis';
  return '\$${NumberFormat.decimalPattern('en_US').format(amount.round())}';
}
