import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_id.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../case/data/case_providers.dart';
import '../data/resolution_providers.dart';

class ResolutionDateScreen extends ConsumerStatefulWidget {
  const ResolutionDateScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<ResolutionDateScreen> createState() =>
      _ResolutionDateScreenState();
}

class _ResolutionDateScreenState extends ConsumerState<ResolutionDateScreen> {
  DateTime? _date;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    final chosen = GoRouterState.of(context).uri.queryParameters['chosen'] ?? 'a';
    if (_date == null) return;

    final repo = ref.read(resolutionRepositoryProvider);
    await repo.create(
      caseId: widget.caseId,
      chosenOption: chosen,
      decidedAt: DateTime.now(),
      resolutionCheckDate: _date!,
    );

    final notif = ref.read(localNotificationServiceProvider);
    try {
      await notif.scheduleResolutionCheckIn(
        id: notificationIdFor(widget.caseId, resolutionSlot),
        caseId: widget.caseId,
        when: _date!,
      );
    } catch (_) {
      // Best-effort — the resolution row is already saved.
    }

    // The case status flipped to `resolving`; drop the cached `decided`
    // value so Case Detail doesn't re-offer "Set resolution date".
    ref.invalidate(caseByIdProvider(widget.caseId));

    if (mounted) context.go('/case/${widget.caseId}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('When should we check back in?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Pick a date when you'll know how this decision feels in your life. It can be weeks, months, or years from now.",
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            OHButton(
              label: _date == null
                  ? 'Pick a date'
                  : 'Check in on ${DateFormat.yMMMEd().format(_date!)}',
              style: OHButtonStyle.secondary,
              expanded: true,
              onPressed: _pick,
            ),
            const Spacer(),
            OHButton(
              label: 'Schedule check-in',
              expanded: true,
              onPressed: _date == null ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
