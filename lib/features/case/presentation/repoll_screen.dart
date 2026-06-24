import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/llm/llm_providers.dart';
import '../../../core/llm/llm_service.dart';
import '../../../shared/widgets/lean_slider.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../data/case_providers.dart';
import '../domain/entities/poll.dart';

class RepollScreen extends ConsumerStatefulWidget {
  const RepollScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<RepollScreen> createState() => _RepollScreenState();
}

class _RepollScreenState extends ConsumerState<RepollScreen> {
  double _lean = 50;
  Confidence _confidence = Confidence.medium;
  final _rationale = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  MismatchResult? _mismatch;

  @override
  void dispose() {
    _rationale.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    final addPoll = ref.read(addPollProvider);
    await addPoll(
      caseId: widget.caseId,
      lean: _lean.round(),
      confidence: _confidence,
      rationale: _rationale.text.trim().isEmpty ? null : _rationale.text.trim(),
    );

    if (_rationale.text.trim().isNotEmpty) {
      try {
        final llm = await ref.read(llmServiceProvider.future);
        final result = await llm.detectRepollSentiment(
          _lean.round(),
          _rationale.text.trim(),
        );
        if (mounted) setState(() => _mismatch = result);
      } catch (e) {
        // Mismatch detection is best-effort; never blocks save.
        debugPrint('Re-poll mismatch detection failed: $e');
      }
    }

    ref.invalidate(pollsForCaseProvider(widget.caseId));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    // If there is no mismatch to read, auto-pop so the user isn't stuck
    // on a latched "Saved" screen with no obvious next step. When a
    // mismatch did surface, stay on-screen so they can read it.
    if (_mismatch?.mismatch != true) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go('/case/${widget.caseId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseAsync = ref.watch(caseByIdProvider(widget.caseId));
    return Scaffold(
      appBar: AppBar(title: const Text('Re-poll')),
      body: caseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (case_) {
          if (case_ == null) return const Center(child: Text('Not found'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OHCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(case_.question,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Stakes: ${case_.stakes.name}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Where are you leaning today?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                LeanSlider(
                  value: _lean,
                  onChanged: (v) => setState(() => _lean = v),
                  optionA: case_.optionA,
                  optionB: case_.optionB,
                ),
                const SizedBox(height: 24),
                OHTextField(
                  controller: _rationale,
                  label: 'Rationale (optional)',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: Confidence.values
                      .map((c) => ChoiceChip(
                            label: Text(c.name),
                            selected: _confidence == c,
                            onSelected: (_) => setState(() => _confidence = c),
                          ))
                      .toList(),
                ),
                if (_mismatch?.mismatch == true) ...[
                  const SizedBox(height: 16),
                  OHCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Worth noticing',
                                  style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 4),
                              Text(_mismatch!.observation,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _mismatch = null),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                OHButton(
                  label: _saved
                      ? 'Saved'
                      : (_saving ? 'Saving...' : 'Save'),
                  expanded: true,
                  onPressed: (_saving || _saved) ? null : _save,
                ),
                const SizedBox(height: 8),
                OHButton(
                  label: 'Done',
                  style: OHButtonStyle.text,
                  onPressed: () => context.go('/case/${widget.caseId}'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
