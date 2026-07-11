import 'package:drift/drift.dart';
import 'groups_table.dart';

/// One person's membership in a [Groups] row. [memberId] is the member's
/// stable ghost account id (the same id that attributes their ballots);
/// [displayName] is what the group sees. A person joins a group once —
/// (groupId, memberId) is unique.
@DataClassName('GroupMemberRow')
class GroupMembers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get memberId => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {groupId, memberId},
      ];
}
