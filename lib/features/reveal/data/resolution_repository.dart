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
  });
  final String caseId;
  final int satisfactionScore;
}
