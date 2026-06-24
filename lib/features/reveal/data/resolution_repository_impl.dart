import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../case/domain/entities/case.dart';
import '../../predictions/domain/repositories/prediction_repository.dart';
import 'resolution_repository.dart';

class ResolutionRepositoryImpl implements ResolutionRepository {
  ResolutionRepositoryImpl(this._db, {PredictionRepository? predictions, Uuid? uuid})
      : _predictions = predictions,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final PredictionRepository? _predictions;
  final Uuid _uuid;

  @override
  Future<void> create({
    required String caseId,
    required String chosenOption,
    required DateTime decidedAt,
    required DateTime resolutionCheckDate,
  }) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.resolutions)
            ..where((t) => t.caseId.equals(caseId)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.resolutions).insert(
              ResolutionsCompanion.insert(
                id: _uuid.v4(),
                caseId: caseId,
                decidedAt: decidedAt,
                chosenOption: chosenOption,
                resolutionCheckDate: resolutionCheckDate,
              ),
            );
      } else {
        await (_db.update(_db.resolutions)
              ..where((t) => t.id.equals(existing.id)))
            .write(ResolutionsCompanion(
          chosenOption: Value(chosenOption),
          decidedAt: Value(decidedAt),
          resolutionCheckDate: Value(resolutionCheckDate),
        ));
      }
      await (_db.update(_db.cases)..where((t) => t.id.equals(caseId))).write(
        CasesCompanion(status: Value(CaseStatus.resolving.name)),
      );
    });
  }

  @override
  Future<List<ScoredResolution>> scoredResolutions() async {
    final rows = await (_db.select(_db.resolutions)
          ..where((t) => t.satisfactionScore.isNotNull()))
        .get();
    return rows
        .map((r) => ScoredResolution(
              caseId: r.caseId,
              satisfactionScore: r.satisfactionScore!,
            ))
        .toList();
  }

  @override
  Future<void> recordSatisfaction({
    required String caseId,
    required int satisfactionScore,
    String? reflection,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.resolutions)
            ..where((t) => t.caseId.equals(caseId)))
          .write(ResolutionsCompanion(
        satisfactionScore: Value(satisfactionScore),
        reflection: Value(reflection),
      ));
      await (_db.update(_db.cases)..where((t) => t.id.equals(caseId))).write(
        CasesCompanion(status: Value(CaseStatus.closed.name)),
      );
    });
    // Score any predictions tied to this case. Scoring rule: satisfaction
    // is the outcome signal, normalised from -2..+2 onto -1..+1 so mean
    // scores are comparable across cases regardless of satisfaction range.
    // Opt-in per construction — tests that build the repo without a
    // prediction store will skip this step.
    await _predictions?.scoreForCase(
      caseId,
      score: satisfactionScore / 2.0,
      scoredAt: DateTime.now(),
    );
  }
}
