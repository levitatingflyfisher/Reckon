import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_card.dart';
import '../../case/data/case_providers.dart';
import '../../case/domain/entities/case.dart';
import '../../export/data/share_export.dart';
import '../../forecasters/data/forecaster_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import '../data/bounty_providers.dart';
import '../domain/bounty_codec.dart';

/// Ask outside bots (the reckonBounty interface, v0: files and paste).
///
/// Ask tab: a de-identified request is drafted (on-device model when one is
/// resident, by hand otherwise), ALWAYS shown in an editable preview, and
/// leaves the device only when the user shares or copies the file.
///
/// Import tab: pasted BountyResponse JSON becomes sealed duel forecasts —
/// counts are shown, content never is (R1: the app reveals no forecast
/// before the user's own decision; the pasted text itself is the user's
/// artifact, outside the app's control).
///
/// Both surfaces exist only while the case is open: once the user has
/// decided, outside forecasts can no longer be sealed against the decision.
class BountyScreen extends ConsumerWidget {
  const BountyScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseByIdProvider(caseId));
    return Scaffold(
      appBar: AppBar(title: const Text('Ask outside bots')),
      body: caseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (case_) {
          if (case_ == null) {
            return const Center(child: Text('Not found'));
          }
          if (case_.status != CaseStatus.open) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'This decision is already decided — outside forecasts can '
                  'only be added while a case is open.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Ask'), Tab(text: 'Import')]),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AskTab(case_: case_),
                      _ImportTab(case_: case_),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ask — redaction preview + export
// ---------------------------------------------------------------------------

class _AskTab extends ConsumerStatefulWidget {
  const _AskTab({required this.case_});

  final Case case_;

  @override
  ConsumerState<_AskTab> createState() => _AskTabState();
}

class _AskTabState extends ConsumerState<_AskTab>
    with AutomaticKeepAliveClientMixin {
  final _title = TextEditingController();
  final _background = TextEditingController();

  /// `local-llm` | `manual` once the draft is ready; null while drafting.
  String? _redaction;

  // Keep the user's edits alive across tab switches.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _draft();
  }

  @override
  void dispose() {
    _title.dispose();
    _background.dispose();
    super.dispose();
  }

  Future<void> _draft() async {
    final result = await ref.read(redactQuestionProvider)(
      title: widget.case_.question,
      background: BountyCodec.draftBackground(widget.case_),
    );
    if (!mounted) return;
    setState(() {
      _title.text = result.title;
      _background.text = result.background;
      _redaction = result.redaction;
    });
  }

  String _requestJson() {
    // Horizon: the resolution check date when one exists, else the deadline.
    // Export is only offered on open cases, which cannot have a resolutions
    // row yet — so the deadline (or nothing) is what an open case knows.
    final request = BountyCodec.buildRequest(
      widget.case_,
      title: _title.text.trim(),
      background: _background.text.trim(),
      redaction: _redaction ?? 'manual',
      horizon: widget.case_.deadline,
    );
    return const JsonEncoder.withIndent('  ').convert(request);
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final shortId = widget.case_.id.length > 8
          ? widget.case_.id.substring(0, 8)
          : widget.case_.id;
      await shareExport(
        content: _requestJson(),
        fileName: 'reckon-bounty-request-$shortId.json',
        subject: 'Reckon bounty request',
        text: 'A de-identified decision question (reckonBounty v0.1).',
      );
    } catch (e) {
      final message = e is UnsupportedError
          ? (e.message ?? 'Sharing is not available here yet.')
          : 'Share failed: $e';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _requestJson()));
    messenger.showSnackBar(
        const SnackBar(content: Text('Request JSON copied.')));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OHCard(
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nothing leaves this device until you share the file. '
                  'Check it reads like a stranger wrote it.',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_redaction == null) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Drafting a de-identified version…',
              style: textTheme.bodySmall),
        ] else ...[
          Text(
            _redaction == 'local-llm'
                ? 'Drafted by the on-device model — read it over before '
                    'sharing.'
                : 'No on-device model here, so redact by hand: strip names, '
                    'employers, and places.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('bounty-title'),
            controller: _title,
            decoration: const InputDecoration(labelText: 'Question'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('bounty-background'),
            controller: _background,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Background'),
          ),
          const SizedBox(height: 16),
          Text(
            'A: ${widget.case_.optionA}\nB: ${widget.case_.optionB}',
            style: textTheme.bodyMedium,
          ),
          Text(
            'Options travel as-is — answers come back keyed to their text.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OHButton(label: 'Share request file', expanded: true, onPressed: _share),
          const SizedBox(height: 8),
          OHButton(
            label: 'Copy request JSON',
            style: OHButtonStyle.secondary,
            expanded: true,
            onPressed: _copy,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Import — paste responses
// ---------------------------------------------------------------------------

class _ImportTab extends ConsumerStatefulWidget {
  const _ImportTab({required this.case_});

  final Case case_;

  @override
  ConsumerState<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<_ImportTab>
    with AutomaticKeepAliveClientMixin {
  final _paste = TextEditingController();
  bool _importing = false;
  String? _parseError;
  List<String> _rejected = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (_importing) return;
    setState(() {
      _importing = true;
      _parseError = null;
      _rejected = const [];
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(importBountyResponsesProvider)
          .call(widget.case_, _paste.text);
      ref.invalidate(duelForecastsForCaseProvider(widget.case_.id));
      ref.invalidate(forecastersProvider);
      if (!mounted) return;
      setState(() {
        _rejected = result.rejected;
        // Clear an accepted paste so the content leaves the screen.
        if (result.imported > 0) _paste.clear();
      });
      // Counts only — imported forecasts stay sealed (R1).
      final text = result.imported > 0
          ? '${result.imported} forecast'
              '${result.imported == 1 ? '' : 's'} sealed'
              '${result.duplicates > 0 ? ' · ${result.duplicates} already imported' : ''}'
          : result.duplicates > 0
              ? 'Already imported — every bot in that paste has answered.'
              : 'Nothing imported.';
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _parseError = e.message);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Paste the answer file a bot (or a friend running one) sent back — '
          'one response or a whole array.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('bounty-paste'),
          controller: _paste,
          minLines: 6,
          maxLines: 12,
          style: textTheme.bodySmall!.copyWith(fontFamily: 'monospace'),
          decoration: const InputDecoration(
            labelText: 'BountyResponse JSON',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        if (_importing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          )
        else
          OHButton(
            label: 'Import forecasts',
            expanded: true,
            onPressed: _import,
          ),
        const SizedBox(height: 8),
        Text(
          'Imported forecasts stay sealed until you decide — same rule as '
          'the duel.',
          style: textTheme.bodySmall,
        ),
        if (_parseError != null) ...[
          const SizedBox(height: 12),
          Text(_parseError!,
              style: textTheme.bodyMedium!.copyWith(color: colors.error)),
        ],
        if (_rejected.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Not imported:', style: textTheme.labelLarge),
          for (final reason in _rejected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $reason', style: textTheme.bodySmall),
            ),
        ],
      ],
    );
  }
}
