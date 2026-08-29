import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/itinerary_view/presentation/itinerary_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // No tumbamos la app por un problema de init: la pantalla del itinerario
    // mostrará su estado de error y el pitch puede seguir.
    debugPrint('Firebase.initializeApp falló: $e\n$st');
  }
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
      home: const ItineraryScreen(),
      routes: {
        '/chat': (_) => const ChatPlaceholderScreen(),
      },
    );
  }
}

/// Placeholder de navegación hacia el chat. La feature real la construye Track B
/// (paso B2) en `lib/features/chat_agent/presentation/chat_screen.dart`; cuando
/// exista, se cambia el destino del push en `ItineraryScreen`.
class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hablar con el agente')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 48),
              const SizedBox(height: 16),
              Text('El chat del agente llega en el paso B2',
                  style: t.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Por ahora, el itinerario se lee directo de Firestore (trips/demo-seed).',
                style: t.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
