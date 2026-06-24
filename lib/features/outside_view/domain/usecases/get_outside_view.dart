import 'package:uuid/uuid.dart';

import '../../../../core/llm/llm_service.dart';
import '../../../case/domain/entities/case.dart';
import '../../../predictions/domain/entities/model_prediction.dart';
import '../../../predictions/domain/repositories/prediction_repository.dart';
import '../entities/citation.dart';
import '../entities/outside_view.dart';
import '../repositories/outside_view_repository.dart';

class GetOutsideView {
  GetOutsideView(this._repo, this._llm, this._predictions, [Uuid? uuid])
      : _uuid = uuid ?? const Uuid();

  final OutsideViewRepository _repo;
  final LlmService _llm;
  final PredictionRepository _predictions;
  final Uuid _uuid;

  /// Returns the outside view for [case_], generating it on-device only if one
  /// hasn't been produced before. Pass [force] to regenerate. Without this
  /// guard the screen re-ran a slow LLM synthesis and logged a duplicate
  /// prediction on every visit, multiplying rows and skewing the scorecard.
  Future<OutsideView> call(Case case_, {bool force = false}) async {
    if (!force) {
      final existing = await _repo.getForCase(case_.id);
      if (existing != null) return existing;
    }

    final category = case_.category ?? 'career';
    final ref = await _repo.findReferenceClass(category);
    if (ref == null) {
      throw StateError('No reference class for category "$category"');
    }
    final profile = await _repo.getUserProfile();
    final result = await _llm.synthesizeOutsideView(case_, ref, profile);

    // Citations come from the curated reference class, never the LLM —
    // snapshotted onto the record so it stays honest if the reference DB
    // is updated later.
    final citations = ref.sources.map(Citation.fromJson).toList();

    final now = DateTime.now();
    final view = OutsideView(
      id: _uuid.v4(),
      caseId: case_.id,
      generatedAt: now,
      baseRateSummary: result.baseRateSummary,
      referenceClassUsed: result.referenceClassUsed,
      uncertaintyLevel: result.uncertaintyLevel,
      stratificationFactors: result.stratificationFactors,
      llmMode: 'private',
      modelVersion: result.modelVersion,
      citations: citations,
    );
    await _repo.save(view);

    await _predictions.log(ModelPrediction(
      id: _uuid.v4(),
      caseId: case_.id,
      modelVersion: result.modelVersion,
      kind: PredictionKind.outsideView,
      predictedAt: now,
      payload: {
        'baseRateSummary': result.baseRateSummary,
        'referenceClassUsed': result.referenceClassUsed,
        'uncertaintyLevel': result.uncertaintyLevel,
      },
    ));

    return view;
  }
}
