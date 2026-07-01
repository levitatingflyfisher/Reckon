/// The deference map: every forecast participant — the user included — with
/// the weight its track record has EARNED on this user's resolved decisions.
///
/// Nothing here is ever persisted; the whole shape is recomputed on read
/// from the prediction log and the closed-case records (invariant R2 — the
/// per-prediction `ModelPredictions.score` is the one sanctioned persisted
/// input). Weights are descriptive ("who has earned deference so far"),
/// never prescriptive: the app must not phrase them as verdicts.
class ForecasterWeights {
  const ForecasterWeights({
    required this.entries,
    required this.resolvedCaseCount,
  });

  /// The reserved [ForecasterWeightEntry.forecasterId] for the user's own
  /// entry. Forecaster ids are uuids or namespaced (`persona-…`, `bounty:…`),
  /// so the bare word cannot collide.
  static const userEntryId = 'you';

  /// Eligible entries first, best earned weight first; then the
  /// not-yet-eligible, closest to eligibility first.
  final List<ForecasterWeightEntry> entries;

  /// How many resolved (closed, satisfaction-scored) cases fed this map.
  final int resolvedCaseCount;

  /// True once at least one entry has an earned weight to show. Below this
  /// the screen shows progress copy, never a comparison.
  bool get hasEnoughData => entries.any((e) => e.eligible);
}

/// One participant's earned track record.
class ForecasterWeightEntry {
  const ForecasterWeightEntry({
    required this.forecasterId,
    required this.displayName,
    required this.isUser,
    required this.sampleCount,
    required this.meanScore,
    required this.byCategory,
    required this.weight,
  });

  /// Scored samples required before an entry earns a comparable weight —
  /// the house small-sample guard (mirrors ClarityScore/CalibrationReport).
  static const minSampleCount = 5;

  final String forecasterId;
  final String displayName;

  /// The user's own computed-on-read entry (final pre-decision poll of each
  /// resolved case, scored by the same alignment rule as the forecasters).
  final bool isUser;

  /// Scored samples backing [meanScore].
  final int sampleCount;

  /// Mean alignment score over scored samples, in [-1, +1]; null when there
  /// are no samples yet.
  final double? meanScore;

  /// Mean + count per case category, sorted by mean, best first.
  final List<CategoryScore> byCategory;

  /// Share of earned weight in [0, 1]: `max(0, (mean + 1) / 2)` normalized
  /// over eligible entries. Null while ineligible — a two-sample hot streak
  /// must not outrank an earned record, so low-n entries are listed but
  /// never weighted or compared.
  final double? weight;

  bool get eligible => sampleCount >= minSampleCount;
}

/// Per-category slice of an entry's record.
class CategoryScore {
  const CategoryScore({
    required this.label,
    required this.meanScore,
    required this.sampleCount,
  });

  final String label;
  final double meanScore;
  final int sampleCount;
}
