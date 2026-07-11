import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/group_providers.dart';
import '../domain/entities/party.dart';

/// A group's home: who is in it, the decisions it has made (and is making),
/// and the door to a new one. History is the point — a household's choices
/// accumulate here instead of vanishing with each one-shot poll.
class GroupHomeScreen extends ConsumerWidget {
  const GroupHomeScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final partiesAsync = ref.watch(groupPartiesProvider(groupId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          loading: () => const Text(''),
          error: (_, __) => const Text('Group'),
          data: (g) => Text(g?.name ?? 'Group'),
        ),
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (group) {
          if (group == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('This group is not on this device. Join one of '
                    'its shared decisions to adopt it.'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(label: 'Members'),
              membersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (members) => members.isEmpty
                    ? Text(
                        'No named members yet — names arrive with votes.',
                        style: textTheme.bodySmall,
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in members)
                            Chip(
                              avatar: const Icon(Icons.person_outline,
                                  size: 18),
                              label: Text(m.displayName),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              OHButton(
                label: 'New decision',
                icon: Icons.how_to_vote,
                expanded: true,
                onPressed: () =>
                    context.push('/party/create?groupId=$groupId'),
              ),
              const SectionHeader(label: 'Decisions'),
              partiesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (parties) => parties.isEmpty
                    ? Text('No decisions yet.', style: textTheme.bodySmall)
                    : Column(
                        children: [
                          for (final p in parties)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DecisionTile(party: p),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({required this.party});
  final Party party;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return OHCard(
      onTap: () => context.push('/party/${party.id}/result'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(party.title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  party.closed
                      ? 'Closed'
                      : party.resultsSealed
                          ? 'Voting — results sealed'
                          : 'Voting',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (party.resultsSealed) const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
