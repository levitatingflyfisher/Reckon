import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../sync/party_sync_providers.dart';

/// Join a party someone shared with you. Paste the link (or the text behind a
/// QR); it carries the relay/peer address and the decryption key, so the party
/// is fetched, decrypted, and stored locally before you start voting.
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
