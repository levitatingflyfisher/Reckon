import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/party_providers.dart';
import '../domain/entities/party.dart';

/// Create a ReckonParty group decision. Local-first: the party is written to
/// the on-device database and the creator is taken straight to voting (the
/// pass-the-phone flow). No account, no network.
class PartyCreateScreen extends ConsumerStatefulWidget {
  const PartyCreateScreen({super.key});

  @override
  ConsumerState<PartyCreateScreen> createState() => _PartyCreateScreenState();
}

class _PartyCreateScreenState extends ConsumerState<PartyCreateScreen> {
  static const _minOptions = 2;
  static const _maxOptions = 10;

  final _title = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  VotingMethod _method = VotingMethod.approval;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    for (final c in _options) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _filledOptions =>
      _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  bool get _canCreate =>
      _title.text.trim().isNotEmpty && _filledOptions.length >= _minOptions;

  void _addOption() {
    if (_options.length >= _maxOptions) return;
    final c = TextEditingController()..addListener(_refresh);
    setState(() => _options.add(c));
  }

  void _removeOption(int i) {
    if (_options.length <= _minOptions) return;
    final c = _options.removeAt(i);
    c.dispose();
    setState(() {});
  }

  Future<void> _create() async {
    if (!_canCreate || _creating) return;
    setState(() => _creating = true);

    // Stable option ids by position; labels are the trimmed, non-empty entries.
    final options = <PartyOption>[];
    for (var i = 0; i < _options.length; i++) {
      final label = _options[i].text.trim();
      if (label.isNotEmpty) {
        options.add(PartyOption(id: 'o$i', label: label));
      }
    }

    try {
      final party = await ref.read(partyRepositoryProvider).createParty(
            title: _title.text.trim(),
            options: options,
            votingMethod: _method,
          );
      if (!mounted) return;
      context.go('/party/${party.id}/vote');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't create party: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Group decision')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What are you deciding together?', style: textTheme.bodyLarge),
          const SizedBox(height: 12),
          OHTextField(
            controller: _title,
            hint: 'e.g. Where should we eat tonight?',
            autofocus: true,
          ),
          const SectionHeader(label: 'Options'),
          for (var i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OHTextField(
                      controller: _options[i],
                      hint: 'Option ${i + 1}',
                    ),
                  ),
                  if (_options.length > _minOptions)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove option',
                      onPressed: () => _removeOption(i),
                    ),
                ],
              ),
            ),
          if (_options.length < _maxOptions)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
            ),
          const SectionHeader(label: 'How to decide'),
          SegmentedButton<VotingMethod>(
            segments: const [
              ButtonSegment(
                value: VotingMethod.approval,
                label: Text('Approval'),
                icon: Icon(Icons.done_all),
              ),
              ButtonSegment(
                value: VotingMethod.ranked,
                label: Text('Ranked'),
                icon: Icon(Icons.format_list_numbered),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _method == VotingMethod.approval
                ? 'Everyone ticks every option they’d be happy with. Most ticks wins.'
                : 'Everyone ranks the options. Resolved by instant-runoff so the '
                    'least-disliked option wins.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OHButton(
            label: _creating ? 'Creating…' : 'Start voting',
            expanded: true,
            onPressed: _canCreate && !_creating ? _create : null,
          ),
          const SizedBox(height: 8),
          OHButton(
            label: 'Join with a link',
            style: OHButtonStyle.text,
            expanded: true,
            onPressed: _creating ? null : () => context.push('/party/join'),
          ),
        ],
      ),
    );
  }
}
