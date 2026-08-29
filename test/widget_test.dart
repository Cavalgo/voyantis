// Hoy no hacemos tests exhaustivos (ver mymds/rules.md). Dos smoke tests:
//  1. la app arranca y pinta el shell sin crashear (override de
//     `currentTripProvider` para no depender de Firebase);
//  2. los helpers de formato no explotan con entradas raras.
// La cobertura real de FASE 1 está en models_roundtrip_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voyanties/core/format.dart';
import 'package:voyanties/core/models/models.dart';
import 'package:voyanties/features/itinerary_view/presentation/itinerary_providers.dart';
import 'package:voyanties/main.dart';

void main() {
  testWidgets('arranca y pinta el shell (chat + itinerario)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTripProvider.overrideWith((ref) => Stream<Trip?>.value(null)),
        ],
        child: const VoyantisApp(),
      ),
    );
    await tester.pump();

    // Pantalla de chat visible (pestaña por defecto en layout angosto).
    expect(find.text('Cuéntame de tu próximo viaje'), findsOneWidget);
  });

  test('helpers de formato no crashean con entradas vacías o inválidas', () {
    expect(formatDayLabel(''), '');
    expect(formatDayLabel('no-es-fecha'), 'no-es-fecha');
    expect(formatDateRange('2026-09-18', '2026-09-20'), '18 – 20 sep 2026');
    expect(formatMoney(18000, 'MXN'), r'$18,000 MXN');
    expect(formatCost(0), 'Gratis');
  });
}
