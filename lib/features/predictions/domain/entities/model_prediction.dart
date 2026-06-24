enum PredictionKind {
  outsideView,
  repollSentiment,
  revealObservation,
  communitySeed,
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
