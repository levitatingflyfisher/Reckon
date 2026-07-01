import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../shared/widgets/oh_button.dart';
import '../../../shared/widgets/oh_text_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../data/group_providers.dart';

/// Create a persistent group: a name for the circle, and a name for yourself.
/// Your display name is the first user-entered identity in the app — it stays
/// on this device and inside the end-to-end-encrypted decisions you share;
/// no account is created anywhere.
class GroupCreateScreen extends ConsumerStatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _displayName.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _name.text.trim().isNotEmpty &&
      _displayName.text.trim().isNotEmpty &&
      !_creating;

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() => _creating = true);
    try {
      final groups = ref.read(groupRepositoryProvider);
      final group = await groups.createGroup(name: _name.text.trim());
      // The creator is the first member: their stable ghost account id plus
      // the display name the group will see on their ballots.
      final accountId =
          await ref.read(authRepositoryProvider).getOrCreateAccountId();
      await groups.addMember(
        groupId: group.id,
        memberId: accountId,
        displayName: _displayName.text.trim(),
      );
      ref.invalidate(groupsProvider);
      ref.invalidate(groupMembersProvider(group.id));
      if (!mounted) return;
      context.go('/group/${group.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't create group: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(label: 'Name the group'),
          OHTextField(
            controller: _name,
            hint: 'e.g. The household',
            autofocus: true,
          ),
          const SectionHeader(label: 'Your name in this group'),
          OHTextField(
            controller: _displayName,
            hint: 'What the others will see on your votes',
          ),
          const SizedBox(height: 8),
          Text(
            'Both names stay on your devices — they only ever travel inside '
            'encrypted decisions shared with the group.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OHButton(
            label: _creating ? 'Creating…' : 'Create group',
            expanded: true,
            onPressed: _canCreate ? _create : null,
          ),
        ],
      ),
    );
  }
}
