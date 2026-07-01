import 'package:drift/drift.dart';
import '../converters.dart';
import 'parties_table.dart';

/// One participant's ballot for a [Parties] row. Stores both shapes; which is
/// meaningful depends on the party's voting method (approvals for approval,
/// ranking for ranked). Mirrors the `Ballot` domain entity.
@DataClassName('PartyBallotRow')
class PartyBallots extends Table {
  TextColumn get id => text()();
  TextColumn get partyId => text().references(Parties, #id)();

  /// 'approval' | 'ranked'.
  TextColumn get method => text()();

  /// JSON list of approved option ids (approval ballots; empty otherwise).
  TextColumn get approvals => text().map(const JsonListConverter())();

  /// JSON list of option ids, most→least preferred (ranked ballots; empty
  /// otherwise).
  TextColumn get ranking => text().map(const JsonListConverter())();

  DateTimeColumn get submittedAt => dateTime()();

  /// The voter's ghost account id for group (attributed) decisions; null for
  /// the original anonymous ballots. Attribution rides only inside encrypted
  /// blobs on the wire — never in relay plaintext. Added at schema v5.
  TextColumn get memberId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
