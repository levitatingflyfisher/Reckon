import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_id.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/repoll_schedule.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
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

/// Review-and-edit screen. The on-device model produces a best-effort draft
/// (and may leave fields blank); this screen lets the user fix anything and
/// finish the case, so saving is never blocked by what the small model got
/// right.
class CaseSummaryScreen extends ConsumerStatefulWidget {
  const CaseSummaryScreen({super.key, required this.draft});
  final CaseDraft draft;

  @override
  ConsumerState<CaseSummaryScreen> createState() => _CaseSummaryScreenState();
}

class _CaseSummaryScreenState extends ConsumerState<CaseSummaryScreen> {
  late final TextEditingController _question;
  late final TextEditingController _optionA;
  late final TextEditingController _optionB;
  late final TextEditingController _category;
  late Stakes _stakes;
  late RegretHorizon _horizon;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _question = TextEditingController(text: d.question);
    _optionA = TextEditingController(text: d.optionA);
    _optionB = TextEditingController(text: d.optionB);
    _category = TextEditingController(text: d.category ?? '');
    _stakes = d.stakes;
    _horizon = d.regretHorizon;
    _deadline = d.deadline;
  }

  @override
  void dispose() {
    _question.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _category.dispose();
    super.dispose();
  }

  bool get _valid =>
      _question.text.trim().isNotEmpty &&
      _optionA.text.trim().isNotEmpty &&
      _optionB.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Does this look right?')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Edit anything that isn’t quite right, then save it.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  _label('The decision'),
                  OHTextField(controller: _question, hint: 'What are you deciding?'),
                  const SizedBox(height: 16),
                  _label('Option A'),
                  OHTextField(controller: _optionA, hint: 'The first option'),
                  const SizedBox(height: 16),
                  _label('Option B'),
                  OHTextField(controller: _optionB, hint: 'The second option'),
                  const SizedBox(height: 20),
                  _label('Stakes'),
                  _chips<Stakes>(
                    Stakes.values, _stakes, (v) => setState(() => _stakes = v)),
                  const SizedBox(height: 16),
                  _label('When will you know if it was right?'),
                  _chips<RegretHorizon>(RegretHorizon.values, _horizon,
                      (v) => setState(() => _horizon = v)),
                  const SizedBox(height: 16),
                  _label('Category (optional)'),
                  OHTextField(controller: _category, hint: 'e.g. career, home'),
                ],
              ),
            ),
            OHButton(
              label: _saving ? 'Saving…' : 'Save this decision',
              expanded: true,
              onPressed: _saving ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _chips<T extends Enum>(
          List<T> values, T selected, ValueChanged<T> onPick) =>
      Wrap(
        spacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(v.name),
              selected: v == selected,
              onSelected: (_) => onPick(v),
            ),
        ],
      );

  Future<void> _confirm() async {
    if (_saving) return;
    if (!_valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add the decision and both options before saving.'),
      ));
      return;
    }
    setState(() => _saving = true);

    final createCase = ref.read(createCaseProvider);
    final case_ = await createCase(
      question: _question.text.trim(),
      optionA: _optionA.text.trim(),
      optionB: _optionB.text.trim(),
      criteria: widget.draft.statedCriteria,
      stakes: _stakes,
      regretHorizon: _horizon,
      deadline: _deadline,
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
    );

    final notif = ref.read(localNotificationServiceProvider);
    final granted = await notif.requestPermissions();
    if (granted) {
      final schedule = computeRepollSchedule(
        now: DateTime.now(),
        deadline: _deadline,
      );
      // Schedule in a best-effort loop — on Android, a single per-alarm
      // failure must not abort persistence of the case or block navigation.
      for (var i = 0; i < schedule.length; i++) {
        try {
          await notif.scheduleRepoll(
            id: notificationIdFor(case_.id, i),
            caseId: case_.id,
            caseTitle: _question.text.trim(),
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
