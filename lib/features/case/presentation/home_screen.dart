import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/oh_card.dart';
import '../data/case_providers.dart';
import '../domain/entities/case.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(openCasesStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reckon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Group decision',
            onPressed: () => context.push('/party/create'),
          ),
        ],
      ),
      body: casesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cases) {
          if (cases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No open cases yet.',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap + to open your first decision.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CaseTile(case_: cases[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/intake'),
        icon: const Icon(Icons.add),
        label: const Text('New case'),
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.case_});
  final Case case_;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deadline = case_.deadline;
    final fmt = DateFormat.yMMMd();
    return OHCard(
      onTap: () => context.push('/case/${case_.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(case_.question, style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${case_.optionA}  vs  ${case_.optionB}',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(status: case_.status),
              const SizedBox(width: 8),
              if (deadline != null)
                Text('by ${fmt.format(deadline)}', style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (status) {
      CaseStatus.open => 'Open',
      CaseStatus.decided => 'Decided',
      CaseStatus.resolving => 'Resolving',
      CaseStatus.closed => 'Closed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: colors.onPrimaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
