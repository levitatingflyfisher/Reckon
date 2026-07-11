import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/bounty/domain/usecases/redact_question.dart';

/// Only redactQuestion matters here; everything else is unreachable.
class _RedactingLlm implements LlmService {
  _RedactingLlm(this.result, {this.throws = false});
  final RedactedQuestion result;
  final bool throws;

  @override
  Future<RedactedQuestion> redactQuestion(
      {required String title, required String background}) async {
    if (throws) throw StateError('rogue backend');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const title = 'Buy the cabin near Bear Lake?';
  const background = 'The Hansens are a family of five.';

  Future<RedactionResult> run(Future<LlmService?> Function() resolve) =>
      RedactQuestion(resolve)(title: title, background: background);

  test('a successful rewrite is flagged local-llm', () async {
    final result = await run(() async => _RedactingLlm(const RedactedQuestion(
        title: 'Buy the vacation cabin?',
        background: 'A family of five, single income.')));

    expect(result.redaction, 'local-llm');
    expect(result.title, 'Buy the vacation cabin?');
    expect(result.background, 'A family of five, single income.');
  });

  test('the sentinel falls back to the original text, flagged manual',
      () async {
    final result =
        await run(() async => _RedactingLlm(RedactedQuestion.sentinel));

    expect(result.redaction, 'manual');
    expect(result.title, title);
    expect(result.background, background);
  });

  test('no resident model (web, not downloaded) means manual', () async {
    final result = await run(() async => null);

    expect(result.redaction, 'manual');
    expect(result.title, title);
  });

  test('a throwing resolver means manual, never a crash', () async {
    final result = await run(() => throw StateError('AiUnavailableOnWeb'));

    expect(result.redaction, 'manual');
  });

  test('a rogue backend that throws means manual, never a crash', () async {
    final result = await run(() async =>
        _RedactingLlm(RedactedQuestion.sentinel, throws: true));

    expect(result.redaction, 'manual');
  });
}
