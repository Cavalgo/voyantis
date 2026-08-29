import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/chat_agent/presentation/chat_notifier.dart';
import 'features/chat_agent/presentation/chat_screen.dart';
import 'features/itinerary_view/presentation/itinerary_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // No tumbamos la app por un fallo de init: la pantalla del itinerario
    // muestra su estado de error y el pitch puede seguir.
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
      home: const HomeShell(),
    );
  }
}

/// Shell responsivo:
/// - Ancho > 1040px: chat y timeline lado a lado (el timeline se actualiza en
///   vivo mientras conversas — es el "wow" del demo).
/// - Angosto: se alterna entre chat e itinerario con la barra inferior; al
///   guardarse el itinerario, salta solo a la pestaña del timeline.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0; // 0 = chat, 1 = itinerario
  DateTime? _handledSaveAt;

  void _openChat() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    // Reacciona una sola vez a cada guardado del itinerario.
    ref.listen(chatNotifierProvider, (prev, next) {
      final savedAt = next.lastSaveAt;
      if (savedAt == null || savedAt == _handledSaveAt) return;
      _handledSaveAt = savedAt;
      if (!mounted) return;
      setState(() => _tab = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu itinerario está listo! 🎉'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.sage,
        ),
      );
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1040;
        if (wide) return const _SplitLayout();
        return _NarrowLayout(
          tab: _tab,
          onTab: (i) => setState(() => _tab = i),
          onOpenChat: _openChat,
        );
      },
    );
  }
}

class _SplitLayout extends StatelessWidget {
  const _SplitLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          SizedBox(width: 440, child: ChatScreen()),
          VerticalDivider(width: 1),
          Expanded(child: ItineraryScreen()),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.tab,
    required this.onTab,
    required this.onOpenChat,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: tab,
        children: [
          const ChatScreen(),
          ItineraryScreen(onOpenChat: onOpenChat),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: onTab,
        backgroundColor: AppColors.card,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Conversar',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Itinerario',
          ),
        ],
      ),
    );
  }
}
