import '../entities/model_prediction.dart';

abstract class PredictionRepository {
  Future<void> log(ModelPrediction p);

  Future<List<ModelPrediction>> forCase(String caseId);

  /// Apply a score to every prediction attached to [caseId]. A prediction's
  /// score is a signed calibration proxy: positive means the model's output
  /// aligned with the eventual satisfaction signal, negative means it was
  /// misleading. The exact scoring rule is the caller's choice.
  Future<void> scoreForCase(
    String caseId, {
    required double score,
    required DateTime scoredAt,
  });

  /// Aggregate counts + mean scores per modelVersion, across scored
  /// predictions only.
  Future<List<ModelScorecardEntry>> scorecard();
}

class ModelScorecardEntry {
  const ModelScorecardEntry({
    required this.modelVersion,
    required this.totalPredictions,
    required this.scoredCount,
    required this.meanScore,
  });
  final String modelVersion;
  final int totalPredictions;
  final int scoredCount;
  final double? meanScore;
}
