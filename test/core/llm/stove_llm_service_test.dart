import 'package:domovoi/domovoi.dart' show AskException, Brain;
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/core/llm/stove_llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';

/// Records every prompt and answers with a canned reply (or throws).
class _FakeBrain implements Brain {
  _FakeBrain(this.reply, {this.failure});

  final String reply;
  final Object? failure;
  final List<String> prompts = [];

  @override
  Future<String> complete(String prompt) async {
    prompts.add(prompt);
    if (failure != null) throw failure!;
    return reply;
  }
}

Case _case() => Case(
      id: 'c1',
      createdAt: DateTime(2026, 8, 2),
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
  test('generateCommunitySeed flattens system + brief into one prompt',
      () async {
    final brain = _FakeBrain('{"lean": 70, "rationale": "go"}');
    final service = StoveLlmService(brain);

    final seed = await service.generateCommunitySeed(_case());

    expect(seed.lean, 70);
    expect(seed.rationale, 'go');
    final prompt = brain.prompts.single;
    expect(prompt, contains('cabin'), reason: 'the decision brief rides along');
    expect(prompt.indexOf('cabin'), greaterThan(0),
        reason: 'the system prompt comes first');
  });

  test('honors persona in the flattened prompt', () async {
    final brain = _FakeBrain('{"lean": 20, "rationale": "stay"}');
    final service = StoveLlmService(brain);

    await service.generateCommunitySeed(_case(),
        persona: 'Steelmans the road not taken.');

    expect(brain.prompts.single, contains('Steelmans'));
  });

  test('conductIntake flattens the transcript with role labels and yields '
      'the reply', () async {
    final brain = _FakeBrain('What matters most?');
    final service = StoveLlmService(brain);

    final out = await service
        .conductIntake(const IntakeContext(
          transcript: [
            IntakeTurn(role: IntakeRole.assistant, content: 'Hi'),
            IntakeTurn(role: IntakeRole.user, content: ''), // dropped
          ],
          userInput: 'I got an offer',
        ))
        .join();

    expect(out, 'What matters most?');
    final prompt = brain.prompts.single;
    expect(prompt, contains('Assistant: Hi'));
    expect(prompt, contains('User: I got an offer'));
    expect(prompt, isNot(contains('User: \n')),
        reason: 'empty turns are dropped');
  });

  test('conductIntake replays only the most recent turns (the local-model '
      'cap)', () async {
    final brain = _FakeBrain('ok');
    final service = StoveLlmService(brain);

    final turns = [
      for (var i = 0; i < 20; i++)
        IntakeTurn(
            role: i.isEven ? IntakeRole.user : IntakeRole.assistant,
            content: 'turn $i'),
    ];
    await service
        .conductIntake(IntakeContext(transcript: turns, userInput: 'now'))
        .join();

    final prompt = brain.prompts.single;
    expect(prompt, isNot(contains('turn 7')),
        reason: 'old turns beyond the replay cap are dropped');
    expect(prompt, contains('turn 19'));
    expect(prompt, contains('User: now'));
  });

  test('a Brain failure degrades to sentinels, never throws', () async {
    final brain = _FakeBrain('unused',
        failure: AskException('The stove is not answering.'));
    final service = StoveLlmService(brain);

    final seed = await service.generateCommunitySeed(_case());
    expect(seed.lean, 50);
    expect(seed.rationale, isEmpty, reason: 'empty rationale = non-forecast');

    final intake = await service
        .conductIntake(const IntakeContext(transcript: [], userInput: 'hi'))
        .join();
    expect(intake, isEmpty);

    final redacted = await service.redactQuestion(
        title: 'Should I leave Initech?', background: 'My boss Bill…');
    expect(redacted.isSentinel, isTrue);
  });

  test('an unparseable reply degrades to sentinels, never throws', () async {
    final service = StoveLlmService(_FakeBrain('the model got chatty'));
    final m = await service.detectRepollSentiment(50, 'meh');
    expect(m.mismatch, isFalse);
  });

  test('modelVersion defaults to household-stove', () {
    expect(StoveLlmService(_FakeBrain('ok')).modelVersion, 'household-stove');
  });
}
