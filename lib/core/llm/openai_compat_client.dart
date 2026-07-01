import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for any OpenAI-compatible chat endpoint — llamafile, Ollama,
/// LM Studio, vLLM, or a hosted gateway. The user supplies a base URL and a
/// model name; requests go to `{base}/v1/chat/completions`.
///
/// Pure `package:http`, so this backend runs everywhere Reckon does —
/// including the web PWA, which gets its first real AI path through it.
/// Network is injected as an [http.Client] so the stack unit-tests without
/// the wire (mirrors [AnthropicClient]).
class OpenAiCompatClient {
  OpenAiCompatClient({
    required this.baseUrl,
    this.headers = const {},
    required this.model,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Server origin, e.g. `http://192.168.1.20:8080` for a LAN llamafile.
  /// The `/v1/chat/completions` path is appended here — see [_endpoint] for
  /// how bases that already carry a path are handled.
  final Uri baseUrl;

  /// The chat-completions endpoint under [baseUrl]. Users paste every shape
  /// the ecosystem produces: a bare origin, an OpenAI-SDK-style `.../v1/`,
  /// a reverse-proxied prefix like `/llm`. `Uri.resolve` mangled two of
  /// those (doubling `/v1`, dropping a no-trailing-slash prefix), so join
  /// textually: keep the base path, append `/v1/chat/completions`, and do
  /// not double a `/v1` the user already wrote.
  Uri _endpoint() {
    final base = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final suffix =
        base.endsWith('/v1') ? '/chat/completions' : '/v1/chat/completions';
    return Uri.parse('$base$suffix');
  }

  /// Extra headers on every request — self-hosted gateways often want an
  /// `authorization: Bearer …`. `content-type` is added automatically.
  final Map<String, String> headers;

  final String model;
  final http.Client _http;

  /// Sends [messages] (with an optional [system] prompt prepended as a system
  /// message) and returns the assistant's reply text. Throws
  /// [OpenAiCompatException] on a non-200 or an unparseable body so callers
  /// can fall back gracefully.
  Future<String> createChatCompletion({
    String? system,
    required List<Map<String, String>> messages,
    double temperature = 0.4,
    int maxTokens = 1024,
  }) async {
    final res = await _http.post(
      _endpoint(),
      headers: {
        'content-type': 'application/json',
        ...headers,
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': [
          if (system != null) {'role': 'system', 'content': system},
          ...messages,
        ],
      }),
    );

    if (res.statusCode != 200) {
      throw OpenAiCompatException(
          'Endpoint returned ${res.statusCode}: ${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = (decoded['choices'] as List?) ?? const [];
      final first = choices.whereType<Map<String, dynamic>>().firstOrNull;
      final message = first?['message'] as Map<String, dynamic>?;
      return message?['content'] as String? ?? '';
    } catch (e) {
      throw OpenAiCompatException('Could not parse response: $e');
    }
  }

  /// Convenience for the single-turn structured prompts: one user message.
  Future<String> complete(
    String system,
    String userMessage, {
    double temperature = 0.4,
    int maxTokens = 1024,
  }) =>
      createChatCompletion(
        system: system,
        messages: [
          {'role': 'user', 'content': userMessage},
        ],
        temperature: temperature,
        maxTokens: maxTokens,
      );

  void close() => _http.close();
}

class OpenAiCompatException implements Exception {
  OpenAiCompatException(this.message);
  final String message;
  @override
  String toString() => 'OpenAiCompatException: $message';
}
