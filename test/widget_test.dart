// Hoy no hacemos tests exhaustivos (ver mymds/rules.md). Este smoke test solo
// verifica que la app arranca sin crashear y pinta el shell del itinerario.
// Se hace override de `currentTripProvider` para no depender de Firebase.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voyanties/main.dart';
import 'package:voyanties/core/models/models.dart';
import 'package:voyanties/features/itinerary_view/data/trip_repository.dart';

void main() {
  testWidgets('arranca y muestra el shell del itinerario', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentTripProvider.overrideWith(
            (ref) => Stream<Trip?>.value(null),
          ),
        ],
        child: const VoyantisApp(),
      ),
    );
    await tester.pump(); // resuelve el primer valor del stream

    expect(find.text('Voyantis'), findsOneWidget); // título del AppBar
    expect(find.text('Aún no hay un itinerario'), findsOneWidget); // estado vacío
  });
}
