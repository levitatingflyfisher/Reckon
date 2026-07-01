import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/bounty/data/bounty_providers.dart';
import 'package:reckon/features/bounty/domain/usecases/redact_question.dart';
import 'package:reckon/features/bounty/presentation/bounty_screen.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/predictions/data/prediction_providers.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';

import '../../forecasters/in_memory_fakes.dart';

const _caseId = 'cabin-case';

class _RedactingLlm implements LlmService {
  @override
  Future<RedactedQuestion> redactQuestion(
          {required String title, required String background}) async =>
      const RedactedQuestion(
        title: 'Buy the vacation cabin?',
        background: 'A family of five weighs a second home.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Case _case({CaseStatus status = CaseStatus.open}) => Case(
      id: _caseId,
      createdAt: DateTime.utc(2026, 7, 11),
      deadline: DateTime.utc(2026, 7, 18),
      status: status,
      question: 'Buy the cabin near Bear Lake?',
      optionA: 'Keep renting each summer',
      optionB: 'Buy the cabin',
      statedCriteria: const [],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'housing',
    );

const _responseJson = '{"reckonbounty": "0.1", "kind": "response", '
    '"request_id": "$_caseId", "id": "r1", '
    '"created_at": "2026-07-11T07:02:00Z", '
    '"bot": {"name": "hustlerBot80000"}, '
    '"forecast": {"distribution": {"Buy the cabin": 0.35, '
    '"Keep renting each summer": 0.65}, '
    '"rationale": "Second homes rarely pencil."}}';

void main() {
  late InMemoryForecasterRepository forecasters;
  late InMemoryPredictionRepository predictions;

  setUp(() {
    forecasters = InMemoryForecasterRepository();
    predictions = InMemoryPredictionRepository();
  });

  Widget harness({
    Case? case_,
    Future<LlmService?> Function()? resolve,
  }) =>
      ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => case_ ?? _case()),
          forecasterRepositoryProvider.overrideWithValue(forecasters),
          predictionRepositoryProvider.overrideWithValue(predictions),
          // The default import provider composes over the fakes above; only
          // redaction needs its LLM resolver stubbed.
          redactQuestionProvider.overrideWith(
              (ref) => RedactQuestion(resolve ?? () async => null)),
        ],
        child: const MaterialApp(home: BountyScreen(caseId: _caseId)),
      );

  group('Ask tab', () {
    testWidgets('shows the privacy promise and an editable manual draft',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Nothing leaves this device until you share'),
        findsOneWidget,
      );
      expect(
        find.textContaining('reads like a stranger wrote it'),
        findsWidgets,
      );
      // No resident model — the draft is the original text, flagged manual.
      expect(find.textContaining('redact by hand'), findsOneWidget);
      expect(find.text('Buy the cabin near Bear Lake?'), findsOneWidget);
      // Options are shown but not editable — answers key to their text.
      expect(find.textContaining('Keep renting each summer'), findsWidgets);
    });

    testWidgets('a resident model drafts the rewrite, flagged as such',
        (tester) async {
      await tester
          .pumpWidget(harness(resolve: () async => _RedactingLlm()));
      await tester.pumpAndSettle();

      expect(find.text('Buy the vacation cabin?'), findsOneWidget);
      expect(find.textContaining('on-device model'), findsOneWidget);
      expect(find.text('Buy the cabin near Bear Lake?'), findsNothing);
    });

    testWidgets('Copy request JSON puts a valid, edited request on the '
        'clipboard', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('bounty-title')), 'Buy the vacation cabin?');
      await tester.tap(find.text('Copy request JSON'));
      await tester.pumpAndSettle();

      final setData =
          calls.singleWhere((c) => c.method == 'Clipboard.setData');
      final text = (setData.arguments as Map)['text'] as String;
      final req = jsonDecode(text) as Map<String, dynamic>;
      expect(req['reckonbounty'], '0.1');
      expect(req['kind'], 'request');
      expect(req['id'], _caseId);
      expect((req['question'] as Map)['title'], 'Buy the vacation cabin?');
      expect((req['question'] as Map)['options'],
          ['Keep renting each summer', 'Buy the cabin']);
      expect((req['privacy'] as Map)['redaction'], 'manual');
    });
  });

  group('Import tab', () {
    testWidgets('a pasted response seals a forecast — count shown, content '
        'never', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('bounty-paste')), _responseJson);
      await tester.tap(find.text('Import forecasts'));
      await tester.pumpAndSettle();

      expect(predictions.logged, hasLength(1));
      expect(predictions.logged.single.kind, PredictionKind.duelForecast);
      expect(find.textContaining('1 forecast sealed'), findsOneWidget);
      // R1: the app renders neither lean nor rationale before the reveal.
      expect(find.textContaining('35'), findsNothing);
      expect(find.textContaining('rarely pencil'), findsNothing);
      // The paste box is cleared so the content stops being on screen.
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('bounty-paste')))
              .controller!
              .text,
          isEmpty);
    });

    testWidgets('garbage input surfaces the precise parse error', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('bounty-paste')), 'not json at all');
      await tester.tap(find.text('Import forecasts'));
      await tester.pumpAndSettle();

      expect(predictions.logged, isEmpty);
      expect(find.textContaining('not valid JSON'), findsOneWidget);
    });

    testWidgets('rejected responses list their reasons', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('bounty-paste')),
        '{"reckonbounty": "0.1", "kind": "response", '
        '"request_id": "some-other-case", "bot": {"name": "wrongBot"}, '
        '"forecast": {"p": 0.5}}',
      );
      await tester.tap(find.text('Import forecasts'));
      await tester.pumpAndSettle();

      expect(predictions.logged, isEmpty);
      // The bullet under the paste box (the paste itself also mentions the
      // bot, which is fine — it is the user's own text).
      expect(find.textContaining('wrongBot: answers a different request'),
          findsOneWidget);
    });
  });

  testWidgets('a decided case gets no export/import surface', (tester) async {
    await tester
        .pumpWidget(harness(case_: _case(status: CaseStatus.decided)));
    await tester.pumpAndSettle();

    expect(find.textContaining('already decided'), findsOneWidget);
    expect(find.text('Import forecasts'), findsNothing);
    expect(find.text('Copy request JSON'), findsNothing);
  });
}
