import 'package:drift/drift.dart';
import '../converters.dart';
import 'groups_table.dart';

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

  /// The persistent [Groups] row this decision belongs to; null for the
  /// original one-shot (ungrouped) parties. Added at schema v5.
  TextColumn get groupId => text().nullable().references(Groups, #id)();

  /// Considered mode: a serious decision whose tallies stay hidden until the
  /// host closes voting (blind, then mutual reveal). Added at schema v5.
  BoolColumn get considered => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
