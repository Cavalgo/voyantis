import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

/// Cliente HTTP hacia la Cloud Function del agente (`POST /api/chat`).
///
/// Base URL:
/// - **Release** (build web servido por Hosting): `/api` — el rewrite
///   `"/api/**" -> api` de `firebase.json` mantiene el mismo origen (sin CORS).
/// - **Dev** (`flutter run -d chrome`): el rewrite de Hosting NO aplica, así que
///   se apunta a la URL cruda de la función. CORS ya está resuelto en el backend
///   (refleja el origin). Cambiar [_rawFunctionUrl] si se re-deploya en otra región.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// URL cruda de la función deployada (us-central1, proyecto `mi-viaje-11d84`).
  static const String _rawFunctionUrl =
      'https://us-central1-mi-viaje-11d84.cloudfunctions.net/api';

  /// `/api` en release (rewrite de Hosting), URL cruda en dev.
  static String get defaultBaseUrl =>
      kReleaseMode ? kApiBasePath : _rawFunctionUrl;

  /// El agente tarda ~30s en responder y hasta ~55s en guardar. Damos margen.
  static const Duration _timeout = Duration(seconds: 120);

  Future<ChatResponse> postChat(ChatRequest request) async {
    final uri = Uri.parse('$_baseUrl/chat');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    // El backend degrada errores a 200 con `error` seteado. Un status != 2xx
    // sin cuerpo parseable sí es un fallo de transporte.
    if (res.statusCode ~/ 100 != 2 && body.isEmpty) {
      return ChatResponse(
        error: 'http_${res.statusCode}',
      );
    }
    return ChatResponse.fromJson(body);
  }

  void dispose() => _client.close();
}
