import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

// TODO Track B: inicializar Firebase aquí antes de runApp:
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
void main() {
  runApp(const ProviderScope(child: VoyantisApp()));
}

class VoyantisApp extends StatelessWidget {
  const VoyantisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voyantis',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Shell(),
    );
  }
}

/// Placeholder. Track B lo reemplaza con la navegación chat ↔ itinerario.
class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Voyantis', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tu viaje, diagnosticado y diseñado.', style: t.bodyLarge),
            const SizedBox(height: 24),
            Text('Shell base — features en construcción', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
