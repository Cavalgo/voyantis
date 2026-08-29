// Hoy no hacemos tests exhaustivos (ver mymds/rules.md). El smoke test de arranque
// de la app se movió a una prueba manual (`flutter run -d chrome`) porque `main()`
// ahora inicializa Firebase y la UI escucha Firestore — nada de eso corre en el
// entorno de test sin mocks. La cobertura real de FASE 1 está en
// models_roundtrip_test.dart.
import 'package:flutter_test/flutter_test.dart';

import 'package:voyanties/core/format.dart';

void main() {
  test('helpers de formato no crashean con entradas vacías o inválidas', () {
    expect(formatDayLabel(''), '');
    expect(formatDayLabel('no-es-fecha'), 'no-es-fecha');
    expect(formatDateRange('2026-09-18', '2026-09-20'), '18 – 20 sep 2026');
    expect(formatMoney(18000, 'MXN'), r'$18,000 MXN');
    expect(formatCost(0), 'Gratis');
  });
}
