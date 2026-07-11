import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/entities/group.dart';
import '../domain/entities/party.dart';
import '../domain/repositories/group_repository.dart';
import 'group_repository_impl.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// All unarchived groups. Invalidate after create/archive.
final groupsProvider = FutureProvider<List<Group>>((ref) {
  return ref.watch(groupRepositoryProvider).listGroups();
});

/// A single group by id (null if unknown on this device).
final groupProvider = FutureProvider.family<Group?, String>((ref, id) {
  return ref.watch(groupRepositoryProvider).getGroup(id);
});

/// The group's roster, in joining order. Invalidate after addMember.
final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).membersOf(groupId);
});

/// The group's decision history (its parties, newest first). Invalidate
/// after creating a decision in the group.
final groupPartiesProvider =
    FutureProvider.family<List<Party>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).partiesInGroup(groupId);
});
