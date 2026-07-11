import 'package:drift/native.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/group_repository_impl.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/repositories/party_repository.dart';
import 'package:reckon/features/party/domain/usecases/compute_approval_result.dart';
import 'package:reckon/features/party/domain/usecases/compute_ranked_result.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_relay.dart';
import 'package:reckon/features/party/sync/party_sync_service.dart';
import 'package:uuid/uuid.dart';

/// In-memory fakes for party *screen* tests.
///
/// Widget tests must not reach drift or real crypto: futures backed by a real
/// database/AES-GCM don't resolve under the widget tester's fake clock, so the
/// screen hangs on its loading spinner (see the note in
/// `party_join_screen_test.dart`). The real service→relay path is covered by
/// the real-async tests in `sync/` and the LAN integration test; these fakes
/// let widget tests cover the screen glue — which calls happen, and how
/// failures surface.
class FakePartyRepository implements PartyRepository {
  final parties = <String, Party>{};
  final ballots = <String, List<Ballot>>{};

  @override
  Future<Party> createParty({
    required String title,
    required List<PartyOption> options,
    required VotingMethod votingMethod,
    String? groupId,
    bool considered = false,
  }) async {
    final party = Party(
      id: const Uuid().v4(),
      title: title,
      options: options,
      votingMethod: votingMethod,
      createdAt: DateTime(2026, 7, 11),
      groupId: groupId,
      considered: considered,
    );
    parties[party.id] = party;
    return party;
  }

  @override
  Future<Party?> getParty(String id) async => parties[id];

  @override
  Future<void> submitBallot(String partyId, Ballot ballot) async {
    final existing = ballots[partyId] ??= [];
    if (existing.any((b) => b.id == ballot.id)) return; // idempotent by id
    existing.add(ballot);
  }

  @override
  Future<void> closeParty(String partyId) async {
    final party = parties[partyId];
    if (party != null) parties[partyId] = party.copyWith(closed: true);
  }

  @override
  Future<Object> computeResult(String partyId) async {
    final party = parties[partyId]!;
    final cast = ballots[partyId] ?? const <Ballot>[];
    return switch (party.votingMethod) {
      VotingMethod.approval => const ComputeApprovalResult()(party, cast),
      VotingMethod.ranked => const ComputeRankedResult()(party, cast),
    };
  }
}

/// A [PartySyncService] whose network behavior is scripted. The superclass
/// dependencies are inert placeholders — the database is never opened and the
/// relay is never contacted, because every service method the screens call is
/// overridden here.
class RecordingSyncService extends PartySyncService {
  RecordingSyncService(
    this.repo, {
    this.synced = true,
    this.failPush = false,
  }) : super(
          local: LocalPartyRepository(_inertDb),
          keys: InMemoryPartyKeyStore(),
          relayFor: (_) async => InMemoryPartyRelay(),
          groups: GroupRepositoryImpl(_inertDb),
        );

  /// One never-opened database shared by every recording service — drift only
  /// allocates resources on first query, and no overridden method ever
  /// queries it.
  static final _inertDb = AppDatabase(NativeDatabase.memory());

  final FakePartyRepository repo;

  /// Whether this device holds a sync key for any party asked about.
  bool synced;

  /// When true, [pushBallot] fails like an unreachable relay.
  bool failPush;

  final pushed = <Ballot>[];
  int pullCount = 0;
  bool closedOnRelay = false;

  /// Ballots "on the relay" that the next [pull] folds into [repo].
  final pendingRemote = <String, List<Ballot>>{};

  @override
  Future<bool> isSynced(String partyId) async => synced;

  @override
  Future<void> pushBallot(String partyId, Ballot ballot) async {
    if (!synced) return; // mirror the real no-op for keyless parties
    if (failPush) throw StateError('relay unreachable');
    pushed.add(ballot);
  }

  @override
  Future<void> pull(String partyId) async {
    if (!synced) return;
    pullCount++;
    for (final b in pendingRemote.remove(partyId) ?? const <Ballot>[]) {
      await repo.submitBallot(partyId, b);
    }
  }

  @override
  Future<void> closeSynced(String partyId) async {
    await repo.closeParty(partyId);
    if (synced) closedOnRelay = true;
  }
}
