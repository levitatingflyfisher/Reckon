import '../entities/group.dart';
import '../entities/party.dart';

/// Persistent groups over the one-shot party machinery.
///
/// Creation and joining share one door: [createGroup] with an explicit [id]
/// is how a device adopts a group it learned about from a shared decision —
/// so both it and [addMember] are idempotent (re-imports return the stored
/// row unchanged instead of clobbering local state).
abstract class GroupRepository {
  /// Create a group, or — when [id] names one that already exists locally —
  /// return the stored group unchanged.
  Future<Group> createGroup({required String name, String? id});

  /// The group, or null if this device doesn't know it.
  Future<Group?> getGroup(String id);

  /// All unarchived groups, oldest first.
  Future<List<Group>> listGroups();

  /// Add a person to a group, or return their existing membership — one row
  /// per (group, member), first display name wins.
  Future<GroupMember> addMember({
    required String groupId,
    required String memberId,
    required String displayName,
  });

  /// Everyone in the group, in joining order.
  Future<List<GroupMember>> membersOf(String groupId);

  /// The group's decision history: its parties, newest first.
  Future<List<Party>> partiesInGroup(String groupId);

  /// Hide the group from lists without deleting anything.
  Future<void> archive(String groupId);
}
