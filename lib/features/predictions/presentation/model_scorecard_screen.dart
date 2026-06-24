import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/prediction_providers.dart';
import '../domain/repositories/prediction_repository.dart';

class ModelScorecardScreen extends ConsumerWidget {
  const ModelScorecardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final card = ref.watch(modelScorecardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Model scorecard')),
      body: card.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No model predictions logged yet. Open a case and let Reckon generate an outside view — that will show up here.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Each prediction a model makes is logged and, once a case resolves, scored against your satisfaction. A higher mean score means the model tended to produce predictions attached to cases you ended up satisfied with.',
                style: textTheme.bodyMedium,
              ),
              const SectionHeader(label: 'MODELS'),
              for (final entry in entries) _ScorecardTile(entry: entry),
            ],
          );
        },
      ),
    );
  }
}

class _ScorecardTile extends StatelessWidget {
  const _ScorecardTile({required this.entry});
  final ModelScorecardEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final score = entry.meanScore;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OHCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.modelVersion, style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat(
                  context,
                  label: 'Predictions',
                  value: '${entry.totalPredictions}',
                ),
                const SizedBox(width: 24),
                _stat(
                  context,
                  label: 'Scored',
                  value: '${entry.scoredCount}',
                ),
                const SizedBox(width: 24),
                _stat(
                  context,
                  label: 'Mean score',
                  value: score == null ? '—' : score.toStringAsFixed(2),
                ),
              ],
            ),
            if (score != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (score + 1) / 2,
                minHeight: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  score >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context,
      {required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelSmall),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}
