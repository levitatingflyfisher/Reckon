import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_id.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/repoll_schedule.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../data/case_providers.dart';
import '../domain/entities/case.dart';
import '../domain/entities/criterion.dart';

class CaseDraft {
  const CaseDraft({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.stakes,
    required this.regretHorizon,
    required this.deadline,
    required this.statedCriteria,
    required this.category,
  });

  final String question;
  final String optionA;
  final String optionB;
  final Stakes stakes;
  final RegretHorizon regretHorizon;
  final DateTime? deadline;
  final List<Criterion> statedCriteria;
  final String? category;
}

class CaseSummaryScreen extends ConsumerStatefulWidget {
  const CaseSummaryScreen({super.key, required this.draft});
  final CaseDraft draft;

  @override
  ConsumerState<CaseSummaryScreen> createState() => _CaseSummaryScreenState();
}

class _CaseSummaryScreenState extends ConsumerState<CaseSummaryScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Does this look right?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OHCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.question, style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('A: ${draft.optionA}', style: textTheme.bodyLarge),
                  Text('B: ${draft.optionB}', style: textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Stakes: ${draft.stakes.name} · Horizon: ${draft.regretHorizon.name}',
                    style: textTheme.bodyMedium,
                  ),
                  if (draft.deadline != null)
                    Text('Deadline: ${draft.deadline}',
                        style: textTheme.bodyMedium),
                  if (draft.category != null)
                    Text('Category: ${draft.category}',
                        style: textTheme.bodyMedium),
                ],
              ),
            ),
            const Spacer(),
            OHButton(
              label: _saving ? 'Saving…' : 'Looks right',
              expanded: true,
              onPressed: _saving ? null : _confirm,
            ),
            const SizedBox(height: 12),
            OHButton(
              label: 'Edit',
              style: OHButtonStyle.secondary,
              expanded: true,
              onPressed: _saving ? null : () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);

    final draft = widget.draft;
    final createCase = ref.read(createCaseProvider);
    final case_ = await createCase(
      question: draft.question,
      optionA: draft.optionA,
      optionB: draft.optionB,
      criteria: draft.statedCriteria,
      stakes: draft.stakes,
      regretHorizon: draft.regretHorizon,
      deadline: draft.deadline,
      category: draft.category,
    );

    final notif = ref.read(localNotificationServiceProvider);
    final granted = await notif.requestPermissions();
    if (granted) {
      final schedule = computeRepollSchedule(
        now: DateTime.now(),
        deadline: draft.deadline,
      );
      // Schedule in a best-effort loop — on Android, a single per-alarm
      // failure must not abort persistence of the case or block navigation.
      for (var i = 0; i < schedule.length; i++) {
        try {
          await notif.scheduleRepoll(
            id: notificationIdFor(case_.id, i),
            caseId: case_.id,
            caseTitle: draft.question,
            when: schedule[i],
          );
        } catch (_) {
          // Swallow — the case is already persisted; missing reminders
          // degrade gracefully and the user can still open the case manually.
        }
      }
    }

    if (!mounted) return;
    // A decision journal lives on its nudges. If notification permission was
    // denied, say so plainly rather than silently dropping every reminder.
    if (!granted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reminders are off'),
          content: const Text(
            "Reckon's gentle re-poll check-ins won't fire without notification "
            'permission. Your case is saved either way — you can turn '
            'notifications on later in system settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }
    context.go('/stratification', extra: case_.id);
  }
}
