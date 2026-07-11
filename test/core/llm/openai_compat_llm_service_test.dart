import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/core/llm/openai_compat_client.dart';
import 'package:reckon/core/llm/openai_compat_llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';

/// Builds a service over a llamafile-shaped endpoint whose HTTP layer returns
/// [body] with [status], recording requests for assertions.
({OpenAiCompatLlmService service, List<http.Request> requests}) _service(
  String body, {
  int status = 200,
  String model = 'llamafile',
  Map<String, String> headers = const {},
}) {
  final requests = <http.Request>[];
  final mock = MockClient((req) async {
    requests.add(req);
    return http.Response(body, status,
        headers: {'content-type': 'application/json'});
  });
  final client = OpenAiCompatClient(
    baseUrl: Uri.parse('http://192.168.1.20:8080'),
    headers: headers,
    model: model,
    httpClient: mock,
  );
  return (service: OpenAiCompatLlmService(client), requests: requests);
}

String _chatResponse(String content) => jsonEncode({
      'choices': [
        {
          'message': {'role': 'assistant', 'content': content}
        }
      ]
    });

Case _case() => Case(
      id: 'c1',
      createdAt: DateTime(2026, 7, 11),
      deadline: null,
      status: CaseStatus.open,
      question: 'Move to the cabin?',
      optionA: 'Stay in town',
      optionB: 'Move',
      statedCriteria: const [],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'relocation',
    );

void main() {
  test('posts to {base}/v1/chat/completions with a system message', () async {
    final h = _service(_chatResponse('{"lean": 70, "rationale": "go"}'));
    final seed = await h.service.generateCommunitySeed(_case());

    expect(seed.lean, 70);
    final req = h.requests.single;
    expect(req.url.toString(),
        'http://192.168.1.20:8080/v1/chat/completions');
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['model'], 'llamafile');
    final messages = body['messages'] as List;
    expect((messages.first as Map)['role'], 'system');
    expect((messages.last as Map)['role'], 'user');
    expect((messages.last as Map)['content'], contains('cabin'));
  });

  test('honors persona and temperature', () async {
    final h = _service(_chatResponse('{"lean": 20, "rationale": "stay"}'));
    await h.service.generateCommunitySeed(
      _case(),
      persona: 'Steelmans the road not taken.',
      temperature: 0.9,
    );

    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    expect(body['temperature'], 0.9);
    final system = ((body['messages'] as List).first as Map)['content'];
    expect(system, contains('Steelmans'));
  });

  test('extra headers ride every request (self-hosted gateways want a key)',
      () async {
    final h = _service(_chatResponse('ok'),
        headers: {'authorization': 'Bearer sk-local'});
    await h.service.detectRepollSentiment(50, 'meh');

    expect(h.requests.single.headers['authorization'], 'Bearer sk-local');
  });

  test('conductIntake maps the transcript and yields the reply', () async {
    final h = _service(_chatResponse('What matters most?'));
    final out = await h.service
        .conductIntake(const IntakeContext(
          transcript: [
            IntakeTurn(role: IntakeRole.assistant, content: 'Hi'),
            IntakeTurn(role: IntakeRole.user, content: ''), // dropped
          ],
          userInput: 'I got an offer',
        ))
        .join();

    expect(out, 'What matters most?');
    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    final messages = body['messages'] as List;
    // system + assistant turn + latest user input (empty turn dropped).
    expect(messages, hasLength(3));
  });

  test('a non-200 response degrades to sentinels, never throws', () async {
    final h = _service('server on fire', status: 500);

    final seed = await h.service.generateCommunitySeed(_case());
    expect(seed.lean, 50);
    expect(seed.rationale, isEmpty);

    final intake = await h.service
        .conductIntake(const IntakeContext(transcript: [], userInput: 'hi'))
        .join();
    expect(intake, isEmpty);
  });

  test('an unparseable body degrades to sentinels, never throws', () async {
    final h = _service('<html>gateway error</html>');
    final m = await h.service.detectRepollSentiment(50, 'meh');
    expect(m.mismatch, isFalse);
  });

  test('modelVersion is the configured model string', () {
    final h = _service(_chatResponse('ok'), model: 'qwen2.5:7b');
    expect(h.service.modelVersion, 'qwen2.5:7b');
  });

  group('endpoint path joining', () {
    Future<Uri> urlFor(String base) async {
      final requests = <http.Request>[];
      final mock = MockClient((req) async {
        requests.add(req);
        return http.Response(_chatResponse('ok'), 200,
            headers: {'content-type': 'application/json'});
      });
      final client = OpenAiCompatClient(
        baseUrl: Uri.parse(base),
        model: 'm',
        httpClient: mock,
      );
      await client.complete('s', 'u');
      return requests.single.url;
    }

    test('a bare origin gets /v1/chat/completions appended', () async {
      expect((await urlFor('http://192.168.1.20:8080')).toString(),
          'http://192.168.1.20:8080/v1/chat/completions');
    });

    test('an OpenAI-SDK-style /v1/ base is not doubled', () async {
      expect((await urlFor('http://localhost:8080/v1/')).toString(),
          'http://localhost:8080/v1/chat/completions');
      expect((await urlFor('http://localhost:8080/v1')).toString(),
          'http://localhost:8080/v1/chat/completions');
    });

    test('a reverse-proxy path prefix is preserved, never dropped', () async {
      expect((await urlFor('http://host/llm')).toString(),
          'http://host/llm/v1/chat/completions');
      expect((await urlFor('http://host/api/')).toString(),
          'http://host/api/v1/chat/completions');
    });
  });
}
