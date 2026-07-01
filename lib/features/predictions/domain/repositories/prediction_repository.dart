import '../entities/model_prediction.dart';

abstract class PredictionRepository {
  Future<void> log(ModelPrediction p);

  Future<List<ModelPrediction>> forCase(String caseId);

  /// Apply one identical score to every prediction attached to [caseId].
  ///
  /// Superseded for the resolution flow by [scoreDuelForecasts] (a blanket
  /// score cannot tell a good forecast from a bad one on the same case, and
  /// observation kinds are not forecasts at all). Retained as a generic bulk
  /// tool; nothing in the app calls it today.
  Future<void> scoreForCase(
    String caseId, {
    required double score,
    required DateTime scoredAt,
  });

  /// Score each of [caseId]'s `duelForecast` predictions against what IT
  /// predicted, once the user has resolved the case.
  ///
  /// Lean orientation (verified against LeanSlider, LlmPrompts, and the
  /// reveal chart): 0 = fully optionA, 100 = fully optionB. The rule:
  ///
  ///     pChosen   = chosenOption == 'b' ? lean / 100 : 1 - lean / 100
  ///     alignment = 2 * pChosen - 1                       // in [-1, +1]
  ///     score     = alignment * (satisfaction / 2)        // in [-1, +1]
  ///
  /// Positive means the forecaster leaned toward the option the user ended
  /// up glad about; negative means it argued for the regretted one. A
  /// perfect forecaster (alignment 1) earns exactly the old blanket
  /// `satisfaction / 2`, so historical scores stay comparable. Kinds other
  /// than `duelForecast` are observations, not forecasts, and are
  /// deliberately left unscored (ADR-0007).
  Future<void> scoreDuelForecasts(
    String caseId, {
    required String chosenOption,
    required int satisfaction,
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
