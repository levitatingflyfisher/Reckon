import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../case/data/case_providers.dart';
import '../data/outside_view_providers.dart';
import 'citation_list.dart';

class OutsideViewScreen extends ConsumerStatefulWidget {
  const OutsideViewScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<OutsideViewScreen> createState() => _OutsideViewScreenState();
}

class _OutsideViewScreenState extends ConsumerState<OutsideViewScreen> {
  bool _generating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    try {
      final case_ = await ref.read(caseByIdProvider(widget.caseId).future);
      if (case_ == null) throw StateError('Case not found');
      final uc = await ref.read(getOutsideViewProvider.future);
      await uc(case_);
      if (mounted) {
        setState(() => _generating = false);
        ref.invalidate(outsideViewForCaseProvider(widget.caseId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final view = ref.watch(outsideViewForCaseProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Outside view')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scroll the synthesis so a long base-rate summary (or large
            // accessibility text scale) can't overflow the column behind the
            // pinned action button.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_generating)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Text('Error: $_error', style: textTheme.bodyLarge)
                    else
                      view.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                        data: (v) {
                          if (v == null) return const SizedBox.shrink();
                          return OHCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reference class: ${v.referenceClassUsed}',
                                    style: textTheme.labelLarge),
                                const SizedBox(height: 12),
                                Text(v.baseRateSummary,
                                    style: textTheme.bodyLarge),
                                const SizedBox(height: 16),
                                Text('Uncertainty: ${v.uncertaintyLevel}',
                                    style: textTheme.bodySmall),
                                if (v.citations.isNotEmpty) ...[
                                  const Divider(height: 24),
                                  CitationList(citations: v.citations),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OHButton(
              label: "I'll live with it for a while",
              expanded: true,
              onPressed: () => context.go('/case/${widget.caseId}'),
            ),
          ],
        ),
      ),
    );
  }
}
