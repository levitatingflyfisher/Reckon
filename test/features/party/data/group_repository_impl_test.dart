import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/group_repository_impl.dart';

void main() {
  late AppDatabase db;
  late GroupRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GroupRepositoryImpl(db, now: () => DateTime(2026, 7, 11));
  });

  tearDown(() => db.close());

  group('groups', () {
    test('createGroup persists and getGroup round-trips', () async {
      final created = await repo.createGroup(name: 'Household');
      expect(created.id, isNotEmpty);
      expect(created.name, 'Household');
      expect(created.archived, isFalse);
      expect(created.createdAt, DateTime(2026, 7, 11));

      final fetched = await repo.getGroup(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Household');
    });

    test('getGroup returns null for an unknown id', () async {
      expect(await repo.getGroup('nope'), isNull);
    });

    test(
        'createGroup with an existing id returns the stored group unchanged '
        '(idempotent join-import)', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      final again = await repo.createGroup(name: 'Renamed?', id: 'g1');
      expect(again.name, 'Household',
          reason: 're-joining a known group must not clobber local state');
      expect(await repo.listGroups(), hasLength(1));
    });

    test('listGroups excludes archived groups', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      await repo.createGroup(name: 'Book club', id: 'g2');
      await repo.archive('g1');

      final listed = await repo.listGroups();
      expect(listed.map((g) => g.id), ['g2']);

      final archived = await repo.getGroup('g1');
      expect(archived, isNotNull,
          reason: 'archive hides, never deletes — history stays reachable');
      expect(archived!.archived, isTrue);
    });
  });

  group('members', () {
    test('addMember + membersOf round-trips', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      final member = await repo.addMember(
        groupId: 'g1',
        memberId: 'ghost-ann',
        displayName: 'Ann',
      );
      expect(member.groupId, 'g1');
      expect(member.memberId, 'ghost-ann');
      expect(member.displayName, 'Ann');
      expect(member.joinedAt, DateTime(2026, 7, 11));

      final members = await repo.membersOf('g1');
      expect(members, hasLength(1));
      expect(members.single.displayName, 'Ann');
    });

    test('addMember is idempotent per (group, member)', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      final first = await repo.addMember(
          groupId: 'g1', memberId: 'ghost-ann', displayName: 'Ann');
      final again = await repo.addMember(
          groupId: 'g1', memberId: 'ghost-ann', displayName: 'Annie');
      expect(again.id, first.id,
          reason: 're-joining returns the existing membership');
      expect(again.displayName, 'Ann',
          reason: 'the original display name is kept');
      expect(await repo.membersOf('g1'), hasLength(1));
    });

    test('the same person can belong to two groups', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      await repo.createGroup(name: 'Book club', id: 'g2');
      await repo.addMember(
          groupId: 'g1', memberId: 'ghost-ann', displayName: 'Ann');
      await repo.addMember(
          groupId: 'g2', memberId: 'ghost-ann', displayName: 'Ann');
      expect(await repo.membersOf('g1'), hasLength(1));
      expect(await repo.membersOf('g2'), hasLength(1));
    });

    test('addMember to a nonexistent group is rejected (FK)', () async {
      await expectLater(
        repo.addMember(
            groupId: 'no-such-group', memberId: 'm1', displayName: 'Ann'),
        throwsA(predicate(
            (e) => e.toString().toUpperCase().contains('FOREIGN KEY'))),
      );
    });
  });

  group('decision history', () {
    Future<void> insertParty(String id, String? groupId, DateTime at) async {
      await db.into(db.parties).insert(PartiesCompanion.insert(
            id: id,
            title: 'Decision $id',
            votingMethod: 'approval',
            options: const [
              {'id': 'o1', 'label': 'Yes'},
            ],
            createdAt: at,
            groupId: Value(groupId),
          ));
    }

    test('partiesInGroup returns only that group, newest first', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      await repo.createGroup(name: 'Book club', id: 'g2');
      await insertParty('p-old', 'g1', DateTime(2026, 7, 1));
      await insertParty('p-new', 'g1', DateTime(2026, 7, 10));
      await insertParty('p-other', 'g2', DateTime(2026, 7, 5));
      await insertParty('p-solo', null, DateTime(2026, 7, 6));

      final history = await repo.partiesInGroup('g1');
      expect(history.map((p) => p.id), ['p-new', 'p-old']);
      expect(history.first.title, 'Decision p-new');
      expect(history.first.options.single.label, 'Yes');
    });

    test('partiesInGroup is empty for a group with no decisions', () async {
      await repo.createGroup(name: 'Household', id: 'g1');
      expect(await repo.partiesInGroup('g1'), isEmpty);
    });
  });
}
