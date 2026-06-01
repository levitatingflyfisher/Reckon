import '../../../case/domain/entities/poll.dart';
import '../entities/calibration_report.dart';
import 'compute_insight_cards.dart';

class ComputeCalibrationReport {
  const ComputeCalibrationReport();

  CalibrationReport call(List<ClosedCaseRecord> records) {
    final categoryStats = _categoryStats(records);
    final confidenceBuckets = _confidenceBuckets(records);
    final meanLeanDrift = _meanLeanDrift(records);
    return CalibrationReport(
      sampleCount: records.length,
      categoryStats: categoryStats,
      confidenceBuckets: confidenceBuckets,
      meanLeanDrift: meanLeanDrift,
    );
  }

  List<CategoryStat> _categoryStats(List<ClosedCaseRecord> records) {
    final byCategory = <String, List<int>>{};
    for (final r in records) {
      final cat = r.case_.category ?? 'uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(r.satisfactionScore);
    }
    final stats = byCategory.entries.map((e) {
      final sum = e.value.fold<int>(0, (a, b) => a + b);
      return CategoryStat(
        category: e.key,
        count: e.value.length,
        meanSatisfaction: sum / e.value.length,
      );
    }).toList()
      ..sort((a, b) => b.meanSatisfaction.compareTo(a.meanSatisfaction));
    return stats;
  }

  List<ConfidenceBucket> _confidenceBuckets(List<ClosedCaseRecord> records) {
    final byConfidence = <Confidence, List<int>>{};
    for (final r in records) {
      if (r.polls.isEmpty) continue;
      final last = r.polls.last;
      byConfidence
          .putIfAbsent(last.confidence, () => [])
          .add(r.satisfactionScore);
    }
    return Confidence.values
        .where(byConfidence.containsKey)
        .map((c) {
          final scores = byConfidence[c]!;
          final sum = scores.fold<int>(0, (a, b) => a + b);
          return ConfidenceBucket(
            label: c.name,
            count: scores.length,
            meanSatisfaction: sum / scores.length,
          );
        })
        .toList();
  }

  double _meanLeanDrift(List<ClosedCaseRecord> records) {
    final drifts = <int>[];
    for (final r in records) {
      if (r.polls.length < 2) continue;
      final leans = r.polls.map((p) => p.lean).toList();
      final hi = leans.reduce((a, b) => a > b ? a : b);
      final lo = leans.reduce((a, b) => a < b ? a : b);
      drifts.add(hi - lo);
    }
    if (drifts.isEmpty) return 0;
    return drifts.fold<int>(0, (a, b) => a + b) / drifts.length;
  }
}
