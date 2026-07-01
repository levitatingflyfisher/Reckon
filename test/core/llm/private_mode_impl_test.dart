import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/private_mode_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';

/// Fake session: replays a canned reply through the REAL [InferenceChat]
/// machinery (token accounting, history) so the test exercises the same
/// plumbing the on-device path uses, minus the native runtime.
class _FakeSession implements InferenceModelSession {
  _FakeSession(this.reply);

  final String reply;
  final List<Message> queries = [];

  @override
  Future<void> addQueryChunk(Message message) async => queries.add(message);

  @override
  Future<String> getResponse() async => reply;

  @override
  Stream<String> getResponseAsync() => Stream.fromIterable([reply]);

  @override
  Future<int> sizeInTokens(String text) async => 1;

  @override
  Future<void> stopGeneration() async {}

  @override
  Future<void> close() async {}
}

class _FakeModel extends InferenceModel {
  _FakeModel(this.reply, {this.throwOnSession = false});

  final String reply;
  final bool throwOnSession;

  String? lastSystemInstruction;
  double? lastTemperature;

  @override
  InferenceModelSession? get session => null;

  @override
  int get maxTokens => 4096;

  @override
  ModelFileType get fileType => ModelFileType.task;

  @override
  Future<InferenceModelSession> createSession({
    double temperature = .8,
    int randomSeed = 1,
    int topK = 1,
    double? topP,
    String? loraPath,
    bool? enableVisionModality,
    bool? enableAudioModality,
    String? systemInstruction,
    bool enableThinking = false,
  }) async {
    if (throwOnSession) throw StateError('native runtime fell over');
    lastSystemInstruction = systemInstruction;
    lastTemperature = temperature;
    return _FakeSession(reply);
  }

  @override
  Future<void> close() async {}
}

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
  test('generateCommunitySeed parses the single-line JSON reply', () async {
    final model = _FakeModel(
        '{"lean": 62, "rationale": "Most movers in this class are glad."}');
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    final seed = await svc.generateCommunitySeed(_case());

    expect(seed.lean, 62);
    expect(seed.rationale, contains('glad'));
  });

  test('clamps an out-of-range lean into 0-100', () async {
    final model = _FakeModel('{"lean": 140, "rationale": "sure"}');
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    final seed = await svc.generateCommunitySeed(_case());

    expect(seed.lean, 100);
  });

  test('persona reaches the system instruction; none means neutral prompt',
      () async {
    final model = _FakeModel('{"lean": 50, "rationale": "even"}');
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    await svc.generateCommunitySeed(
      _case(),
      persona: 'Anchors on base rates and distrusts special stories.',
    );
    expect(model.lastSystemInstruction, contains('base rates'));

    await svc.generateCommunitySeed(_case());
    expect(model.lastSystemInstruction, isNot(contains('base rates')));
    expect(model.lastSystemInstruction, contains('"lean"'));
  });

  test('temperature override reaches the session', () async {
    final model = _FakeModel('{"lean": 50, "rationale": "even"}');
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    await svc.generateCommunitySeed(_case(), temperature: 0.9);
    expect(model.lastTemperature, 0.9);

    await svc.generateCommunitySeed(_case());
    expect(model.lastTemperature, 0.4); // structured-call default
  });

  test('an unparseable reply degrades to the sentinel, never throws',
      () async {
    final model = _FakeModel('I cannot answer that in JSON, sorry.');
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    final seed = await svc.generateCommunitySeed(_case());

    expect(seed.lean, 50);
    expect(seed.rationale, isEmpty); // empty rationale marks the sentinel
  });

  test('a native failure degrades to the sentinel, never throws', () async {
    final model = _FakeModel('unused', throwOnSession: true);
    final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

    final seed = await svc.generateCommunitySeed(_case());

    expect(seed.lean, 50);
    expect(seed.rationale, isEmpty);
  });

  group('redactQuestion', () {
    test('parses the single-line JSON rewrite', () async {
      final model = _FakeModel(
          '{"title": "Buy the vacation cabin?", '
          '"background": "Family of five, single income."}');
      final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

      final r = await svc.redactQuestion(
        title: 'Buy the cabin near Bear Lake?',
        background: 'The Hansens are a family of five; Jim works at Acme.',
      );

      expect(r.isSentinel, isFalse);
      expect(r.title, 'Buy the vacation cabin?');
      expect(r.background, 'Family of five, single income.');
      // The redactor prompt reached the session.
      expect(model.lastSystemInstruction, contains('de-identify'));
    });

    test('an unparseable reply degrades to the sentinel', () async {
      final model = _FakeModel('Sure! Here is a redacted version: ...');
      final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

      final r = await svc.redactQuestion(title: 't', background: 'b');

      expect(r.isSentinel, isTrue);
    });

    test('a reply missing either field degrades to the sentinel', () async {
      final model = _FakeModel('{"title": "only a title"}');
      final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

      final r = await svc.redactQuestion(title: 't', background: 'b');

      expect(r.isSentinel, isTrue);
    });

    test('a native failure degrades to the sentinel, never throws', () async {
      final model = _FakeModel('unused', throwOnSession: true);
      final svc = PrivateModeImpl(model, 'qwen-2.5-1.5b-it');

      final r = await svc.redactQuestion(title: 't', background: 'b');

      expect(r.isSentinel, isTrue);
    });
  });
}
