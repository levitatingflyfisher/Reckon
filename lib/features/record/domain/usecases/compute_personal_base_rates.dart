import '../../../case/domain/entities/poll.dart';
import '../entities/personal_base_rates.dart';
import 'compute_insight_cards.dart';

/// Mines your closed, scored cases into personal base rates — your own
/// reference class. The headline is the confidence curve: how often you ended
/// up glad, grouped by how certain you felt when you last re-polled, plus a
/// direct overconfidence signal comparing your most- and least-confident calls.
class ComputePersonalBaseRates {
  const ComputePersonalBaseRates();

  PersonalBaseRates call(List<ClosedCaseRecord> records) {
    final byCategory = _rates(
      records,
      key: (r) => r.case_.category ?? 'uncategorized',
    )..sort((a, b) => b.gladRate.compareTo(a.gladRate));

    final byConfidence = _confidenceRates(records);

    return PersonalBaseRates(
      sampleCount: records.length,
      byCategory: byCategory,
      byConfidence: byConfidence,
      overconfidenceGap: _overconfidenceGap(byConfidence),
    );
  }

  List<PersonalBaseRate> _rates(
    List<ClosedCaseRecord> records, {
    required String Function(ClosedCaseRecord) key,
  }) {
    final groups = <String, List<int>>{};
    for (final r in records) {
      groups.putIfAbsent(key(r), () => []).add(r.satisfactionScore);
    }
    return [
      for (final e in groups.entries) _rateOf(e.key, e.value),
    ];
  }

  /// Confidence is taken from the last re-poll (the belief you acted on),
  /// matching how the calibration report buckets confidence. Ordered low→high.
  List<PersonalBaseRate> _confidenceRates(List<ClosedCaseRecord> records) {
    final byConfidence = <Confidence, List<int>>{};
    for (final r in records) {
      if (r.polls.isEmpty) continue;
      byConfidence
          .putIfAbsent(r.polls.last.confidence, () => [])
          .add(r.satisfactionScore);
    }
    return [
      for (final c in Confidence.values)
        if (byConfidence.containsKey(c)) _rateOf(c.name, byConfidence[c]!),
    ];
  }

  PersonalBaseRate _rateOf(String label, List<int> scores) {
    final glad = scores.where((s) => s > 0).length;
    final sum = scores.fold<int>(0, (a, b) => a + b);
    return PersonalBaseRate(
      label: label,
      sampleCount: scores.length,
      gladRate: glad / scores.length,
      meanSatisfaction: sum / scores.length,
    );
  }

  /// Needs at least two distinct confidence levels present; compares the most-
  /// to least-confident slice. `byConfidence` is already ordered low→high.
  double? _overconfidenceGap(List<PersonalBaseRate> byConfidence) {
    if (byConfidence.length < 2) return null;
    return byConfidence.last.gladRate - byConfidence.first.gladRate;
  }
}
