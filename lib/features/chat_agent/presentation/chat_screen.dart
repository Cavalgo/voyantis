import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'chat_notifier.dart';
import 'widgets/message_bubble.dart';
import 'widgets/thinking_indicator.dart';

/// Pantalla de conversación con el agente.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();

  static const _suggestions = <String>[
    'Viaje a Oaxaca con mi pareja, 3 días, 18k pesos, salimos de CDMX. '
        'Nos gusta la comida y la historia, ritmo relajado. Propón directo.',
    'Fin de semana en la CDMX, solo, presupuesto libre, quiero museos y buena comida.',
    'Sorpréndeme: 5 días de playa con amigos en México, algo instagrameable.',
  ];

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? preset]) {
    // Mientras el agente responde, ignoramos el envío pero NO tocamos el campo
    // (dejamos que el usuario siga escribiendo su borrador).
    if (ref.read(chatNotifierProvider).isLoading) return;
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(chatNotifierProvider.notifier).send(text);
    _jumpToBottom();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatNotifierProvider);

    ref.listen(chatNotifierProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        _jumpToBottom();
      }
    });

    final itemCount = state.messages.length + (state.isLoading ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: widget.showTitle
          ? AppBar(
              titleSpacing: 20,
              title: Row(
                children: [
                  const _Logo(),
                  const SizedBox(width: 10),
                  Text(
                    'Voyantis',
                    style: displayFont(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: state.isEmpty && !state.isLoading
                ? _Intro(onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: itemCount,
                    itemBuilder: (context, i) {
                      if (i >= state.messages.length) {
                        return const ThinkingIndicator();
                      }
                      return MessageBubble(message: state.messages[i]);
                    },
                  ),
          ),
          if (state.hasError && !state.isLoading)
            _ErrorBar(
              onRetry: () =>
                  ref.read(chatNotifierProvider.notifier).retryLast(),
            ),
          _InputBar(
            controller: _input,
            focusNode: _focus,
            enabled: !state.isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.siennaDark, AppColors.sienna],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.explore_rounded, size: 18, color: Colors.white),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onPick});

  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Logo(),
              const SizedBox(height: 16),
              Text(
                'Cuéntame de tu próximo viaje',
                style: displayFont(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Destino (o "sorpréndeme"), con quién viajas, cuántos días, '
                'presupuesto y qué te late hacer. Yo armo el itinerario.',
                style: t.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'PRUEBA CON',
                style: t.labelSmall?.copyWith(
                  color: AppColors.muted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              for (final s in _ChatScreenState._suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuggestionCard(text: s, onTap: () => onPick(s)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_outward_rounded,
                  size: 16, color: AppColors.sienna),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: t.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6E7DF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: AppColors.siennaDark),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hubo un problema al procesar tu mensaje.',
                style: TextStyle(color: AppColors.ink, fontSize: 13),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final void Function([String?]) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                // NUNCA se deshabilita: en Flutter web, alternar `enabled` mientras
                // el campo tiene foco rompe el <input> y el 2º mensaje no escribe.
                // El envío se ignora aparte mientras `!enabled` (ver _send / _SendButton).
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Escribe tu mensaje…'
                      : 'Puedes ir escribiendo el siguiente…',
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.sienna),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(enabled: enabled, onTap: () => onSend()),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: enabled ? AppColors.sienna : AppColors.line,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: enabled
              ? const Icon(Icons.arrow_upward_rounded, color: Colors.white)
              : const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.muted),
                  ),
                ),
        ),
      ),
    );
  }
}
