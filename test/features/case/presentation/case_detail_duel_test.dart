import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/llm/llm_service.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/case/presentation/case_detail_screen.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/forecasters/domain/usecases/run_duel.dart';
import 'package:reckon/features/outside_view/data/outside_view_providers.dart';
import 'package:reckon/features/outside_view/domain/entities/reference_class_entry.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';
import 'package:reckon/features/predictions/data/prediction_providers.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/reveal/domain/entities/case_time_series.dart';
import 'package:reckon/features/reveal/domain/entities/reveal_observation.dart';

import '../../forecasters/in_memory_fakes.dart';

const _caseId = 'case-duel';
const _rationale = 'Movers in this class are usually glad.';

class _FakeLlm implements LlmService {
  @override
  String get modelVersion => 'fake-model';
  @override
  Future<CommunitySeed> generateCommunitySeed(Case c,
          {String? persona, double? temperature}) async =>
      const CommunitySeed(lean: 70, rationale: _rationale);
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
  Future<RevealObservation> generateRevealObservation(CaseTimeSeries ts) =>
      throw UnimplementedError();
  @override
  Future<RedactedQuestion> redactQuestion(
          {required String title, required String background}) =>
      throw UnimplementedError();
}

Case _case() => Case(
      id: _caseId,
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

Forecaster _persona(String id, String name) => Forecaster(
      id: id,
      displayName: name,
      kind: ForecasterKind.persona,
      config: const {'persona': 'A stance.'},
      createdAt: DateTime(2026, 7, 11),
    );

ModelPrediction _sealedForecast() => ModelPrediction(
      id: 'p1',
      caseId: _caseId,
      modelVersion: 'fake#f1',
      kind: PredictionKind.duelForecast,
      predictedAt: DateTime(2026, 7, 11),
      payload: const {
        'lean': 70,
        'rationale': _rationale,
        'forecasterId': 'f1',
        'forecasterName': 'Base-rate skeptic',
      },
    );

void main() {
  late InMemoryForecasterRepository forecasters;
  late InMemoryPredictionRepository predictions;

  setUp(() {
    forecasters = InMemoryForecasterRepository([
      _persona('persona-base-rate-skeptic', 'Base-rate skeptic'),
      _persona('persona-steelman-advocate', 'Steelman advocate'),
    ]);
    predictions = InMemoryPredictionRepository();
  });

  Widget harness({required List<Forecaster> runnable}) => ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _case()),
          pollsForCaseProvider.overrideWith((ref, id) async => <Poll>[]),
          outsideViewForCaseProvider.overrideWith((ref, id) async => null),
          forecasterRepositoryProvider.overrideWithValue(forecasters),
          predictionRepositoryProvider.overrideWithValue(predictions),
          runnableForecastersProvider.overrideWith((ref) async => runnable),
          // Real RunDuel over the fakes — sealing + idempotence run for real.
          runDuelProvider.overrideWith((ref) => RunDuel(
                ref.watch(forecasterRepositoryProvider),
                ref.watch(predictionRepositoryProvider),
                (f) async => _FakeLlm(),
              )),
        ],
        child: const MaterialApp(home: CaseDetailScreen(caseId: _caseId)),
      );

  testWidgets('shows "Run the duel" on an open case with a runnable roster',
      (tester) async {
    await tester.pumpWidget(harness(
        runnable: [_persona('persona-base-rate-skeptic', 'Base-rate skeptic')]));
    await tester.pumpAndSettle();

    expect(find.text('Run the duel'), findsOneWidget);
    expect(find.textContaining('sealed'), findsNothing); // nothing sealed yet
  });

  testWidgets('hides the duel button when no forecaster can run here',
      (tester) async {
    await tester.pumpWidget(harness(runnable: const []));
    await tester.pumpAndSettle();

    expect(find.text('Run the duel'), findsNothing);
  });

  testWidgets(
      'running the duel seals forecasts: count appears, content never does',
      (tester) async {
    await tester.pumpWidget(harness(
        runnable: [_persona('persona-base-rate-skeptic', 'Base-rate skeptic')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run the duel'));
    await tester.pumpAndSettle();

    // Both enabled personas dueled.
    expect(find.text('2 forecasts sealed'), findsOneWidget);
    expect(predictions.logged, hasLength(2));
    // R1: lean and rationale stay sealed on the open case — count only.
    expect(find.textContaining(_rationale), findsNothing);
    expect(find.textContaining('70'), findsNothing);
  });

  testWidgets('a case with prior sealed forecasts shows the count on entry',
      (tester) async {
    predictions.logged.add(_sealedForecast());

    await tester.pumpWidget(harness(runnable: const []));
    await tester.pumpAndSettle();

    expect(find.text('1 forecast sealed'), findsOneWidget);
    expect(find.textContaining(_rationale), findsNothing);
  });
}
