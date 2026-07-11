import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/predictions/data/prediction_repository_impl.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/repositories/prediction_repository.dart';
import 'package:reckon/features/reveal/data/resolution_repository_impl.dart';

/// A prediction store whose duel scoring always fails — the crash/DB-error
/// window between "case closed" and "forecasts scored".
class _ThrowingPredictions implements PredictionRepository {
  @override
  Future<void> scoreDuelForecasts(String caseId,
          {required String chosenOption,
          required int satisfaction,
          required DateTime scoredAt}) =>
      throw StateError('scoring blew up');
  @override
  Future<void> log(ModelPrediction p) async {}
  @override
  Future<List<ModelPrediction>> forCase(String caseId) async => [];
  @override
  Future<void> scoreForCase(String caseId,
      {required double score, required DateTime scoredAt}) async {}
  @override
  Future<List<ModelScorecardEntry>> scorecard() async => [];
}

void main() {
  late AppDatabase db;
  late ResolutionRepositoryImpl repo;
  late CaseRepositoryImpl cases;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ResolutionRepositoryImpl(db);
    cases = CaseRepositoryImpl(db);
    await cases.insert(Case(
      id: 'c1',
      createdAt: DateTime(2026, 4, 10),
      deadline: null,
      status: CaseStatus.decided,
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

  Future<int> resolutionCount() async {
    final rows = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .get();
    return rows.length;
  }

  test('create inserts a resolution row and flips case status to resolving',
      () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    final case_ = await cases.getById('c1');
    expect(case_!.status, CaseStatus.resolving);
    expect(await resolutionCount(), 1);
  });

  test('create is idempotent — re-entry updates the existing row', () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    await repo.create(
      caseId: 'c1',
      chosenOption: 'b',
      decidedAt: DateTime(2026, 4, 12),
      resolutionCheckDate: DateTime(2026, 11, 12),
    );
    expect(await resolutionCount(), 1, reason: 'must not insert a duplicate');
    final row = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .getSingle();
    expect(row.chosenOption, 'b');
    expect(row.resolutionCheckDate, DateTime(2026, 11, 12));
  });

  test('scoredResolutions returns (caseId, satisfactionScore) tuples only for scored rows',
      () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    expect(await repo.scoredResolutions(), isEmpty,
        reason: 'pre-satisfaction rows must be excluded');
    await repo.recordSatisfaction(
      caseId: 'c1',
      satisfactionScore: 1,
    );
    final list = await repo.scoredResolutions();
    expect(list, hasLength(1));
    expect(list.single.caseId, 'c1');
    expect(list.single.satisfactionScore, 1);
    expect(list.single.chosenOption, 'a',
        reason: 'record analytics need the chosen option to score '
            'the user\'s own final poll with the duel formula');
  });

  test(
      'recordSatisfaction scores duel forecasts per-prediction and leaves '
      'observations unscored', () async {
    final predictions = PredictionRepositoryImpl(db);
    final scoringRepo = ResolutionRepositoryImpl(db, predictions: predictions);
    await predictions.log(ModelPrediction(
      id: 'duel-1',
      caseId: 'c1',
      modelVersion: 'gemma-3-1b-it#f1',
      kind: PredictionKind.duelForecast,
      predictedAt: DateTime(2026, 4, 11),
      payload: const {'lean': 75, 'rationale': 'r', 'forecasterId': 'f1'},
    ));
    await predictions.log(ModelPrediction(
      id: 'obs-1',
      caseId: 'c1',
      modelVersion: 'gemma-3-1b-it',
      kind: PredictionKind.revealObservation,
      predictedAt: DateTime(2026, 4, 11),
      payload: const {'summary': 'an observation'},
    ));
    await scoringRepo.create(
      caseId: 'c1',
      chosenOption: 'b',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    await scoringRepo.recordSatisfaction(caseId: 'c1', satisfactionScore: 2);

    final logged = await predictions.forCase('c1');
    final duel = logged.firstWhere((p) => p.id == 'duel-1');
    final obs = logged.firstWhere((p) => p.id == 'obs-1');
    // lean 75 toward the chosen b: p_chosen .75 -> alignment .5 -> x 1 = .5
    expect(duel.score, closeTo(0.5, 1e-9));
    expect(obs.score, isNull,
        reason: 'observations are not forecasts and must not be scored');
  });

  test(
      'a scoring failure rolls the whole check-in back — the case stays '
      'resolving and can be re-checked-in, never closed-but-unscored',
      () async {
    final failing =
        ResolutionRepositoryImpl(db, predictions: _ThrowingPredictions());
    await failing.create(
      caseId: 'c1',
      chosenOption: 'b',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );

    await expectLater(
      failing.recordSatisfaction(caseId: 'c1', satisfactionScore: 2),
      throwsA(isA<StateError>()),
    );

    final case_ = await cases.getById('c1');
    expect(case_!.status, CaseStatus.resolving,
        reason: 'closing the case while its forecasts stay unscored would '
            'silently drop them from every track record — no code path '
            're-scores a closed case');
    final row = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .getSingle();
    expect(row.satisfactionScore, isNull,
        reason: 'the satisfaction write and the scoring must commit or '
            'fail as one');
  });

  test('recordSatisfaction writes score + closes the case', () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    await repo.recordSatisfaction(
      caseId: 'c1',
      satisfactionScore: 2,
      reflection: 'glad I chose a',
    );
    final case_ = await cases.getById('c1');
    expect(case_!.status, CaseStatus.closed);
    final row = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .getSingle();
    expect(row.satisfactionScore, 2);
    expect(row.reflection, 'glad I chose a');
  });
}
