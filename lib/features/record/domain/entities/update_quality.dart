/// Did your re-polling move you toward the options you ended up glad about?
///
/// Computed on read from closed cases (never persisted — R2). Positive mean:
/// your updates tended to walk toward the choice that later felt right.
/// Negative: they tended to drift toward what you came to regret. The exact
/// per-case formula lives on `ComputeUpdateQuality`.
class UpdateQuality {
  const UpdateQuality({
    required this.mean,
    required this.sampleCount,
  });

  /// Mean per-case update quality in [-1, +1]; null when no case qualifies.
  final double? mean;

  /// Closed cases with at least two polls and a recorded choice.
  final int sampleCount;

  /// House small-sample guard: below five qualifying cases the screen shows
  /// progress copy, not a number.
  bool get hasEnoughData => sampleCount >= 5;
}
