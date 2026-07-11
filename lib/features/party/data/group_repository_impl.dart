import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/group.dart';
import '../domain/entities/party.dart';
import '../domain/repositories/group_repository.dart';
import 'local_party_repository.dart';

/// Drift-backed [GroupRepository]. Same local-first stance as
/// [LocalPartyRepository]: groups live entirely in the on-device database;
/// joining a group learned from a shared decision goes through the same
/// idempotent [createGroup]/[addMember] doors as creating one by hand.
class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._db, {Uuid? uuid, DateTime Function()? now})
      : _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  @override
  Future<Group> createGroup({required String name, String? id}) async {
    final groupId = id ?? _uuid.v4();
    final existing = await getGroup(groupId);
    if (existing != null) return existing;
    final group = Group(id: groupId, name: name, createdAt: _now());
    await _db.into(_db.groups).insert(
          GroupsCompanion.insert(
            id: group.id,
            name: group.name,
            createdAt: group.createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return group;
  }

  @override
  Future<Group?> getGroup(String id) async {
    final row = await (_db.select(_db.groups)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _groupFromRow(row);
  }

  @override
  Future<List<Group>> listGroups() async {
    final rows = await (_db.select(_db.groups)
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_groupFromRow).toList();
  }

  @override
  Future<GroupMember> addMember({
    required String groupId,
    required String memberId,
    required String displayName,
  }) async {
    final existing = await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId))
          ..where((t) => t.memberId.equals(memberId)))
        .getSingleOrNull();
    if (existing != null) return _memberFromRow(existing);

    final member = GroupMember(
      id: _uuid.v4(),
      groupId: groupId,
      memberId: memberId,
      displayName: displayName,
      joinedAt: _now(),
    );
    await _db.into(_db.groupMembers).insert(
          GroupMembersCompanion.insert(
            id: member.id,
            groupId: member.groupId,
            memberId: member.memberId,
            displayName: member.displayName,
            joinedAt: member.joinedAt,
          ),
        );
    return member;
  }

  @override
  Future<List<GroupMember>> membersOf(String groupId) async {
    final rows = await (_db.select(_db.groupMembers)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.joinedAt),
            (t) => OrderingTerm.asc(t.displayName),
          ]))
        .get();
    return rows.map(_memberFromRow).toList();
  }

  @override
  Future<List<Party>> partiesInGroup(String groupId) async {
    final rows = await (_db.select(_db.parties)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(LocalPartyRepository.partyFromRow).toList();
  }

  @override
  Future<void> archive(String groupId) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(groupId)))
        .write(const GroupsCompanion(archived: Value(true)));
  }

  Group _groupFromRow(GroupRow row) => Group(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        archived: row.archived,
      );

  GroupMember _memberFromRow(GroupMemberRow row) => GroupMember(
        id: row.id,
        groupId: row.groupId,
        memberId: row.memberId,
        displayName: row.displayName,
        joinedAt: row.joinedAt,
      );
}
