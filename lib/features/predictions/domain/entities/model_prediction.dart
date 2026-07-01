enum PredictionKind {
  outsideView,
  repollSentiment,
  revealObservation,
  communitySeed,

  /// A forecaster's sealed lean on an open case, logged by the duel and
  /// scored per-prediction against the user's eventual satisfaction. Payload:
  /// `{lean, rationale, forecasterId, forecasterName}`. (Readers older than
  /// v0.4 coerce unknown kinds to [outsideView] via the firstWhere fallback —
  /// acceptable: they never scored or displayed duel rows anyway.)
  duelForecast,
}

class ModelPrediction {
  const ModelPrediction({
    required this.id,
    required this.caseId,
    required this.modelVersion,
    required this.kind,
    required this.predictedAt,
    required this.payload,
    this.score,
    this.scoredAt,
  });

  final String id;
  final String caseId;
  final String modelVersion;
  final PredictionKind kind;
  final DateTime predictedAt;
  final Map<String, dynamic> payload;
  final double? score;
  final DateTime? scoredAt;
}
