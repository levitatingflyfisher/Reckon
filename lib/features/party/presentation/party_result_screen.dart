import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/party_providers.dart';
import '../domain/entities/party.dart';
import '../domain/entities/party_result.dart';
import 'party_host_action.dart';

/// Live tally for a party. Recomputed on demand from on-device ballots. Offers
/// the pass-the-phone loop (add another voter), closing voting, sharing a text
/// summary, and handing a stuck group off into a full Reckon case.
class PartyResultScreen extends ConsumerWidget {
  const PartyResultScreen({super.key, required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyProvider(partyId));
    final resultAsync = ref.watch(partyResultProvider(partyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: partyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (party) {
          if (party == null) {
            return const Center(child: Text('This party no longer exists.'));
          }
          final labels = {for (final o in party.options) o.id: o.label};
          return resultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (result) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(party.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                if (result is ApprovalResult)
                  _ApprovalView(result: result, labels: labels)
                else if (result is RankedResult)
                  _RankedView(result: result, labels: labels),
                const SizedBox(height: 24),
                _Actions(party: party, labels: labels, result: result),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalView extends StatelessWidget {
  const _ApprovalView({required this.result, required this.labels});
  final ApprovalResult result;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${result.ballotCount} vote(s) · approval',
            style: textTheme.bodySmall),
        if (result.isContested)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Close call — the group is split.',
                style: textTheme.bodySmall),
          ),
        const SizedBox(height: 12),
        for (final t in result.tallies)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OHCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          labels[t.optionId] ?? t.optionId,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: result.winnerIds.contains(t.optionId)
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text('${t.approvals} · ${t.percentage.round()}%',
                          style: textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (t.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RankedView extends StatelessWidget {
  const _RankedView({required this.result, required this.labels});
  final RankedResult result;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${result.ballotCount} vote(s) · ranked (instant-runoff)',
            style: textTheme.bodySmall),
        const SizedBox(height: 12),
        OHCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Winner', style: textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                result.winnerId == null
                    ? 'No votes yet'
                    : labels[result.winnerId] ?? result.winnerId!,
                style: textTheme.titleLarge,
              ),
              if (result.isContested)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Took several rounds — a divided group.',
                      style: textTheme.bodySmall),
                ),
            ],
          ),
        ),
        if (result.rounds.length > 1) const SectionHeader(label: 'How it played out'),
        for (final round in result.rounds)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('R${round.roundNumber}',
                      style: textTheme.labelMedium),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          for (final t in round.tallies)
                            '${labels[t.optionId] ?? t.optionId} ${t.votes}'
                        ].join(' · '),
                        style: textTheme.bodyMedium,
                      ),
                      if (round.eliminatedOptionId != null)
                        Text(
                          'eliminated: ${labels[round.eliminatedOptionId] ?? round.eliminatedOptionId}',
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.party, required this.labels, required this.result});
  final Party party;
  final Map<String, String> labels;
  final Object result;

  String _summary() {
    final buf = StringBuffer('${party.title}\n');
    if (result is ApprovalResult) {
      final r = result as ApprovalResult;
      for (final t in r.tallies) {
        buf.writeln(
            '• ${labels[t.optionId] ?? t.optionId}: ${t.approvals} (${t.percentage.round()}%)');
      }
    } else if (result is RankedResult) {
      final r = result as RankedResult;
      final w = r.winnerId;
      buf.writeln('Winner: ${w == null ? '—' : labels[w] ?? w}');
    }
    buf.write('\nDecided with ReckonParty.');
    return buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!party.closed)
          OHButton(
            label: 'Pass to next voter',
            expanded: true,
            icon: Icons.how_to_vote,
            onPressed: () => context.go('/party/${party.id}/vote'),
          ),
        if (!party.closed) ...[
          const SizedBox(height: 12),
          PartyHostAction(partyId: party.id),
        ],
        const SizedBox(height: 12),
        OHButton(
          label: 'Share result',
          style: OHButtonStyle.secondary,
          expanded: true,
          icon: Icons.share,
          onPressed: () => Share.share(_summary()),
        ),
        const SizedBox(height: 12),
        if (!party.closed)
          OHButton(
            label: 'Close voting',
            style: OHButtonStyle.text,
            expanded: true,
            onPressed: () async {
              await ref.read(partyRepositoryProvider).closeParty(party.id);
              ref.invalidate(partyProvider(party.id));
            },
          ),
        OHButton(
          label: 'Turn this into a Reckon case',
          style: OHButtonStyle.text,
          expanded: true,
          onPressed: () => context.go('/intake'),
        ),
      ],
    );
  }
}
