import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/hf_token.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';

class _FakeSvc extends ModelDownloadService {
  _FakeSvc({this.token});
  final String? token;
  String? saved;

  @override
  Future<String?> getHfToken() async => token;

  @override
  Future<void> setHfToken(String t) async => saved = t;
}

void main() {
  Future<bool> run(WidgetTester tester, ModelDownloadService svc,
      ReckonModelSpec spec) async {
    late bool result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await ensureHfToken(context, svc, spec),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('returns true for an ungated spec without prompting',
      (tester) async {
    final ok = await run(tester, _FakeSvc(), ReckonModelSpec.gemma3_1b);
    expect(ok, isTrue);
    expect(find.text('HuggingFace token'), findsNothing);
  });

  testWidgets('returns true when a gated spec already has a token',
      (tester) async {
    final ok = await run(
        tester, _FakeSvc(token: 'hf_existing'), ReckonModelSpec.qwen25_1_5b);
    expect(ok, isTrue);
    expect(find.text('HuggingFace token'), findsNothing);
  });

  testWidgets('prompts for a gated spec with no token and saves on Save',
      (tester) async {
    final svc = _FakeSvc();
    late bool result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result =
              await ensureHfToken(context, svc, ReckonModelSpec.qwen25_1_5b),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('HuggingFace token'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hf_new');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(svc.saved, 'hf_new');
  });
}
