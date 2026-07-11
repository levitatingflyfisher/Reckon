import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reckon/core/llm/anthropic_client.dart';
import 'package:reckon/core/llm/anthropic_llm_service.dart';
import 'package:reckon/core/llm/byok_mode_impl.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';

/// Builds a service whose HTTP layer returns [body] (status [status]) and
/// records the last request for assertions.
({AnthropicLlmService service, List<http.Request> requests}) _service(
  String body, {
  int status = 200,
  String model = 'claude-sonnet-4-6',
}) {
  final requests = <http.Request>[];
  final mock = MockClient((req) async {
    requests.add(req);
    return http.Response(body, status, headers: {'content-type': 'application/json'});
  });
  final client = AnthropicClient(
    baseUrl: Uri.parse('https://api.anthropic.com'),
    headers: const {'x-api-key': 'sk-test'},
    model: model,
    httpClient: mock,
  );
  return (service: AnthropicLlmService(client), requests: requests);
}

String _textResponse(String text) =>
    jsonEncode({
      'content': [
        {'type': 'text', 'text': text}
      ]
    });

Case _case() => Case(
      id: 'c1',
      createdAt: DateTime(2026, 1, 1),
      deadline: null,
      status: CaseStatus.open,
      question: 'Take the job?',
      optionA: 'Stay',
      optionB: 'Go',
      statedCriteria: const [Criterion(label: 'comp', weight: 1)],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'career',
    );

void main() {
  test('conductIntake sends model + system + messages and yields the reply',
      () async {
    final h = _service(_textResponse('What matters most to you here?'));
    final out = await h.service
        .conductIntake(const IntakeContext(
          transcript: [
            IntakeTurn(role: IntakeRole.assistant, content: 'Hi'),
            IntakeTurn(role: IntakeRole.user, content: ''), // dropped (empty)
          ],
          userInput: 'I got an offer',
        ))
        .join();

    expect(out, 'What matters most to you here?');
    final req = h.requests.single;
    expect(req.url.path, '/v1/messages');
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['model'], 'claude-sonnet-4-6');
    expect(body['system'], isNotEmpty);
    // Empty turn dropped; assistant turn + the latest user input remain.
    final messages = body['messages'] as List;
    expect(messages, hasLength(2));
    expect(messages.last, {'role': 'user', 'content': 'I got an offer'});
  });

  test('synthesizeOutsideView returns the text plus reference metadata',
      () async {
    final h = _service(_textResponse('Roughly 60% are glad at 2 years.'));
    final result = await h.service.synthesizeOutsideView(
      _case(),
      const ReferenceClassEntry(
        id: 'career-job-offer-eval',
        category: 'career',
        subcategory: 'job offer evaluation',
        baseRateDescription: '~60% glad at 2 years',
        stratificationVariables: ['comp delta'],
        sources: [],
        commonCriteria: ['comp'],
        commonRegretPatterns: 'comp-only movers regret',
        uncertaintyLevel: 'medium',
        lastUpdated: '2026-04-01',
      ),
      const UserProfile(sesBracket: 'mid'),
    );

    expect(result.baseRateSummary, contains('60%'));
    expect(result.referenceClassUsed, 'career / job offer evaluation');
    expect(result.uncertaintyLevel, 'medium');
    expect(result.stratificationFactors['ses'], 'mid');
  });

  test('detectRepollSentiment parses a JSON object from the reply', () async {
    final h = _service(_textResponse(
        '{"mismatch": true, "observation": "Your words read more negative than your score."}'));
    final result = await h.service.detectRepollSentiment(70, 'I dread it');
    expect(result.mismatch, isTrue);
    expect(result.observation, contains('negative'));
  });

  test('generateCommunitySeed parses and clamps lean', () async {
    final h = _service(
        _textResponse('{"lean": 120, "rationale": "leans strongly to B"}'));
    final seed = await h.service.generateCommunitySeed(_case());
    expect(seed.lean, 100); // clamped from 120
    expect(seed.rationale, contains('B'));
  });

  test('generateCommunitySeed honors persona and temperature', () async {
    final h = _service(_textResponse('{"lean": 30, "rationale": "leans A"}'));
    final seed = await h.service.generateCommunitySeed(
      _case(),
      persona: 'Steelmans the option the asker leans away from.',
      temperature: 0.8,
    );

    expect(seed.lean, 30);
    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    expect(body['system'], contains('Steelmans'));
    expect(body['temperature'], 0.8);
  });

  test('generateCommunitySeed without a persona uses the neutral prompt',
      () async {
    final h = _service(_textResponse('{"lean": 55, "rationale": "close"}'));
    await h.service.generateCommunitySeed(_case());

    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    expect(body['system'], contains('"lean"'));
    expect(body['system'], isNot(contains('stance:')));
  });

  test('a non-200 response degrades gracefully, never throws', () async {
    final h = _service('rate limited', status: 429);
    final mismatch = await h.service.detectRepollSentiment(50, 'meh');
    expect(mismatch.mismatch, isFalse); // sentinel
    final intake = await h.service
        .conductIntake(const IntakeContext(transcript: [], userInput: 'hi'))
        .join();
    expect(intake, isEmpty); // empty stream, no crash
  });

  test('redactQuestion sends the redactor prompt and parses the rewrite',
      () async {
    final h = _service(_textResponse(
        '{"title": "Buy the vacation cabin?", '
        '"background": "Family of five, single income."}'));

    final r = await h.service.redactQuestion(
      title: 'Buy the cabin near Bear Lake?',
      background: 'The Hansens are a family of five.',
    );

    expect(r.isSentinel, isFalse);
    expect(r.title, 'Buy the vacation cabin?');
    expect(r.background, 'Family of five, single income.');
    final body = jsonDecode(h.requests.single.body) as Map<String, dynamic>;
    expect(body['system'], contains('de-identify'));
    final content =
        ((body['messages'] as List).single as Map)['content'] as String;
    expect(content, contains('Bear Lake'));
    expect(content, contains('Hansens'));
  });

  test('redactQuestion degrades to the sentinel on HTTP failure', () async {
    final h = _service('rate limited', status: 429);

    final r = await h.service.redactQuestion(title: 't', background: 'b');

    expect(r.isSentinel, isTrue);
  });

  test('BYOK mode points at api.anthropic.com with the user key header',
      () async {
    final requests = <http.Request>[];
    final mock = MockClient((req) async {
      requests.add(req);
      return http.Response(_textResponse('ok'), 200);
    });
    final byok = ByokModeImpl(apiKey: 'sk-user-123', httpClient: mock);
    await byok
        .conductIntake(const IntakeContext(transcript: [], userInput: 'hi'))
        .join();

    final req = requests.single;
    expect(req.url.origin, 'https://api.anthropic.com');
    expect(req.url.path, '/v1/messages');
    expect(req.headers['x-api-key'], 'sk-user-123');
    expect(req.headers['anthropic-version'], '2023-06-01');
    expect(byok.modelVersion, ByokModeImpl.defaultModel);
  });
}
