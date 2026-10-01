import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/data/reveal_providers.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';
import 'package:reckon/features/reveal/domain/usecases/generate_reveal.dart';
import 'package:reckon/features/reveal/presentation/reveal_screen.dart';

const _caseId = 'case-reveal-overflow';

final _case = Case(
  id: _caseId,
  createdAt: DateTime.utc(2026, 4, 1),
  deadline: null,
  status: CaseStatus.open,
  question: 'Move cities or stay?',
  optionA: 'Stay',
  optionB: 'Move',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
  category: 'relocation',
);

final _polls = <Poll>[
  for (var i = 0; i < 3; i++)
    Poll(
      id: 'p-$i',
      caseId: _caseId,
      createdAt: DateTime.utc(2026, 4, 1 + i),
      pollNumber: i + 1,
      lean: [20, 50, 80][i],
      confidence: Confidence.medium,
      rationale: 'note',
    ),
];

/// Regression guard: the reveal screen (240px chart + observation card +
/// choice chips + pinned button) must scroll, not overflow, at 320dp / ×3.
void main() {
  testWidgets('RevealScreen scrolls instead of overflowing at 320dp / ×3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        caseByIdProvider.overrideWith((ref, id) async => _case),
        pollsForCaseProvider.overrideWith((ref, id) async => _polls),
        generateRevealProvider.overrideWith(
          (ref) async => GenerateReveal(_FakeLlm(), _FakePredictions()),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3.0)),
          child: child!,
        ),
        home: const RevealScreen(caseId: _caseId),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });

  // The lean chart's axis labels used to crowd and clip at 320dp / ×3:
  // "50" ran into A and B, and the poll numbers and "Poll #" were cut by
  // slots sized for 1x text.
  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3), (320.0, 3.0)]) {
    testWidgets('lean chart labels fit and do not overlap at '
        '${width.toInt()}dp / ×$scale', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _case),
          pollsForCaseProvider.overrideWith((ref, id) async => _polls),
          generateRevealProvider.overrideWith(
            (ref) async => GenerateReveal(_FakeLlm(), _FakePredictions()),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const RevealScreen(caseId: _caseId),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);

      final chart = find.byType(LineChart);
      expect(chart, findsOneWidget);
      final bounds = tester.getRect(chart);
      final labels = find.descendant(of: chart, matching: find.byType(Text));
      final rects = <String, Rect>{
        for (final e in labels.evaluate())
          (e.widget as Text).data!: tester.getRect(find.byWidget(e.widget)),
      };
      for (final want in ['A', 'B', '50', '1', '2', '3', 'Poll #', 'Lean']) {
        expect(rects, contains(want), reason: 'label "$want" missing');
      }
      for (final MapEntry(:key, :value) in rects.entries) {
        expect(bounds.inflate(0.5).contains(value.topLeft) &&
                bounds.inflate(0.5).contains(value.bottomRight),
            isTrue,
            reason: '"$key" spills out of the chart: $value vs $bounds');
      }
      final list = rects.entries.toList();
      for (var i = 0; i < list.length; i++) {
        for (var j = i + 1; j < list.length; j++) {
          final overlap =
              list[i].value.deflate(0.5).overlaps(list[j].value.deflate(0.5));
          expect(overlap, isFalse,
              reason: '"${list[i].key}" ${list[i].value} overlaps '
                  '"${list[j].key}" ${list[j].value}');
        }
      }
    });
  }
}

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'gemma-3-1b-it';
  @override
  Stream<String> conductIntake(IntakeContext ctx) => const Stream.empty();
  @override
  Future<OutsideViewResult> synthesizeOutsideView(
          Case c, ReferenceClassEntry r, UserProfile p) =>
      throw UnimplementedError();
  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      throw UnimplementedError();
  @override
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries ts) async =>
      const RevealObservation(
        text:
            'A long reveal observation that, at a large accessibility text '
            'scale on a narrow phone, needs to scroll rather than push the '
            'pinned action button off the bottom of the column.',
      );
  @override
  Future<CommunitySeed> generateCommunitySeed(Case c,
          {String? persona, double? temperature}) =>
      throw UnimplementedError();
  @override
  Future<RedactedQuestion> redactQuestion(
          {required String title, required String background}) =>
      throw UnimplementedError();
}

class _FakePredictions implements PredictionRepository {
  @override
  Future<void> log(ModelPrediction p) async {}
  @override
  Future<List<ModelPrediction>> forCase(String caseId) async => [];
  @override
  Future<void> scoreForCase(String caseId,
      {required double score, required DateTime scoredAt}) async {}
  @override
  Future<void> scoreDuelForecasts(String caseId,
      {required String chosenOption,
      required int satisfaction,
      required DateTime scoredAt}) async {}
  @override
  Future<List<ModelScorecardEntry>> scorecard() async => [];
}
