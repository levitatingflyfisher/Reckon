import 'dart:math' as math;

import '../../../record/domain/usecases/compute_insight_cards.dart';
import '../entities/forecaster_weights.dart';
import '../entities/model_prediction.dart';

/// Builds the deference map (see [ForecasterWeights]) from the two honest
/// sources: the persisted per-prediction duel scores, and the closed-case
/// records. Pure and recomputed on read — invariant R2.
///
/// Forecaster samples: every `duelForecast` prediction that has been scored
/// at resolution (`score` non-null), attributed via `payload.forecasterId`.
///
/// User samples: the final pre-decision poll of each resolved case, scored
/// on read with the SAME rule the forecasters faced —
///
///     pChosen   = chosen == 'b' ? lean / 100 : 1 - lean / 100
///     score     = (2 * pChosen - 1) * (satisfaction / 2)
///
/// so the ensemble includes you, on equal terms, without persisting a
/// single user metric.
///
/// Earned weight: `max(0, (mean + 1) / 2)` normalized over entries with at
/// least [ForecasterWeightEntry.minSampleCount] samples. Entries below the
/// bar are listed but weightless (null) and must not be compared.
class ComputeForecasterWeights {
  const ComputeForecasterWeights();

  ForecasterWeights call({
    required List<ModelPrediction> predictions,
    required List<ClosedCaseRecord> records,
  }) {
    final categoryByCase = {
      for (final r in records) r.case_.id: _category(r.case_.category),
    };

    // Forecaster samples from the persisted duel scores.
    final samplesById = <String, List<_Sample>>{};
    final nameById = <String, String>{};
    for (final p in predictions) {
      if (p.kind != PredictionKind.duelForecast) continue;
      final score = p.score;
      final forecasterId = p.payload['forecasterId'] as String?;
      if (score == null || forecasterId == null) continue;
      nameById[forecasterId] =
          (p.payload['forecasterName'] as String?) ?? forecasterId;
      samplesById.putIfAbsent(forecasterId, () => []).add(_Sample(
            score: score,
            category: categoryByCase[p.caseId] ?? _category(null),
          ));
    }

    // The user's samples, computed on read (R2) with the duel's own rule.
    final userSamples = <_Sample>[];
    for (final r in records) {
      final chosen = r.chosenOption;
      if (chosen == null || r.polls.isEmpty) continue;
      final lean = r.polls.last.lean.toDouble().clamp(0.0, 100.0);
      final pChosen = chosen == 'b' ? lean / 100 : 1 - lean / 100;
      userSamples.add(_Sample(
        score: (2 * pChosen - 1) * (r.satisfactionScore / 2),
        category: _category(r.case_.category),
      ));
    }

    final unweighted = <ForecasterWeightEntry>[
      _entry(
        forecasterId: ForecasterWeights.userEntryId,
        displayName: 'You',
        isUser: true,
        samples: userSamples,
      ),
      for (final e in samplesById.entries)
        _entry(
          forecasterId: e.key,
          displayName: nameById[e.key]!,
          isUser: false,
          samples: e.value,
        ),
    ];

    final entries = _withNormalizedWeights(unweighted)
      ..sort(_eligibleByWeightThenClosest);

    return ForecasterWeights(
      entries: entries,
      resolvedCaseCount: records.length,
    );
  }

  ForecasterWeightEntry _entry({
    required String forecasterId,
    required String displayName,
    required bool isUser,
    required List<_Sample> samples,
  }) {
    final byCategory = <String, List<double>>{};
    for (final s in samples) {
      byCategory.putIfAbsent(s.category, () => []).add(s.score);
    }
    final categories = [
      for (final e in byCategory.entries)
        CategoryScore(
          label: e.key,
          meanScore: _mean(e.value)!,
          sampleCount: e.value.length,
        ),
    ]..sort((a, b) => b.meanScore.compareTo(a.meanScore));

    return ForecasterWeightEntry(
      forecasterId: forecasterId,
      displayName: displayName,
      isUser: isUser,
      sampleCount: samples.length,
      meanScore: _mean([for (final s in samples) s.score]),
      byCategory: categories,
      weight: null, // assigned in _withNormalizedWeights
    );
  }

  List<ForecasterWeightEntry> _withNormalizedWeights(
      List<ForecasterWeightEntry> entries) {
    double raw(ForecasterWeightEntry e) =>
        math.max(0, ((e.meanScore ?? 0) + 1) / 2);
    final eligible = entries.where((e) => e.eligible).toList();
    final total = eligible.fold<double>(0, (sum, e) => sum + raw(e));
    return [
      for (final e in entries)
        if (!e.eligible)
          e
        else
          ForecasterWeightEntry(
            forecasterId: e.forecasterId,
            displayName: e.displayName,
            isUser: e.isUser,
            sampleCount: e.sampleCount,
            meanScore: e.meanScore,
            byCategory: e.byCategory,
            // All-eligible-at-the-floor is degenerate (every mean at -1);
            // everyone earns 0 rather than dividing by zero.
            weight: total > 0 ? raw(e) / total : 0.0,
          ),
    ];
  }

  static int _eligibleByWeightThenClosest(
      ForecasterWeightEntry a, ForecasterWeightEntry b) {
    if (a.eligible != b.eligible) return a.eligible ? -1 : 1;
    if (a.eligible) {
      final byWeight = (b.weight ?? 0).compareTo(a.weight ?? 0);
      if (byWeight != 0) return byWeight;
    }
    return b.sampleCount.compareTo(a.sampleCount);
  }

  static String _category(String? raw) => raw ?? 'uncategorized';

  static double? _mean(List<double> xs) => xs.isEmpty
      ? null
      : xs.fold<double>(0, (a, b) => a + b) / xs.length;
}

class _Sample {
  const _Sample({required this.score, required this.category});
  final double score;
  final String category;
}
