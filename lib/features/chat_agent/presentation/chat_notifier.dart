import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

/// Estado de la conversación. `messages` es lo que se reenvía entero cada turno.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.tripId,
    this.error,
    this.lastSaveAt,
  });

  /// Historial COMPLETO (solo turnos reales user/assistant — sin el saludo de UI).
  final List<ChatMessage> messages;
  final bool isLoading;

  /// `null` hasta el primer `save_itinerary`.
  final String? tripId;

  /// Motivo del último fallo, si lo hubo (se limpia al siguiente envío).
  final String? error;

  /// Marca de tiempo del último turno que guardó el itinerario. La usa la UI
  /// para reaccionar una sola vez (navegar / celebrar).
  final DateTime? lastSaveAt;

  bool get isEmpty => messages.isEmpty;
  bool get hasError => error != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? tripId,
    Object? error = _sentinel,
    DateTime? lastSaveAt,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      tripId: tripId ?? this.tripId,
      error: identical(error, _sentinel) ? this.error : error as String?,
      lastSaveAt: lastSaveAt ?? this.lastSaveAt,
    );
  }

  static const Object _sentinel = Object();
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// Envía un mensaje del usuario. Añade el turno al historial de inmediato,
  /// llama al backend con la lista completa y anexa la respuesta del agente.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final outgoing = [
      ...state.messages,
      ChatMessage.user(trimmed),
    ];
    state = state.copyWith(
      messages: outgoing,
      isLoading: true,
      error: null,
    );

    try {
      final res = await _repo.sendMessage(
        tripId: state.tripId,
        messages: outgoing,
      );

      final reply = res.reply ??
          'Uy, algo no salió bien de mi lado. ¿Lo intentamos otra vez?';

      state = state.copyWith(
        messages: [...outgoing, ChatMessage.assistant(reply)],
        isLoading: false,
        tripId: res.tripId ?? state.tripId,
        error: res.error,
        lastSaveAt: res.itinerarySaved ? DateTime.now() : null,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...outgoing,
          const ChatMessage.assistant(
            'No pude comunicarme con el servidor. Revisa tu conexión e '
            'inténtalo de nuevo en un momento.',
          ),
        ],
        isLoading: false,
        error: 'network',
      );
    }
  }

  /// Reintenta el último mensaje del usuario (tras un fallo).
  Future<void> retryLast() async {
    if (state.isLoading || state.messages.isEmpty) return;
    // Quita el último turno del asistente (el mensaje de error) y el último del
    // usuario, y re-envía ese texto.
    final msgs = [...state.messages];
    if (msgs.isNotEmpty && !msgs.last.isUser) msgs.removeLast();
    if (msgs.isEmpty || !msgs.last.isUser) return;
    final lastUserText = msgs.removeLast().content;
    state = state.copyWith(messages: msgs, error: null);
    await send(lastUserText);
  }

  void reset() => state = const ChatState();
}
