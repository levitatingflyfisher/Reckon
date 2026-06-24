import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/oh_button.dart';
import '../data/party_providers.dart';
import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';

/// Cast one ballot for a party. This is the pass-the-phone surface: each voter
/// fills it in, submits, and hands the device on. Fully on-device.
class PartyVoteScreen extends ConsumerStatefulWidget {
  const PartyVoteScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<PartyVoteScreen> createState() => _PartyVoteScreenState();
}

class _PartyVoteScreenState extends ConsumerState<PartyVoteScreen> {
  final _approved = <String>{};
  List<String> _rankOrder = [];
  bool _inited = false;
  bool _submitting = false;

  void _ensureInit(Party party) {
    if (_inited) return;
    _rankOrder = party.options.map((o) => o.id).toList();
    _inited = true;
  }

  bool _canSubmit(Party party) => party.votingMethod == VotingMethod.approval
      ? _approved.isNotEmpty
      : _rankOrder.isNotEmpty;

  Future<void> _submit(Party party) async {
    if (_submitting || !_canSubmit(party)) return;
    setState(() => _submitting = true);
    final id = const Uuid().v4();
    final ballot = party.votingMethod == VotingMethod.approval
        ? Ballot.approval(id: id, party: party, approvedOptionIds: _approved)
        : Ballot.ranked(id: id, party: party, rankedOptionIds: _rankOrder);

    try {
      await ref.read(partyRepositoryProvider).submitBallot(party.id, ballot);
      ref.invalidate(partyResultProvider(party.id));
      if (!mounted) return;
      context.go('/party/${party.id}/result');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't submit: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final partyAsync = ref.watch(partyProvider(widget.partyId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your vote')),
      body: partyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (party) {
          if (party == null) {
            return const Center(child: Text('This party no longer exists.'));
          }
          _ensureInit(party);
          final labels = {for (final o in party.options) o.id: o.label};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.title, style: textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      party.votingMethod == VotingMethod.approval
                          ? 'Tick every option you’d be happy with.'
                          : 'Drag to rank — most preferred at the top.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: party.votingMethod == VotingMethod.approval
                    ? _ApprovalBallot(
                        party: party,
                        selected: _approved,
                        onToggle: (id, on) => setState(() {
                          on ? _approved.add(id) : _approved.remove(id);
                        }),
                      )
                    : ReorderableListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        // onReorder is kept (vs the newer onReorderItem) so the
                        // widget compiles across the supported Flutter range.
                        // ignore: deprecated_member_use
                        onReorder: (oldI, newI) => setState(() {
                          if (newI > oldI) newI -= 1;
                          final id = _rankOrder.removeAt(oldI);
                          _rankOrder.insert(newI, id);
                        }),
                        children: [
                          for (var i = 0; i < _rankOrder.length; i++)
                            ListTile(
                              key: ValueKey(_rankOrder[i]),
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text(labels[_rankOrder[i]] ?? '?'),
                              trailing: const Icon(Icons.drag_handle),
                            ),
                        ],
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OHButton(
                    label: _submitting ? 'Submitting…' : 'Submit vote',
                    expanded: true,
                    onPressed: _canSubmit(party) && !_submitting
                        ? () => _submit(party)
                        : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApprovalBallot extends StatelessWidget {
  const _ApprovalBallot({
    required this.party,
    required this.selected,
    required this.onToggle,
  });

  final Party party;
  final Set<String> selected;
  final void Function(String id, bool on) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        for (final o in party.options)
          CheckboxListTile(
            value: selected.contains(o.id),
            onChanged: (v) => onToggle(o.id, v ?? false),
            title: Text(o.label),
          ),
      ],
    );
  }
}
