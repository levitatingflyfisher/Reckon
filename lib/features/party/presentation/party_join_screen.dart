import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../data/group_providers.dart';
import '../sync/party_sync_providers.dart';

/// Join a party someone shared with you. Paste the link (or the text behind a
/// QR); it carries the relay/peer address and the decryption key, so the party
/// is fetched, decrypted, and stored locally before you start voting.
///
/// A decision that belongs to a persistent group brings the group along
/// (auto-created locally by the sync service); the first time, this screen
/// asks for your display name so the group can put a name to your votes.
/// Declining is fine — you still vote, just without a roster name.
class PartyJoinScreen extends ConsumerStatefulWidget {
  const PartyJoinScreen({super.key});

  @override
  ConsumerState<PartyJoinScreen> createState() => _PartyJoinScreenState();
}

class _PartyJoinScreenState extends ConsumerState<PartyJoinScreen> {
  final _link = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _link.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _canJoin => _link.text.trim().isNotEmpty && !_joining;

  Future<void> _join() async {
    if (!_canJoin) return;
    setState(() => _joining = true);
    try {
      final party =
          await ref.read(partySyncServiceProvider).joinParty(_link.text.trim());
      final groupId = party.groupId;
      if (groupId != null) await _introduceYourself(groupId);
      if (!mounted) return;
      context.go('/party/${party.id}/vote');
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't join: $e")),
      );
    }
  }

  /// First contact with a group: ask for a display name and join its roster.
  /// Skipped for members the roster already knows.
  Future<void> _introduceYourself(String groupId) async {
    final groups = ref.read(groupRepositoryProvider);
    final accountId =
        await ref.read(authRepositoryProvider).getOrCreateAccountId();
    final roster = await groups.membersOf(groupId);
    if (roster.any((m) => m.memberId == accountId)) return;
    final group = await groups.getGroup(groupId);
    if (group == null || !mounted) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => _DisplayNameDialog(groupName: group.name),
    );
    if (name == null || name.trim().isEmpty) return;
    await groups.addMember(
      groupId: groupId,
      memberId: accountId,
      displayName: name.trim(),
    );
    ref.invalidate(groupsProvider);
    ref.invalidate(groupMembersProvider(groupId));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Join a party')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Got a link to a group decision?', style: textTheme.bodyLarge),
          const SizedBox(height: 12),
          OHTextField(
            controller: _link,
            hint: 'Paste the join link',
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            'The link includes the key to decrypt the party. It stays on your '
            'device — the relay never sees it.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OHButton(
            label: _joining ? 'Joining…' : 'Join',
            expanded: true,
            onPressed: _canJoin ? _join : null,
          ),
        ],
      ),
    );
  }
}

/// "You've joined <group> — who are you?" One optional text field; the name
/// stays local and travels only inside the group's encrypted ballots.
class _DisplayNameDialog extends StatefulWidget {
  const _DisplayNameDialog({required this.groupName});
  final String groupName;

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('You joined “${widget.groupName}”'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add your name so the group knows who voted. It stays '
              'inside the group — never on any server.'),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: const Text('Join the group'),
        ),
      ],
    );
  }
}
