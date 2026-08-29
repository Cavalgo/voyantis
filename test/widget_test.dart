// Hoy no hacemos tests exhaustivos (ver mymds/rules.md). Este smoke test
// solo verifica que la app arranca sin crashear.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voyanties/main.dart';

void main() {
  testWidgets('la app arranca y muestra el nombre', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VoyantisApp()));
    expect(find.text('Voyantis'), findsOneWidget);
  });
}
