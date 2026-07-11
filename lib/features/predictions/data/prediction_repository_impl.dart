import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/model_prediction.dart';
import '../domain/repositories/prediction_repository.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  PredictionRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> log(ModelPrediction p) async {
    await _db.into(_db.modelPredictions).insert(
          ModelPredictionsCompanion.insert(
            id: p.id,
            caseId: p.caseId,
            modelVersion: p.modelVersion,
            kind: p.kind.name,
            predictedAt: p.predictedAt,
            payload: p.payload,
            score: Value(p.score),
            scoredAt: Value(p.scoredAt),
          ),
        );
  }

  @override
  Future<List<ModelPrediction>> forCase(String caseId) async {
    final rows = await (_db.select(_db.modelPredictions)
          ..where((t) => t.caseId.equals(caseId))
          ..orderBy([(t) => OrderingTerm.asc(t.predictedAt)]))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> scoreForCase(
    String caseId, {
    required double score,
    required DateTime scoredAt,
  }) async {
    await (_db.update(_db.modelPredictions)
          ..where((t) => t.caseId.equals(caseId)))
        .write(ModelPredictionsCompanion(
      score: Value(score),
      scoredAt: Value(scoredAt),
    ));
  }

  @override
  Future<void> scoreDuelForecasts(
    String caseId, {
    required String chosenOption,
    required int satisfaction,
    required DateTime scoredAt,
  }) async {
    final rows = await (_db.select(_db.modelPredictions)
          ..where((t) =>
              t.caseId.equals(caseId) &
              t.kind.equals(PredictionKind.duelForecast.name)))
        .get();
    await _db.transaction(() async {
      for (final row in rows) {
        // Payload lean: 0 = fully optionA, 100 = fully optionB (the same
        // orientation as LeanSlider and the reveal chart). A missing OR
        // malformed lean reads as 50 (R4) — a no-signal forecast that
        // scores 0 either way; throwing here would strand every forecast
        // on the case unscored, with the case already closed.
        final rawLean = row.payload['lean'];
        final lean =
            (rawLean is num ? rawLean.toDouble() : 50.0).clamp(0.0, 100.0);
        final pChosen = chosenOption == 'b' ? lean / 100 : 1 - lean / 100;
        final score = (2 * pChosen - 1) * (satisfaction / 2);
        await (_db.update(_db.modelPredictions)
              ..where((t) => t.id.equals(row.id)))
            .write(ModelPredictionsCompanion(
          score: Value(score),
          scoredAt: Value(scoredAt),
        ));
      }
    });
  }

  @override
  Future<List<ModelScorecardEntry>> scorecard() async {
    final rows = await _db.select(_db.modelPredictions).get();
    final byModel = <String, List<ModelPredictionRow>>{};
    for (final r in rows) {
      byModel.putIfAbsent(r.modelVersion, () => []).add(r);
    }
    return byModel.entries.map((e) {
      final scored = e.value.where((r) => r.score != null).toList();
      final mean = scored.isEmpty
          ? null
          : scored.fold<double>(0, (a, b) => a + b.score!) / scored.length;
      return ModelScorecardEntry(
        modelVersion: e.key,
        totalPredictions: e.value.length,
        scoredCount: scored.length,
        meanScore: mean,
      );
    }).toList()
      ..sort((a, b) => b.totalPredictions.compareTo(a.totalPredictions));
  }

  ModelPrediction _toEntity(ModelPredictionRow r) => ModelPrediction(
        id: r.id,
        caseId: r.caseId,
        modelVersion: r.modelVersion,
        kind: PredictionKind.values.firstWhere(
          (k) => k.name == r.kind,
          orElse: () => PredictionKind.outsideView,
        ),
        predictedAt: r.predictedAt,
        payload: r.payload,
        score: r.score,
        scoredAt: r.scoredAt,
      );
}
