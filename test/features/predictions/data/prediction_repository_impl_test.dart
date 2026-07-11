import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/predictions/data/prediction_repository_impl.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';

void main() {
  late AppDatabase db;
  late PredictionRepositoryImpl predictions;
  late CaseRepositoryImpl cases;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    predictions = PredictionRepositoryImpl(db);
    cases = CaseRepositoryImpl(db);
    await cases.insert(Case(
      id: 'c1',
      createdAt: DateTime(2026, 4, 10),
      deadline: null,
      status: CaseStatus.closed,
      question: 'q',
      optionA: 'a',
      optionB: 'b',
      statedCriteria: const [Criterion(label: 'x', weight: 1.0)],
      stakes: Stakes.medium,
      regretHorizon: RegretHorizon.months,
      category: null,
    ));
  });

  tearDown(() => db.close());

  ModelPrediction make({
    String id = 'p1',
    String model = 'gemma-3-1b-it',
    PredictionKind kind = PredictionKind.outsideView,
  }) =>
      ModelPrediction(
        id: id,
        caseId: 'c1',
        modelVersion: model,
        kind: kind,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'summary': 'a prediction'},
      );

  test('log + forCase round-trips a prediction', () async {
    await predictions.log(make());
    final list = await predictions.forCase('c1');
    expect(list, hasLength(1));
    expect(list.first.kind, PredictionKind.outsideView);
    expect(list.first.payload['summary'], 'a prediction');
  });

  test('scoreForCase applies score to every prediction for the case', () async {
    await predictions.log(make(id: 'p1'));
    await predictions.log(make(id: 'p2', kind: PredictionKind.revealObservation));
    await predictions.scoreForCase(
      'c1',
      score: 0.5,
      scoredAt: DateTime(2026, 10, 12),
    );
    final list = await predictions.forCase('c1');
    expect(list.every((p) => p.score == 0.5), isTrue);
    expect(list.every((p) => p.scoredAt == DateTime(2026, 10, 12)), isTrue);
  });

  test('scorecard aggregates per-model counts and mean scores', () async {
    await predictions.log(make(id: 'p1', model: 'gemma-3-1b-it'));
    await predictions.log(make(id: 'p2', model: 'gemma-3-1b-it'));
    await predictions.log(make(id: 'p3', model: 'phi-4-mini'));
    await predictions.scoreForCase('c1',
        score: 1.0, scoredAt: DateTime(2026, 10, 12));

    final card = await predictions.scorecard();
    final gemma = card.firstWhere((e) => e.modelVersion == 'gemma-3-1b-it');
    final phi = card.firstWhere((e) => e.modelVersion == 'phi-4-mini');
    expect(gemma.totalPredictions, 2);
    expect(gemma.scoredCount, 2);
    expect(gemma.meanScore, 1.0);
    expect(phi.totalPredictions, 1);
    expect(phi.meanScore, 1.0);
  });

  test('duelForecast kind round-trips through persistence', () async {
    await predictions.log(make(kind: PredictionKind.duelForecast));
    final list = await predictions.forCase('c1');
    expect(list.single.kind, PredictionKind.duelForecast);
  });

  group('scoreDuelForecasts', () {
    ModelPrediction duel({required String id, required int lean}) =>
        ModelPrediction(
          id: id,
          caseId: 'c1',
          modelVersion: 'gemma-3-1b-it#$id',
          kind: PredictionKind.duelForecast,
          predictedAt: DateTime(2026, 4, 11),
          payload: {'lean': lean, 'rationale': 'r', 'forecasterId': id},
        );

    Future<ModelPrediction> byId(String id) async =>
        (await predictions.forCase('c1')).firstWhere((p) => p.id == id);

    test('scores each duel forecast against what IT predicted', () async {
      // lean 80 = strongly toward optionB; the user chose b and was glad.
      await predictions.log(duel(id: 'd1', lean: 80));
      // lean 20 = strongly toward optionA; same case, same outcome.
      await predictions.log(duel(id: 'd2', lean: 20));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      // p_chosen = .8 -> alignment .6 -> x (2/2) = .6
      expect((await byId('d1')).score, closeTo(0.6, 1e-9));
      // p_chosen = .2 -> alignment -.6 -> x (2/2) = -.6
      expect((await byId('d2')).score, closeTo(-0.6, 1e-9));
      expect((await byId('d1')).scoredAt, DateTime(2026, 10, 12));
    });

    test('orientation flips when the user chose optionA', () async {
      await predictions.log(duel(id: 'd1', lean: 80));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'a',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      // p_chosen = 1 - .8 = .2 -> alignment -.6 -> -.6
      expect((await byId('d1')).score, closeTo(-0.6, 1e-9));
    });

    test('negative satisfaction flips the sign — leaning toward a regretted '
        'choice scores positive', () async {
      await predictions.log(duel(id: 'd1', lean: 80));
      await predictions.log(duel(id: 'd2', lean: 20));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: -1,
        scoredAt: DateTime(2026, 10, 12),
      );
      // Agreed with the regretted choice: .6 x (-1/2) = -.3
      expect((await byId('d1')).score, closeTo(-0.3, 1e-9));
      // Warned against it: -.6 x (-1/2) = .3
      expect((await byId('d2')).score, closeTo(0.3, 1e-9));
    });

    test('a 50/50 lean scores zero whatever happened', () async {
      await predictions.log(duel(id: 'd1', lean: 50));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      expect((await byId('d1')).score, closeTo(0, 1e-9));
      expect((await byId('d1')).scoredAt, isNotNull,
          reason: 'a zero score is still a scored forecast');
    });

    test(
        'a malformed (non-numeric) lean reads as 50 — R4 — instead of '
        'throwing and stranding the whole case unscored', () async {
      await predictions.log(ModelPrediction(
        id: 'd-bad',
        caseId: 'c1',
        modelVersion: 'm#d-bad',
        kind: PredictionKind.duelForecast,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'lean': '70', 'forecasterId': 'd-bad'},
      ));
      await predictions.log(duel(id: 'd-good', lean: 80));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      // The string lean is no-signal: alignment 0, but still scored.
      expect((await byId('d-bad')).score, closeTo(0, 1e-9));
      expect((await byId('d-bad')).scoredAt, isNotNull);
      expect((await byId('d-good')).score, closeTo(0.6, 1e-9),
          reason: 'one malformed payload must not block the rest');
    });

    test('observation kinds are NOT scored — they are not forecasts',
        () async {
      await predictions.log(make(id: 'o1', kind: PredictionKind.outsideView));
      await predictions
          .log(make(id: 'o2', kind: PredictionKind.revealObservation));
      await predictions.log(duel(id: 'd1', lean: 80));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      expect((await byId('o1')).score, isNull);
      expect((await byId('o2')).score, isNull);
      expect((await byId('d1')).score, isNotNull);
    });

    test('only the given case is touched', () async {
      await cases.insert(Case(
        id: 'c2',
        createdAt: DateTime(2026, 4, 10),
        deadline: null,
        status: CaseStatus.closed,
        question: 'q2',
        optionA: 'a',
        optionB: 'b',
        statedCriteria: const [],
        stakes: Stakes.medium,
        regretHorizon: RegretHorizon.months,
        category: null,
      ));
      await predictions.log(duel(id: 'd1', lean: 80));
      await predictions.log(ModelPrediction(
        id: 'other',
        caseId: 'c2',
        modelVersion: 'm',
        kind: PredictionKind.duelForecast,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'lean': 80},
      ));
      await predictions.scoreDuelForecasts(
        'c1',
        chosenOption: 'b',
        satisfaction: 2,
        scoredAt: DateTime(2026, 10, 12),
      );
      final other =
          (await predictions.forCase('c2')).single;
      expect(other.score, isNull);
    });
  });

  test('unscored predictions yield null meanScore', () async {
    await predictions.log(make(model: 'new-model'));
    final card = await predictions.scorecard();
    final entry = card.firstWhere((e) => e.modelVersion == 'new-model');
    expect(entry.scoredCount, 0);
    expect(entry.meanScore, isNull);
  });
}
