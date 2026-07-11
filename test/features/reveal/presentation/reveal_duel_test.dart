import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/data/prediction_providers.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/data/reveal_providers.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';
import 'package:reckon/features/reveal/domain/usecases/generate_reveal.dart';
import 'package:reckon/features/reveal/presentation/reveal_screen.dart';

const _caseId = 'case-reveal-duel';

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

ModelPrediction _forecast(String id, String name, int lean, String rationale) =>
    ModelPrediction(
      id: id,
      caseId: _caseId,
      modelVersion: 'fake#$id',
      kind: PredictionKind.duelForecast,
      predictedAt: DateTime.utc(2026, 4, 2),
      payload: {
        'lean': lean,
        'rationale': rationale,
        'forecasterId': id,
        'forecasterName': name,
      },
    );

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'fake';
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
  Future<RevealObservation> generateRevealObservation(
          CaseTimeSeries ts) async =>
      const RevealObservation(text: 'Held steady.');
  @override
  Future<CommunitySeed> generateCommunitySeed(Case c,
          {String? persona, double? temperature}) =>
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

void main() {
  Widget harness(List<ModelPrediction> duels) => ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _case),
          pollsForCaseProvider.overrideWith((ref, id) async => <Poll>[]),
          generateRevealProvider.overrideWith(
            (ref) async => GenerateReveal(_FakeLlm(), _FakePredictions()),
          ),
          duelForecastsForCaseProvider
              .overrideWith((ref, id) async => duels),
        ],
        child: const MaterialApp(home: RevealScreen(caseId: _caseId)),
      );

  testWidgets('the reveal shows the duel table: names and leans, at last',
      (tester) async {
    await tester.pumpWidget(harness([
      _forecast('f1', 'Base-rate skeptic', 30, 'Most stay and are glad.'),
      _forecast('f2', 'Steelman advocate', 80, 'The move case is stronger.'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('THE DUEL'), findsOneWidget);
    expect(find.text('Base-rate skeptic'), findsOneWidget);
    expect(find.text('Steelman advocate'), findsOneWidget);
    expect(find.textContaining('30'), findsOneWidget);
    expect(find.textContaining('80'), findsOneWidget);
  });

  testWidgets('rationales expand on tap', (tester) async {
    await tester.pumpWidget(harness([
      _forecast('f1', 'Base-rate skeptic', 30, 'Most stay and are glad.'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Most stay and are glad.'), findsNothing);
    await tester.tap(find.text('Base-rate skeptic'));
    await tester.pumpAndSettle();
    expect(find.text('Most stay and are glad.'), findsOneWidget);
  });

  testWidgets('no duel section when nobody forecast', (tester) async {
    await tester.pumpWidget(harness(const []));
    await tester.pumpAndSettle();

    expect(find.text('THE DUEL'), findsNothing);
  });
}
