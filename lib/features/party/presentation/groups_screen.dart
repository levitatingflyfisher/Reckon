import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../data/group_providers.dart';

/// The circles you keep deciding with — household, couple, founding team.
/// Purely local: a group exists on this device because you created it here or
/// joined one of its decisions; there is no group server anywhere.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your groups')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No groups yet.', style: textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      'A group is the people you keep deciding with — your '
                      'household, your team. Decisions in a group build a '
                      'shared history, and its serious votes can stay sealed '
                      'until everyone has voted.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OHButton(
                      label: 'New group',
                      icon: Icons.group_add,
                      onPressed: () => context.push('/groups/create'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final g in groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OHCard(
                    onTap: () => context.push('/group/${g.id}'),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(g.name, style: textTheme.titleMedium),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OHButton(
                label: 'New group',
                style: OHButtonStyle.secondary,
                icon: Icons.group_add,
                expanded: true,
                onPressed: () => context.push('/groups/create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
