import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';
import '../domain/repositories/party_repository.dart';
import '../domain/usecases/compute_approval_result.dart';
import '../domain/usecases/compute_ranked_result.dart';

/// Local-first [PartyRepository]: a party lives entirely in the on-device
/// Drift database. No account, no server — a group decides by passing the
/// phone (or, later, over an optional self-hostable relay that mirrors these
/// same rows). All voting math runs on-device via the Stage-1 usecases.
class LocalPartyRepository implements PartyRepository {
  LocalPartyRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<Party> createParty({
    required String title,
    required List<PartyOption> options,
    required VotingMethod votingMethod,
  }) async {
    final party = Party(
      id: _uuid.v4(),
      title: title,
      options: options,
      votingMethod: votingMethod,
      createdAt: DateTime.now(),
    );
    await _db.into(_db.parties).insert(
          PartiesCompanion.insert(
            id: party.id,
            title: party.title,
            votingMethod: party.votingMethod.name,
            options: [
              for (final o in options) {'id': o.id, 'label': o.label},
            ],
            createdAt: party.createdAt,
          ),
        );
    return party;
  }

  @override
  Future<Party?> getParty(String id) async {
    final row = await (_db.select(_db.parties)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _partyFromRow(row);
  }

  /// All locally-stored ballots for a party (validated). Used by the LAN host
  /// to seed peers with votes already cast on this device.
  Future<List<Ballot>> getBallots(String partyId) async {
    final party = await getParty(partyId);
    if (party == null) return const [];
    return _ballotsForParty(party);
  }

  @override
  Future<void> submitBallot(String partyId, Ballot ballot) async {
    // Idempotent by ballot id so re-submits and sync-merges (see
    // PartySyncService) can't create duplicates.
    await _db.into(_db.partyBallots).insert(
          PartyBallotsCompanion.insert(
            id: ballot.id,
            partyId: partyId,
            method: ballot.method.name,
            approvals: ballot.approvals.toList(),
            ranking: ballot.ranking,
            submittedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Insert a party that was created elsewhere and joined via a link, keeping
  /// its original id. Idempotent — a no-op if the party already exists locally.
  Future<void> importParty(Party party) async {
    await _db.into(_db.parties).insert(
          PartiesCompanion.insert(
            id: party.id,
            title: party.title,
            votingMethod: party.votingMethod.name,
            options: [
              for (final o in party.options) {'id': o.id, 'label': o.label},
            ],
            createdAt: party.createdAt,
            closed: Value(party.closed),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> closeParty(String partyId) async {
    await (_db.update(_db.parties)..where((t) => t.id.equals(partyId)))
        .write(const PartiesCompanion(closed: Value(true)));
  }

  @override
  Future<Object> computeResult(String partyId) async {
    final party = await getParty(partyId);
    if (party == null) {
      throw StateError('No party with id "$partyId"');
    }
    final ballots = await _ballotsForParty(party);
    switch (party.votingMethod) {
      case VotingMethod.approval:
        return const ComputeApprovalResult().call(party, ballots);
      case VotingMethod.ranked:
        return const ComputeRankedResult().call(party, ballots);
    }
  }

  Party _partyFromRow(PartyRow row) => Party(
        id: row.id,
        title: row.title,
        votingMethod: _methodFromName(row.votingMethod),
        options: [
          for (final o in row.options)
            PartyOption(
              id: (o as Map)['id'] as String,
              label: o['label'] as String,
            ),
        ],
        createdAt: row.createdAt,
        closed: row.closed,
      );

  /// Rebuild [Ballot] entities from stored rows, routing each through its
  /// validating factory so persisted ballots are re-checked against the party.
  /// Rows that no longer validate (e.g. an option removed) are skipped rather
  /// than poisoning the tally.
  Future<List<Ballot>> _ballotsForParty(Party party) async {
    final rows = await (_db.select(_db.partyBallots)
          ..where((t) => t.partyId.equals(party.id)))
        .get();
    final ballots = <Ballot>[];
    for (final r in rows) {
      try {
        switch (party.votingMethod) {
          case VotingMethod.approval:
            ballots.add(Ballot.approval(
              id: r.id,
              party: party,
              approvedOptionIds: r.approvals.cast<String>(),
            ));
          case VotingMethod.ranked:
            ballots.add(Ballot.ranked(
              id: r.id,
              party: party,
              rankedOptionIds: r.ranking.cast<String>(),
            ));
        }
      } on ArgumentError {
        // Stale ballot referencing an unknown option — ignore it.
      }
    }
    return ballots;
  }

  VotingMethod _methodFromName(String name) => VotingMethod.values.firstWhere(
        (m) => m.name == name,
        orElse: () => VotingMethod.approval,
      );
}
