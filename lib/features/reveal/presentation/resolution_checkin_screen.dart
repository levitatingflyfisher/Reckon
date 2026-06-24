import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../../case/data/case_providers.dart';
import '../../record/data/record_providers.dart';
import '../data/resolution_providers.dart';

class ResolutionCheckInScreen extends ConsumerStatefulWidget {
  const ResolutionCheckInScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<ResolutionCheckInScreen> createState() =>
      _ResolutionCheckInScreenState();
}

class _ResolutionCheckInScreenState
    extends ConsumerState<ResolutionCheckInScreen> {
  int _score = 0;
  final _reflection = TextEditingController();

  static const _labels = {
    -2: 'Clearly wrong',
    -1: 'Probably wrong',
    0: 'Neutral',
    1: 'Probably right',
    2: 'Clearly right',
  };

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(resolutionRepositoryProvider).recordSatisfaction(
          caseId: widget.caseId,
          satisfactionScore: _score,
          reflection: _reflection.text.trim().isEmpty
              ? null
              : _reflection.text.trim(),
        );

    // The case is now closed and its outcome feeds the Record screen. Drop the
    // stale detail cache (#7) and the cached Record analytics (#6) so both
    // reflect the new closed case without an app restart.
    ref.invalidate(caseByIdProvider(widget.caseId));
    ref.invalidate(clarityScoreProvider);
    ref.invalidate(insightCardsProvider);
    ref.invalidate(closedCasesProvider);
    ref.invalidate(calibrationReportProvider);

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('How does this feel?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Looking back on the decision you made, how does it sit with you now?',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: [-2, -1, 0, 1, 2]
                  .map((s) => ChoiceChip(
                        label: Text(_labels[s]!),
                        selected: _score == s,
                        onSelected: (_) => setState(() => _score = s),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            OHTextField(
              controller: _reflection,
              label: 'One sentence (optional)',
              maxLines: 3,
            ),
            const Spacer(),
            OHButton(
              label: 'Done',
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
