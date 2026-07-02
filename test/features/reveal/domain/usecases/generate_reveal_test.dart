import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';
import 'package:reckon/features/reveal/domain/usecases/generate_reveal.dart';

class _FakePredictions implements PredictionRepository {
  final List<ModelPrediction> logged = [];
  @override
  Future<void> log(ModelPrediction p) async => logged.add(p);
  @override
  Future<List<ModelPrediction>> forCase(String caseId) async =>
      logged.where((p) => p.caseId == caseId).toList();
  @override
  Future<void> scoreForCase(String caseId,
      {required double score, required DateTime scoredAt}) async {}
  @override
  Future<List<ModelScorecardEntry>> scorecard() async => const [];
}

class _FakeLlm implements LlmService {
  CaseTimeSeries? capturedSeries;

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
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries ts) async {
    capturedSeries = ts;
    return const RevealObservation(text: 'stable');
  }

  @override
  Future<CommunitySeed> generateCommunitySeed(Case c) =>
      throw UnimplementedError();
}

void main() {
  test('GenerateReveal passes final choice label into the time series',
      () async {
    final llm = _FakeLlm();
    final predictions = _FakePredictions();
    final uc = GenerateReveal(llm, predictions);
    final result = await uc.call(
      case_: Case(
        id: 'c1',
        createdAt: DateTime(2026, 4, 1),
        deadline: null,
        status: CaseStatus.decided,
        question: 'stay or go?',
        optionA: 'stay',
        optionB: 'go',
        statedCriteria: const [Criterion(label: 'x', weight: 1)],
        stakes: Stakes.medium,
        regretHorizon: RegretHorizon.months,
        category: 'career',
      ),
      polls: const [],
      chosenOption: 'b',
    );
    expect(result.text, 'stable');
    expect(llm.capturedSeries!.finalChoice, 'go');
  });

  Case _stayOrGo() => Case(
        id: 'c1',
        createdAt: DateTime(2026, 4, 1),
        deadline: null,
        status: CaseStatus.decided,
        question: 'stay or go?',
        optionA: 'stay',
        optionB: 'go',
        statedCriteria: const [Criterion(label: 'x', weight: 1)],
        stakes: Stakes.medium,
        regretHorizon: RegretHorizon.months,
        category: 'career',
      );

  test('reuses a prior observation for the SAME chosen option (no re-run)',
      () async {
    final llm = _FakeLlm();
    final predictions = _FakePredictions();
    await predictions.log(ModelPrediction(
      id: 'p0',
      caseId: 'c1',
      modelVersion: 'gemma-3-1b-it',
      kind: PredictionKind.revealObservation,
      predictedAt: DateTime(2026, 4, 1),
      payload: const {'text': 'your lean held steady', 'chosenOption': 'b'},
    ));

    final result = await GenerateReveal(llm, predictions)
        .call(case_: _stayOrGo(), polls: const [], chosenOption: 'b');

    expect(result.text, 'your lean held steady');
    expect(llm.capturedSeries, isNull,
        reason: 'same-option re-entry must reuse the cached reveal');
    expect(predictions.logged.length, 1);
  });

  test('regenerates when the chosen option differs from the cached one',
      () async {
    final llm = _FakeLlm();
    final predictions = _FakePredictions();
    // A reveal was generated earlier for option A ("stay").
    await predictions.log(ModelPrediction(
      id: 'p0',
      caseId: 'c1',
      modelVersion: 'gemma-3-1b-it',
      kind: PredictionKind.revealObservation,
      predictedAt: DateTime(2026, 4, 1),
      payload: const {'text': 'your lean held steady', 'chosenOption': 'a'},
    ));

    // The user now commits option B — the observation must describe B, not
    // reuse the A narrative (the app's signature screen would otherwise
    // describe the wrong option).
    final result = await GenerateReveal(llm, predictions)
        .call(case_: _stayOrGo(), polls: const [], chosenOption: 'b');

    expect(llm.capturedSeries, isNotNull,
        reason: 'a different chosen option must trigger a fresh generation');
    expect(llm.capturedSeries!.finalChoice, 'go');
    expect(result.text, 'stable');
    expect(predictions.logged.length, 2,
        reason: 'the new option-B observation is logged alongside the old one');
  });
}
