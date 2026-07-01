import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/group_repository_impl.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/entities/party_result.dart';
import 'package:reckon/features/party/sync/party_codec.dart';
import 'package:reckon/features/party/sync/party_crypto.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_link.dart';
import 'package:reckon/features/party/sync/party_sync_service.dart';
import 'package:reckon/features/party/sync/transport/lan_party_host.dart';
import 'package:reckon/features/party/sync/transport/lan_relay_resolver.dart';

/// Full stack over a real LAN socket: PartySyncService + the `lan://` resolver +
/// LanPartyHost. Two guests join by link, one votes, the other tallies it.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const options = [
    PartyOption(id: 'a', label: 'Tacos'),
    PartyOption(id: 'b', label: 'Sushi'),
  ];

  test('guests join a LAN party by link, vote, and tally over TCP', () async {
    // Host owns the party and serves its encrypted blob on the LAN.
    final hostDb = AppDatabase(NativeDatabase.memory());
    addTearDown(hostDb.close);
    final hostRepo = LocalPartyRepository(hostDb);
    final party = await hostRepo.createParty(
        title: 'Dinner?', options: options, votingMethod: VotingMethod.approval);

    final gen = await PartyCrypto.generate();
    final host = await LanPartyHost.start(
      partyId: party.id,
      partyBlob: await gen.crypto.encryptJson(PartyCodec.partyToJson(party)),
      address: '127.0.0.1',
    );
    addTearDown(host.stop);

    final link = PartyJoinLink(
      relayBaseUrl: 'lan://127.0.0.1:${host.port}',
      partyId: party.id,
      keyString: gen.keyString,
    ).toUrl();

    // Guest 1 joins over the socket and casts a vote.
    final voter = _device();
    addTearDown(voter.sync.dispose);
    final joined = await voter.sync.joinParty(link);
    expect(joined.title, 'Dinner?');

    final ballot = Ballot.approval(
        id: 'v1', party: joined, approvedOptionIds: const ['b']);
    await voter.repo.submitBallot(party.id, ballot);
    await voter.sync.pushBallot(party.id, ballot);

    // Guest 2 joins fresh, pulls, and tallies the vote that travelled the LAN.
    final tallier = _device();
    addTearDown(tallier.sync.dispose);
    await tallier.sync.joinParty(link);
    await tallier.sync.pull(party.id);

    final result =
        await tallier.repo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 1);
    expect(result.tallies.firstWhere((t) => t.optionId == 'b').approvals, 1);
  });

  test('the UI-path service sequence works end to end over the LAN', () async {
    // This mirrors exactly what the screens call since the wiring fix:
    // vote screen  -> submitBallot + pushBallot
    // result screen -> pull (open/refresh/periodic)
    // close voting -> closeSynced
    final hostDb = AppDatabase(NativeDatabase.memory());
    addTearDown(hostDb.close);
    final hostRepo = LocalPartyRepository(hostDb);
    final party = await hostRepo.createParty(
        title: 'Movie?', options: options, votingMethod: VotingMethod.approval);

    final gen = await PartyCrypto.generate();
    final host = await LanPartyHost.start(
      partyId: party.id,
      partyBlob: await gen.crypto.encryptJson(PartyCodec.partyToJson(party)),
      address: '127.0.0.1',
    );
    addTearDown(host.stop);
    final link = PartyJoinLink(
      relayBaseUrl: 'lan://127.0.0.1:${host.port}',
      partyId: party.id,
      keyString: gen.keyString,
    ).toUrl();

    final voter = _device();
    addTearDown(voter.sync.dispose);
    final joined = await voter.sync.joinParty(link);

    // Vote screen path.
    final ballot = Ballot.approval(
        id: 'ui1', party: joined, approvedOptionIds: const ['a']);
    await voter.repo.submitBallot(party.id, ballot);
    await voter.sync.pushBallot(party.id, ballot);

    // Result screen path on another device: pull folds the vote in.
    final watcher = _device();
    addTearDown(watcher.sync.dispose);
    await watcher.sync.joinParty(link);
    await watcher.sync.pull(party.id);
    final tally = await watcher.repo.computeResult(party.id) as ApprovalResult;
    expect(tally.ballotCount, 1);

    // Close-voting path: the voter closes; the watcher's next pull mirrors it.
    await voter.sync.closeSynced(party.id);
    await watcher.sync.pull(party.id);
    expect((await watcher.repo.getParty(party.id))!.closed, isTrue);
  });
}

({LocalPartyRepository repo, PartySyncService sync}) _device() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = LocalPartyRepository(db);
  final sync = PartySyncService(
    local: repo,
    keys: InMemoryPartyKeyStore(),
    relayFor: lanAndCloudResolver(),
    groups: GroupRepositoryImpl(db),
  );
  return (repo: repo, sync: sync);
}
