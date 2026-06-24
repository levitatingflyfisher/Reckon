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
