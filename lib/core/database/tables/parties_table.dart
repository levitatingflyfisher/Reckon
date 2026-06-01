import 'package:drift/drift.dart';
import '../converters.dart';

/// A ReckonParty group decision. Local-first: a party lives entirely on the
/// device that created it (pass-the-phone / same-room voting). An optional,
/// self-hostable sync relay may mirror it later — never required.
@DataClassName('PartyRow')
class Parties extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();

  /// 'approval' | 'ranked' — the [VotingMethod] name.
  TextColumn get votingMethod => text()();

  /// JSON list of `{id, label}` option maps.
  TextColumn get options => text().map(const JsonListConverter())();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get closed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
