abstract class ResolutionRepository {
  Future<void> create({
    required String caseId,
    required String chosenOption,
    required DateTime decidedAt,
    required DateTime resolutionCheckDate,
  });

  Future<void> recordSatisfaction({
    required String caseId,
    required int satisfactionScore,
    String? reflection,
  });

  /// Every caseId that has a recorded satisfaction score, paired with
  /// that score. Used by the Record tab analytics — lets presentation
  /// layers stay off the AppDatabase.
  Future<List<ScoredResolution>> scoredResolutions();
}

class ScoredResolution {
  const ScoredResolution({
    required this.caseId,
    required this.satisfactionScore,
    required this.chosenOption,
  });
  final String caseId;
  final int satisfactionScore;

  /// 'a' or 'b' — which option the user went with. Lets record analytics
  /// score the user's own final poll with the same alignment rule the duel
  /// forecasters are scored by (computed on read, never persisted — R2).
  final String chosenOption;
}
