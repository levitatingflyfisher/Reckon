import '../../../case/domain/entities/case.dart';
import '../../../case/domain/entities/poll.dart';
import '../entities/insight_card.dart';

class ClosedCaseRecord {
  const ClosedCaseRecord({
    required this.case_,
    required this.polls,
    required this.satisfactionScore,
  });
  final Case case_;
  final List<Poll> polls;
  final int satisfactionScore;
}

class ComputeInsightCards {
  const ComputeInsightCards();

  List<InsightCard> call(List<ClosedCaseRecord> records) {
    if (records.length < 5) return const [];
    final cards = <InsightCard>[];

    final byCategory = <String, List<int>>{};
    for (final r in records) {
      final cat = r.case_.category ?? 'uncategorized';
      byCategory.putIfAbsent(cat, () => []).add(r.satisfactionScore);
    }
    if (byCategory.length > 1) {
      final means = byCategory.map((k, v) =>
          MapEntry(k, v.reduce((a, b) => a + b) / v.length));
      final sorted = means.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      cards.add(InsightCard(
        title: 'Category patterns',
        body:
            'Your highest-satisfaction category is ${sorted.first.key}; your lowest is ${sorted.last.key}.',
      ));
    }

    int driftyHighSat = 0;
    int steadyHighSat = 0;
    int drifty = 0;
    int steady = 0;
    for (final r in records) {
      if (r.polls.length < 2) continue;
      final leans = r.polls.map((p) => p.lean).toList();
      final maxDrift = leans.reduce((a, b) => a > b ? a : b) -
          leans.reduce((a, b) => a < b ? a : b);
      if (maxDrift > 20) {
        drifty++;
        if (r.satisfactionScore > 0) driftyHighSat++;
      } else {
        steady++;
        if (r.satisfactionScore > 0) steadyHighSat++;
      }
    }
    if (drifty > 0 && steady > 0) {
      final driftyRate = driftyHighSat / drifty;
      final steadyRate = steadyHighSat / steady;
      if ((driftyRate - steadyRate).abs() > 0.2) {
        cards.add(InsightCard(
          title: 'Drift vs steadiness',
          body: driftyRate > steadyRate
              ? 'Cases where your lean drifted >20 points ended up feeling better on average than cases where it held steady.'
              : 'Cases where your lean held steady ended up feeling better on average than cases where it drifted >20 points.',
        ));
      }
    }

    int mismatchCount = 0;
    for (final r in records) {
      final criteriaWords = r.case_.statedCriteria
          .map((c) => c.label.toLowerCase())
          .toSet();
      final rationaleWords = r.polls
          .where((p) => p.rationale != null)
          .expand((p) => p.rationale!.toLowerCase().split(RegExp(r'\s+')))
          .toSet();
      final overlap =
          criteriaWords.where(rationaleWords.contains).length;
      if (overlap < criteriaWords.length / 2) mismatchCount++;
    }
    if (mismatchCount > records.length / 3) {
      cards.add(const InsightCard(
        title: 'Criteria vs rationale',
        body:
            'Your rationales at re-poll time often mention different things than the criteria you named at intake. Worth noticing.',
      ));
    }

    return cards.take(3).toList();
  }
}
