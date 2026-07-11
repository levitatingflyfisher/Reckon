import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../record/data/record_providers.dart';
import '../../record/domain/entities/update_quality.dart';
import '../data/prediction_providers.dart';
import '../domain/entities/forecaster_weights.dart';

/// The deference map (successor of the model scorecard): every forecast
/// participant — the user included — listed with the weight its track
/// record has EARNED on this user's resolved decisions.
///
/// Language contract: weights are earned, never assumed, and never framed
/// as verdicts — no "X beats you", no advice. Below the small-sample bar
/// the screen shows honest progress copy instead of a comparison.
class ForecastersScreen extends ConsumerWidget {
  const ForecastersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final weights = ref.watch(forecasterWeightsProvider);
    final updates = ref.watch(updateQualityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Forecasters')),
      body: weights.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (map) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Every forecaster that duels your decisions — you included — '
              'earns weight from its record on the cases you resolved. '
              'Nothing here is a verdict; it is who has been worth '
              'listening to, so far, on your decisions.',
              style: textTheme.bodyMedium,
            ),
            if (!map.hasEnoughData) ...[
              const SizedBox(height: 16),
              OHCard(
                child: Text(
                  'Not enough resolved decisions to say — '
                  'resolve ${_needed(map)} more and the earned weights '
                  'appear here.',
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
            if (map.entries.isNotEmpty) ...[
              const SectionHeader(label: 'EARNED WEIGHT'),
              for (final entry in map.entries)
                _WeightTile(entry: entry, comparable: map.hasEnoughData),
            ],
            const SectionHeader(label: 'YOUR UPDATES'),
            updates.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('Error: $e'),
              data: (q) => _UpdatesCard(quality: q),
            ),
          ],
        ),
      ),
    );
  }

  static int _needed(ForecasterWeights map) {
    final missing =
        ForecasterWeightEntry.minSampleCount - map.resolvedCaseCount;
    return missing < 1 ? 1 : missing;
  }
}

/// One participant's earned record. Tapping toggles the per-category split.
class _WeightTile extends StatefulWidget {
  const _WeightTile({required this.entry, required this.comparable});

  final ForecasterWeightEntry entry;

  /// False while the whole map lacks data — then no entry shows a weight
  /// bar, only its sample progress.
  final bool comparable;

  @override
  State<_WeightTile> createState() => _WeightTileState();
}

class _WeightTileState extends State<_WeightTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final weight = widget.comparable ? entry.weight : null;
    final mean = entry.meanScore;
    final hasCategories = entry.byCategory.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OHCard(
        onTap:
            hasCategories ? () => setState(() => _expanded = !_expanded) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.displayName,
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (weight != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(weight * 100).round()}%',
                    style: textTheme.titleMedium,
                  ),
                ],
                if (hasCategories) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            if (weight != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: weight,
                  minHeight: 6,
                  backgroundColor:
                      colors.surfaceContainerHighest.withValues(alpha: 0.6),
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'earned weight — mean ${_signed(mean)} over '
                '${entry.sampleCount} scored',
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                widget.comparable
                    ? 'Too few scored forecasts to compare — '
                        '${ForecasterWeightEntry.minSampleCount - entry.sampleCount} more '
                        'and this record earns a weight.'
                    : '${entry.sampleCount} scored so far.',
                style: textTheme.bodySmall,
              ),
            ],
            if (_expanded && hasCategories) ...[
              const SizedBox(height: 12),
              for (final c in entry.byCategory)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.label,
                          style: textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_signed(c.meanScore)} · ${c.sampleCount}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _signed(double? x) => x == null
      ? '—'
      : '${x >= 0 ? '+' : ''}${x.toStringAsFixed(2)}';
}

/// "Your updates" — did re-polling walk toward the options you ended up
/// glad about? Positive framing throughout; the worst it ever says is
/// "worth noticing".
class _UpdatesCard extends StatelessWidget {
  const _UpdatesCard({required this.quality});

  final UpdateQuality quality;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mean = quality.mean;
    if (!quality.hasEnoughData || mean == null) {
      final needed = 5 - quality.sampleCount;
      return OHCard(
        child: Text(
          'Appears after $needed more resolved '
          'decision${needed == 1 ? '' : 's'} with at least two polls — '
          're-poll while a case is open and this fills in.',
          style: textTheme.bodyMedium,
        ),
      );
    }
    final String reading;
    if (mean >= 0.1) {
      reading = 'When you re-polled, you tended to move toward the option '
          'you ended up glad about. Your updates are working.';
    } else if (mean <= -0.1) {
      reading = 'Your re-polls often drifted toward options you later '
          'regretted — worth noticing next time your lean starts to move.';
    } else {
      reading = 'Your re-polls moved neither toward nor away from the '
          'options you were glad about.';
    }
    return OHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${mean >= 0 ? '+' : ''}${mean.toStringAsFixed(2)}',
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(reading, style: textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Across ${quality.sampleCount} decisions with two or more polls.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
