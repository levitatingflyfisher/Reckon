/// Your own decision track record, sliced the way an external reference class
/// is — except the data is *you*. This is what powers the "second brain":
/// instead of (or alongside) population base rates, Reckon can tell you how
/// your past self actually fared, by category and by how certain you felt.
class PersonalBaseRate {
  const PersonalBaseRate({
    required this.label,
    required this.sampleCount,
    required this.gladRate,
    required this.meanSatisfaction,
  });

  /// The slice this rate describes — a category ("career") or a confidence
  /// level ("high").
  final String label;

  /// How many closed, scored cases fall in this slice.
  final int sampleCount;

  /// Fraction of those cases you ended up glad about (satisfaction > 0).
  final double gladRate;

  /// Mean satisfaction score across the slice (scale is signed: <0 regret,
  /// >0 glad).
  final double meanSatisfaction;
}

class PersonalBaseRates {
  const PersonalBaseRates({
    required this.sampleCount,
    required this.byCategory,
    required this.byConfidence,
    required this.overconfidenceGap,
  });

  final int sampleCount;

  /// Glad-rate by decision category, highest first.
  final List<PersonalBaseRate> byCategory;

  /// Glad-rate by the confidence you felt at your last re-poll, ordered from
  /// least to most confident — the personal calibration curve.
  final List<PersonalBaseRate> byConfidence;

  /// gladRate(most-confident slice) − gladRate(least-confident slice), when you
  /// have samples spanning more than one confidence level. **Negative means
  /// your high-confidence calls fared worse than your hesitant ones** — a
  /// concrete, personal overconfidence signal. `null` when there isn't enough
  /// spread to say anything honest.
  final double? overconfidenceGap;

  /// Below this we don't pretend the numbers mean anything (mirrors the
  /// insight-card threshold).
  static const minSamples = 5;

  bool get hasEnoughData => sampleCount >= minSamples;
}
