import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/case/presentation/intake_screen.dart';

class _FakeDownloadService extends ModelDownloadService {
  _FakeDownloadService(this._downloaded);
  final Set<String> _downloaded;
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async =>
      _downloaded.contains(spec.id);
}

/// Records the IntakeContext handed to conductIntake so the test can assert the
/// latest user message is sent exactly once (via userInput, not also duplicated
/// in the replayed transcript).
class _RecordingLlmService implements LlmService {
  final List<IntakeContext> contexts = [];

  @override
  String get modelVersion => 'fake';

  @override
  Stream<String> conductIntake(IntakeContext ctx) {
    contexts.add(ctx);
    return const Stream<String>.empty();
  }

  // Other LlmService methods are unused by this test.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('the latest user message is sent once, not duplicated in the transcript',
      (tester) async {
    final svc = _RecordingLlmService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        selectedModelIdProvider
            .overrideWith((ref) async => ReckonModelSpec.qwen25_1_5b.id),
        modelDownloadServiceProvider.overrideWithValue(
            _FakeDownloadService({ReckonModelSpec.qwen25_1_5b.id})),
        llmServiceProvider.overrideWith((ref) async => svc),
      ],
      child: const MaterialApp(home: IntakeScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I got a job offer');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(svc.contexts, isNotEmpty, reason: 'a turn should have been sent');
    final ctx = svc.contexts.last;
    expect(ctx.userInput, 'I got a job offer');
    final dupes = ctx.transcript
        .where((t) => t.role == IntakeRole.user && t.content == 'I got a job offer')
        .length;
    expect(dupes, 0,
        reason: 'the latest message must not also appear in the replayed transcript');
  });
}
