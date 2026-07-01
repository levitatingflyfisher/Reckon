import '../entities/update_quality.dart';
import 'compute_insight_cards.dart';

/// Scores the DIRECTION of the user's belief updates against how the
/// decision eventually felt (the yellow-paper "update quality" formula).
///
/// For each closed case with at least two polls and a recorded choice:
///
///     pChosen(poll) = chosen == 'b' ? lean / 100 : 1 - lean / 100
///     q_case = clamp((pChosen(last) - pChosen(first)) * satisfaction, -1, 1)
///
/// with satisfaction raw in -2..+2 (NOT halved: a two-step swing toward a
/// "clearly right" choice deserves the full clamp range, and the clamp keeps
/// q_case in [-1, +1] regardless). Movement toward the option the user
/// ended up glad about scores positive; movement toward the regretted one,
/// negative; neutral satisfaction (0) carries no signal. Only the first and
/// last polls matter — intermediate wobble is neither rewarded nor punished.
/// The aggregate is the plain mean over qualifying cases.
class ComputeUpdateQuality {
  const ComputeUpdateQuality();

  UpdateQuality call(List<ClosedCaseRecord> records) {
    final qs = <double>[];
    for (final r in records) {
      final chosen = r.chosenOption;
      if (chosen == null || r.polls.length < 2) continue;
      final first = _pChosen(r.polls.first.lean, chosen);
      final last = _pChosen(r.polls.last.lean, chosen);
      qs.add(((last - first) * r.satisfactionScore).clamp(-1.0, 1.0));
    }
    return UpdateQuality(
      mean: qs.isEmpty
          ? null
          : qs.fold<double>(0, (a, b) => a + b) / qs.length,
      sampleCount: qs.length,
    );
  }

  /// Lean orientation: 0 = fully optionA, 100 = fully optionB.
  static double _pChosen(int lean, String chosen) {
    final l = lean.toDouble().clamp(0.0, 100.0);
    return chosen == 'b' ? l / 100 : 1 - l / 100;
  }
}
