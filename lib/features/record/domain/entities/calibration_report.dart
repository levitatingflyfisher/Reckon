class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.count,
    required this.meanSatisfaction,
  });
  final String category;
  final int count;
  final double meanSatisfaction;
}

class ConfidenceBucket {
  const ConfidenceBucket({
    required this.label,
    required this.count,
    required this.meanSatisfaction,
  });
  final String label; // 'low' | 'medium' | 'high'
  final int count;
  final double meanSatisfaction;
}

class CalibrationReport {
  const CalibrationReport({
    required this.sampleCount,
    required this.categoryStats,
    required this.confidenceBuckets,
    required this.meanLeanDrift,
  });

  /// Number of closed cases with a satisfaction score.
  final int sampleCount;

  /// Per-category satisfaction stats, sorted by meanSatisfaction desc.
  final List<CategoryStat> categoryStats;

  /// Final-poll confidence level → satisfaction. Empty when no polls recorded.
  final List<ConfidenceBucket> confidenceBuckets;

  /// Mean max-to-min lean swing across polls, over all closed cases.
  /// Higher = more volatile thinking before deciding.
  final double meanLeanDrift;

  bool get hasEnoughData => sampleCount >= 5;
}
