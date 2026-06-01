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

  test('unscored predictions yield null meanScore', () async {
    await predictions.log(make(model: 'new-model'));
    final card = await predictions.scorecard();
    final entry = card.firstWhere((e) => e.modelVersion == 'new-model');
    expect(entry.scoredCount, 0);
    expect(entry.meanScore, isNull);
  });
}
