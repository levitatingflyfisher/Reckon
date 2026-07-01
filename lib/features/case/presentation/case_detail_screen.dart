import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../forecasters/data/forecaster_providers.dart';
import '../../outside_view/data/outside_view_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import '../data/case_providers.dart';
import '../domain/entities/case.dart';

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));
    final pollsAsync = ref.watch(pollsForCaseProvider(caseId));
    final viewAsync = ref.watch(outsideViewForCaseProvider(caseId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case'),
        actions: [
          // Bounty export/import lives behind the overflow: open cases only —
          // once the user has decided, outside forecasts can't be sealed.
          if (caseAsync.valueOrNull?.status == CaseStatus.open)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'bounty') context.push('/bounty/$caseId');
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'bounty',
                  child: Text('Ask outside bots'),
                ),
              ],
            ),
        ],
      ),
      body: caseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (case_) {
          if (case_ == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OHCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(case_.question, style: textTheme.displayMedium),
                    const SizedBox(height: 12),
                    Text('A: ${case_.optionA}', style: textTheme.bodyLarge),
                    Text('B: ${case_.optionB}', style: textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Stakes: ${case_.stakes.name}  ·  Horizon: ${case_.regretHorizon.name}',
                      style: textTheme.bodyMedium,
                    ),
                    if (case_.deadline != null)
                      Text(
                        'Deadline: ${DateFormat.yMMMd().format(case_.deadline!)}',
                        style: textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SectionHeader(label: 'OUTSIDE VIEW'),
              viewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (v) => v == null
                    ? OHCard(
                        onTap: () => context.push('/outside-view/$caseId'),
                        child: const Text('Tap to generate outside view'),
                      )
                    : OHCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.referenceClassUsed,
                                style: textTheme.labelLarge),
                            const SizedBox(height: 8),
                            Text(v.baseRateSummary, style: textTheme.bodyLarge),
                          ],
                        ),
                      ),
              ),
              const SectionHeader(label: 'POLLS'),
              pollsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (polls) {
                  if (polls.isEmpty) {
                    return Text(
                      'No polls yet. Use "Re-poll now" to record your current lean.',
                      style: textTheme.bodyMedium,
                    );
                  }
                  final revealed = polls.any((p) => p.revealed);
                  if (!revealed) {
                    return Text(
                      '${polls.length} poll${polls.length == 1 ? '' : 's'} recorded. They stay hidden until you tap "I\'ve decided".',
                      style: textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: [
                      for (final p in polls)
                        OHCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Poll ${p.pollNumber} · lean ${p.lean}',
                                style: textTheme.labelLarge,
                              ),
                              if (p.rationale != null && p.rationale!.isNotEmpty)
                                Text(p.rationale!, style: textTheme.bodyMedium),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (case_.status == CaseStatus.open) ...[
                const SectionHeader(label: 'THE DUEL'),
                _DuelCard(case_: case_),
              ],
              const SizedBox(height: 24),
              if (case_.status == CaseStatus.open)
                Column(
                  children: [
                    OHButton(
                      label: 'Re-poll now',
                      expanded: true,
                      onPressed: () => context.push('/repoll/$caseId'),
                    ),
                    const SizedBox(height: 12),
                    OHButton(
                      label: "I've decided",
                      style: OHButtonStyle.secondary,
                      expanded: true,
                      onPressed: () => context.push('/reveal/$caseId'),
                    ),
                  ],
                ),
              if (case_.status == CaseStatus.decided)
                OHButton(
                  label: 'Set resolution date',
                  expanded: true,
                  onPressed: () => context.push('/reveal/$caseId'),
                ),
              if (case_.status == CaseStatus.resolving)
                OHButton(
                  label: 'Resolution check-in',
                  expanded: true,
                  onPressed: () =>
                      context.push('/resolution-checkin/$caseId'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The duel block on an OPEN case. Honesty invariant R1: while the case is
/// open, nothing here may reveal what any forecaster thinks — only that
/// forecasts exist. Lean and rationale first render on the reveal screen,
/// after the user has committed to a choice.
class _DuelCard extends ConsumerStatefulWidget {
  const _DuelCard({required this.case_});

  final Case case_;

  @override
  ConsumerState<_DuelCard> createState() => _DuelCardState();
}

class _DuelCardState extends ConsumerState<_DuelCard> {
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(runDuelProvider).call(widget.case_);
      ref.invalidate(duelForecastsForCaseProvider(widget.case_.id));
      // Counts only — a snackbar must not leak forecast content (R1).
      final text = result.ran > 0
          ? '${result.ran} new forecast${result.ran == 1 ? '' : 's'} sealed'
              '${result.failed > 0 ? ' · ${result.failed} failed' : ''}'
          : result.failed > 0
              ? 'No forecasts sealed — ${result.failed} failed. Try again.'
              : 'Every forecaster has already answered.';
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      // RunDuel's setup phase (roster fetch/seeding, the forCase query)
      // runs before its internal per-forecaster try — a throw there would
      // otherwise vanish as an unhandled zone error while the button just
      // popped back, looping the user through the same silent failure.
      // Naming the error leaks no forecast content (R1).
      messenger.showSnackBar(
          SnackBar(content: Text("The duel couldn't run: $e")));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sealedCount = ref
            .watch(duelForecastsForCaseProvider(widget.case_.id))
            .valueOrNull
            ?.length ??
        0;
    final runnable =
        ref.watch(runnableForecastersProvider).valueOrNull ?? const [];

    if (sealedCount == 0 && runnable.isEmpty) {
      return Text(
        'No forecaster can run here yet — add one in Settings.',
        style: textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sealedCount > 0)
          OHCard(
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$sealedCount forecast'
                        '${sealedCount == 1 ? '' : 's'} sealed',
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        'Revealed once you commit your decision — '
                        'your read stays yours until then.',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (runnable.isNotEmpty) ...[
          if (sealedCount > 0) const SizedBox(height: 12),
          if (_running)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            )
          else
            OHButton(
              label: 'Run the duel',
              style: OHButtonStyle.secondary,
              expanded: true,
              onPressed: _run,
            ),
        ],
      ],
    );
  }
}
