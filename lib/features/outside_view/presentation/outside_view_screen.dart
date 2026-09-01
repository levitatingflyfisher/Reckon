import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../case/data/case_providers.dart';
import '../data/outside_view_providers.dart';
import 'citation_list.dart';
import '../../../core/llm/llm_providers.dart';

class OutsideViewScreen extends ConsumerStatefulWidget {
  const OutsideViewScreen({super.key, required this.caseId});
  final String caseId;

  @override
  ConsumerState<OutsideViewScreen> createState() => _OutsideViewScreenState();
}

class _OutsideViewScreenState extends ConsumerState<OutsideViewScreen> {
  bool _generating = true;
  Object? _error;
  StackTrace? _errorStack;

  /// Whether this build can run the on-device model the outside view is
  /// written by (false on web).
  late final bool _hasRuntime = ref.read(onDeviceModelSupportedProvider);

  /// Null until checked: the runtime is there and the selected model is on
  /// disk. Only then is the outside view generated.
  bool? _hasModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ready = await ref.read(onDeviceModelReadyProvider.future);
      if (!mounted) return;
      setState(() {
        _hasModel = ready;
        if (!ready) _generating = false;
      });
      if (ready) await _generate();
    });
  }

  Future<void> _generate() async {
    try {
      final case_ = await ref.read(caseByIdProvider(widget.caseId).future);
      if (case_ == null) throw StateError('Decision not found');
      final uc = await ref.read(getOutsideViewProvider.future);
      await uc(case_);
      if (mounted) {
        setState(() => _generating = false);
        ref.invalidate(outsideViewForCaseProvider(widget.caseId));
      }
    } catch (e, st) {
      debugPrint('Reckon: building the outside view failed: $e');
      if (mounted) {
        setState(() {
          _generating = false;
          _error = e;
          _errorStack = st;
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
      body: OhPage(
        padding: EdgeInsets.zero,
        child: Padding(
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
                      if (_hasModel == false)
                        OHCard(
                          child: Text(
                            _hasRuntime
                                ? 'The outside view (how decisions like this one '
                                    'usually turn out) is written by the on-device '
                                    'model, and none is downloaded yet. Your decision '
                                    'is saved. Download one in Settings, then open '
                                    'the outside view from the decision.'
                                : 'The outside view (how decisions like this one '
                                    'usually turn out) is written by the on-device '
                                    "model, and this browser can’t run one. Your "
                                    'decision is saved. Open it in the Android app to '
                                    'get an outside view.',
                            style: textTheme.bodyLarge,
                          ),
                        )
                      else if (_generating)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        OhErrorState.fromError(
                          _error!,
                          stackTrace: _errorStack,
                          title: "Couldn’t build the outside view",
                          onRetry: () {
                            setState(() {
                              _error = null;
                              _generating = true;
                            });
                            _generate();
                          },
                        )
                      else
                        view.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => OhErrorState.fromError(e,
              stackTrace: st, title: "Couldn’t load the outside view"),
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
                label: "I’ll live with it for a while",
                expanded: true,
                onPressed: () => context.go('/case/${widget.caseId}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
