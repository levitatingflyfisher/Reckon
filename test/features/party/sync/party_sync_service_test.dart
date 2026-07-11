import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/group_repository_impl.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/entities/party_result.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_link.dart';
import 'package:reckon/features/party/sync/party_relay.dart';
import 'package:reckon/features/party/sync/party_sync_service.dart';

void main() {
  // These tests spin up two independent in-memory databases to model two
  // devices; each has its own executor, so drift's shared-instance warning is
  // a false positive here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // One shared relay simulates the network; two devices each have their own
  // local db + key store + sync service pointing at it.
  late InMemoryPartyRelay relay;

  PartySyncService deviceWith(LocalPartyRepository local,
          GroupRepositoryImpl groups) =>
      PartySyncService(
        local: local,
        keys: InMemoryPartyKeyStore(),
        relayFor: (_) async => relay,
        groups: groups,
      );

  setUp(() => relay = InMemoryPartyRelay());

  const options = [
    PartyOption(id: 'a', label: 'Tacos'),
    PartyOption(id: 'b', label: 'Sushi'),
  ];

  test('share → join replicates the party to another device', () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(dbA);
    final host = deviceWith(hostRepo, GroupRepositoryImpl(dbA));

    final party = await hostRepo.createParty(
        title: 'Dinner?', options: options, votingMethod: VotingMethod.approval);
    final link =
        await host.shareParty(party.id, relayBaseUrl: 'https://r.example');
    expect(PartyJoinLink.parse(link), isNotNull);

    final dbB = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(dbB);
    final joined =
        await deviceWith(guestRepo, GroupRepositoryImpl(dbB)).joinParty(link);

    expect(joined.id, party.id);
    expect(joined.title, 'Dinner?');
    expect((await guestRepo.getParty(party.id))!.options, options);

    await dbA.close();
    await dbB.close();
  });

  test('a guest ballot pushed to the relay reaches the host tally', () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(dbA);
    final host = deviceWith(hostRepo, GroupRepositoryImpl(dbA));
    final party = await hostRepo.createParty(
        title: 'Dinner?', options: options, votingMethod: VotingMethod.approval);
    final link =
        await host.shareParty(party.id, relayBaseUrl: 'https://r.example');

    // Host votes locally + pushes.
    final hostBallot =
        Ballot.approval(id: 'h1', party: party, approvedOptionIds: const ['a']);
    await hostRepo.submitBallot(party.id, hostBallot);
    await host.pushBallot(party.id, hostBallot);

    // Guest joins and votes.
    final dbB = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(dbB);
    final guest = deviceWith(guestRepo, GroupRepositoryImpl(dbB));
    await guest.joinParty(link);
    final guestBallot =
        Ballot.approval(id: 'g1', party: party, approvedOptionIds: const ['a', 'b']);
    await guestRepo.submitBallot(party.id, guestBallot);
    await guest.pushBallot(party.id, guestBallot);

    // Host pulls and tallies both ballots.
    await host.pull(party.id);
    final result = await hostRepo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 2);
    expect(result.tallies.firstWhere((t) => t.optionId == 'a').approvals, 2);

    await dbA.close();
    await dbB.close();
  });

  test('the relay only ever holds ciphertext (zero-knowledge)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = LocalPartyRepository(db);
    final svc = deviceWith(repo, GroupRepositoryImpl(db));
    final party = await repo.createParty(
        title: 'Secret plan', options: options, votingMethod: VotingMethod.approval);
    await svc.shareParty(party.id, relayBaseUrl: 'https://r.example');

    final ballot =
        Ballot.approval(id: 'b1', party: party, approvedOptionIds: const ['a']);
    await svc.pushBallot(party.id, ballot);

    final raw = relay.rawBallot(party.id, 'b1')!;
    // Nothing identifiable in the bytes the relay stores.
    expect(String.fromCharCodes(raw).contains('Tacos'), isFalse);
    final snap = await relay.fetchParty(party.id);
    expect(String.fromCharCodes(snap!.party).contains('Secret plan'), isFalse);

    await db.close();
  });

  test('pull is idempotent — no duplicate ballots', () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(dbA);
    final host = deviceWith(hostRepo, GroupRepositoryImpl(dbA));
    final party = await hostRepo.createParty(
        title: 'Q', options: options, votingMethod: VotingMethod.approval);
    final link =
        await host.shareParty(party.id, relayBaseUrl: 'https://r.example');

    final dbB = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(dbB);
    final guest = deviceWith(guestRepo, GroupRepositoryImpl(dbB));
    await guest.joinParty(link);
    await guest.pushBallot(
        party.id,
        Ballot.approval(id: 'g1', party: party, approvedOptionIds: const ['b']));

    await host.pull(party.id);
    await host.pull(party.id); // twice
    final result = await hostRepo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 1);

    await dbA.close();
    await dbB.close();
  });

  test('sharing a grouped decision lets a joiner rebuild the group', () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(dbA);
    final hostGroups = GroupRepositoryImpl(dbA);
    await hostGroups.createGroup(name: 'The household', id: 'g1');
    final host = deviceWith(hostRepo, hostGroups);

    final party = await hostRepo.createParty(
      title: 'Where do we live?',
      options: options,
      votingMethod: VotingMethod.approval,
      groupId: 'g1',
      considered: true,
    );
    final link =
        await host.shareParty(party.id, relayBaseUrl: 'https://r.example');

    final dbB = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(dbB);
    final guestGroups = GroupRepositoryImpl(dbB);
    final joined = await deviceWith(guestRepo, guestGroups).joinParty(link);

    expect(joined.groupId, 'g1');
    expect(joined.considered, isTrue,
        reason: 'guests must seal their tallies too');
    final group = await guestGroups.getGroup('g1');
    expect(group, isNotNull,
        reason: 'joining a shared decision adopts its group locally');
    expect(group!.name, 'The household');

    await dbA.close();
    await dbB.close();
  });

  test('attributed ballots carry roster names from device to device',
      () async {
    final dbA = AppDatabase(NativeDatabase.memory());
    final hostRepo = LocalPartyRepository(dbA);
    final hostGroups = GroupRepositoryImpl(dbA);
    await hostGroups.createGroup(name: 'The household', id: 'g1');
    final host = deviceWith(hostRepo, hostGroups);
    final party = await hostRepo.createParty(
      title: 'Where do we live?',
      options: options,
      votingMethod: VotingMethod.approval,
      groupId: 'g1',
    );
    final link =
        await host.shareParty(party.id, relayBaseUrl: 'https://r.example');

    // Ada joins, names herself in her local roster, and votes attributed.
    final dbB = AppDatabase(NativeDatabase.memory());
    final guestRepo = LocalPartyRepository(dbB);
    final guestGroups = GroupRepositoryImpl(dbB);
    final guest = deviceWith(guestRepo, guestGroups);
    await guest.joinParty(link);
    await guestGroups.addMember(
        groupId: 'g1', memberId: 'm-ada', displayName: 'Ada');
    final ballot = Ballot.approval(
        id: 'g1-v1', party: party, approvedOptionIds: const ['b'],
        memberId: 'm-ada');
    await guestRepo.submitBallot(party.id, ballot);
    await guest.pushBallot(party.id, ballot);

    // The host pulls: the ballot arrives attributed AND the host's roster
    // learns who Ada is.
    await host.pull(party.id);
    final ballots = await hostRepo.getBallots(party.id);
    expect(ballots.single.memberId, 'm-ada');
    final roster = await hostGroups.membersOf('g1');
    expect(roster.map((m) => m.displayName), contains('Ada'));

    await dbA.close();
    await dbB.close();
  });

  test('the relay sees no group name, member id, or display name', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = LocalPartyRepository(db);
    final groups = GroupRepositoryImpl(db);
    await groups.createGroup(name: 'The household', id: 'g-zk');
    await groups.addMember(
        groupId: 'g-zk', memberId: 'm-zk-ada', displayName: 'Ada');
    final svc = deviceWith(repo, groups);

    final party = await repo.createParty(
      title: 'Secret plan',
      options: options,
      votingMethod: VotingMethod.approval,
      groupId: 'g-zk',
    );
    await svc.shareParty(party.id, relayBaseUrl: 'https://r.example');
    await svc.pushBallot(
      party.id,
      Ballot.approval(
          id: 'zk-1', party: party, approvedOptionIds: const ['a'],
          memberId: 'm-zk-ada'),
    );

    // Z-property, extended to group data: the stored bytes are ciphertext
    // only — group names and member identities never appear.
    final snap = await relay.fetchParty(party.id);
    final partyBytes = String.fromCharCodes(snap!.party);
    expect(partyBytes.contains('household'), isFalse);
    expect(partyBytes.contains('g-zk'), isFalse);
    final ballotBytes = String.fromCharCodes(relay.rawBallot(party.id, 'zk-1')!);
    expect(ballotBytes.contains('Ada'), isFalse);
    expect(ballotBytes.contains('m-zk-ada'), isFalse);

    await db.close();
  });
}
