import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_service.dart';

/// Thin client for the Anthropic Messages API, shared by Connected mode (calls
/// a Cloudflare Worker proxy that holds the key) and BYOK mode (calls the API
/// directly with the user's own key). The only difference between the two is
/// the base URL and auth headers, injected here; all prompt construction and
/// response parsing lives in [AnthropicLlmService].
///
/// Network is injected as an [http.Client] so the whole stack is unit-testable
/// without hitting the wire.
class AnthropicClient {
  AnthropicClient({
    required this.baseUrl,
    required this.headers,
    required this.model,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// Origin to POST to — `https://api.anthropic.com` for BYOK, the Worker
  /// origin for Connected. The `/v1/messages` path is appended here.
  final Uri baseUrl;

  /// Auth + version headers. BYOK supplies `x-api-key`; Connected supplies
  /// whatever the Worker expects (e.g. an app token). `content-type` and
  /// `anthropic-version` are added automatically.
  final Map<String, String> headers;

  final String model;
  final http.Client _http;

  /// Sends [messages] (with an optional [system] prompt) and returns the
  /// assistant's concatenated text. Throws [AnthropicException] on a non-200 or
  /// an unparseable body so callers can fall back gracefully.
  Future<String> createMessage({
    String? system,
    required List<Map<String, String>> messages,
    double temperature = 0.4,
    int maxTokens = 1024,
  }) async {
    final res = await _http.post(
      baseUrl.resolve('v1/messages'),
      headers: {
        'content-type': 'application/json',
        'anthropic-version': '2023-06-01',
        ...headers,
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        if (system != null) 'system': system,
        'messages': messages,
      }),
    );

    if (res.statusCode != 200) {
      throw AnthropicException(
          'Anthropic API returned ${res.statusCode}: ${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (decoded['content'] as List?) ?? const [];
      final text = content
          .whereType<Map<String, dynamic>>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String? ?? '')
          .join();
      return text;
    } catch (e) {
      throw AnthropicException('Could not parse Anthropic response: $e');
    }
  }

  /// Convenience for the single-turn structured prompts (outside view, reveal,
  /// sentiment): one user message.
  Future<String> complete(
    String system,
    String userMessage, {
    double temperature = 0.4,
    int maxTokens = 1024,
  }) =>
      createMessage(
        system: system,
        messages: [
          {'role': 'user', 'content': userMessage},
        ],
        temperature: temperature,
        maxTokens: maxTokens,
      );

  void close() => _http.close();
}

/// Maps an [IntakeContext] (transcript + latest input) onto Anthropic's
/// message list. Empty turns are dropped; consecutive same-role turns are kept
/// as-is (the API tolerates them).
List<Map<String, String>> intakeMessages(IntakeContext ctx) {
  final messages = <Map<String, String>>[];
  for (final turn in ctx.transcript) {
    if (turn.content.isEmpty) continue;
    messages.add({
      'role': turn.role == IntakeRole.user ? 'user' : 'assistant',
      'content': turn.content,
    });
  }
  if (ctx.userInput.isNotEmpty) {
    messages.add({'role': 'user', 'content': ctx.userInput});
  }
  return messages;
}

class AnthropicException implements Exception {
  AnthropicException(this.message);
  final String message;
  @override
  String toString() => 'AnthropicException: $message';
}
