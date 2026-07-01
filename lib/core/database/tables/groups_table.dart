import 'package:drift/drift.dart';

/// A persistent ReckonParty group — a household, a couple, a founding team —
/// that makes decisions together over time, unlike the one-shot [Parties]
/// rows it scopes. Purely local: group names and rosters never leave the
/// device except inside end-to-end-encrypted party blobs.
@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
