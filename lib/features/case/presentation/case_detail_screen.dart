import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../outside_view/data/outside_view_providers.dart';
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
      appBar: AppBar(title: const Text('Case')),
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
