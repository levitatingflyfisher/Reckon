import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/party/data/group_repository_impl.dart';
import 'package:reckon/features/party/data/local_party_repository.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/entities/party_result.dart';

void main() {
  late AppDatabase db;
  late LocalPartyRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalPartyRepository(db);
  });

  tearDown(() async => db.close());

  const options = [
    PartyOption(id: 'a', label: 'Tacos'),
    PartyOption(id: 'b', label: 'Sushi'),
    PartyOption(id: 'c', label: 'Pizza'),
  ];

  test('createParty persists and round-trips a party', () async {
    final created = await repo.createParty(
      title: 'Where to eat?',
      options: options,
      votingMethod: VotingMethod.approval,
    );

    final fetched = await repo.getParty(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.title, 'Where to eat?');
    expect(fetched.votingMethod, VotingMethod.approval);
    expect(fetched.options, options);
    expect(fetched.closed, isFalse);
  });

  test('getParty returns null for an unknown id', () async {
    expect(await repo.getParty('nope'), isNull);
  });

  test('approval ballots tally on-device end to end', () async {
    final party = await repo.createParty(
      title: 'Dinner',
      options: options,
      votingMethod: VotingMethod.approval,
    );
    await repo.submitBallot(
        party.id,
        Ballot.approval(
            id: 'v1', party: party, approvedOptionIds: const ['a', 'b']));
    await repo.submitBallot(
        party.id,
        Ballot.approval(
            id: 'v2', party: party, approvedOptionIds: const ['a']));
    await repo.submitBallot(
        party.id,
        Ballot.approval(
            id: 'v3', party: party, approvedOptionIds: const ['a', 'c']));

    final result = await repo.computeResult(party.id) as ApprovalResult;
    expect(result.ballotCount, 3);
    expect(result.tallies.first.optionId, 'a');
    expect(result.tallies.first.approvals, 3);
  });

  test('ranked ballots resolve via IRV through the repository', () async {
    final party = await repo.createParty(
      title: 'Movie night',
      options: options,
      votingMethod: VotingMethod.ranked,
    );
    // a:2 first-choices, b:2, c:1 -> c eliminated, its vote transfers to a.
    await repo.submitBallot(party.id,
        Ballot.ranked(id: 'v1', party: party, rankedOptionIds: const ['a', 'b']));
    await repo.submitBallot(party.id,
        Ballot.ranked(id: 'v2', party: party, rankedOptionIds: const ['a', 'c']));
    await repo.submitBallot(party.id,
        Ballot.ranked(id: 'v3', party: party, rankedOptionIds: const ['b', 'a']));
    await repo.submitBallot(party.id,
        Ballot.ranked(id: 'v4', party: party, rankedOptionIds: const ['b', 'c']));
    await repo.submitBallot(party.id,
        Ballot.ranked(id: 'v5', party: party, rankedOptionIds: const ['c', 'a']));

    final result = await repo.computeResult(party.id) as RankedResult;
    expect(result.ballotCount, 5);
    expect(result.winnerId, 'a'); // a reaches 3 after c's transfer
    expect(result.rounds.length, greaterThan(1));
  });

  test('closeParty flips the persisted closed flag', () async {
    final party = await repo.createParty(
      title: 'X',
      options: options,
      votingMethod: VotingMethod.approval,
    );
    await repo.closeParty(party.id);
    expect((await repo.getParty(party.id))!.closed, isTrue);
  });

  test('computeResult on an unknown party throws', () async {
    expect(repo.computeResult('ghost'), throwsStateError);
  });

  group('persistent groups', () {
    test('createParty persists group scope and considered mode', () async {
      // The group row must exist first — parties.group_id is a real foreign
      // key and the database enforces it.
      await GroupRepositoryImpl(db).createGroup(name: 'Household', id: 'g1');

      final created = await repo.createParty(
        title: 'Where do we live?',
        options: options,
        votingMethod: VotingMethod.approval,
        groupId: 'g1',
        considered: true,
      );
      expect(created.groupId, 'g1');
      expect(created.considered, isTrue);

      final fetched = await repo.getParty(created.id);
      expect(fetched!.groupId, 'g1');
      expect(fetched.considered, isTrue);
    });

    test('importParty keeps a joined party in its group, considered intact',
        () async {
      await GroupRepositoryImpl(db).createGroup(name: 'Household', id: 'g1');

      final visiting = Party(
        id: 'p-import',
        title: 'Where do we live?',
        options: options,
        votingMethod: VotingMethod.approval,
        createdAt: DateTime.utc(2026, 7, 11),
        groupId: 'g1',
        considered: true,
      );
      await repo.importParty(visiting);

      final fetched = await repo.getParty('p-import');
      expect(fetched!.groupId, 'g1');
      expect(fetched.considered, isTrue);
    });

    test('submitBallot round-trips member attribution', () async {
      final party = await repo.createParty(
        title: 'Dinner',
        options: options,
        votingMethod: VotingMethod.approval,
      );
      await repo.submitBallot(
        party.id,
        Ballot.approval(
          id: 'v1',
          party: party,
          approvedOptionIds: const ['a'],
          memberId: 'm-1',
        ),
      );
      await repo.submitBallot(
        party.id,
        Ballot.approval(
            id: 'v2', party: party, approvedOptionIds: const ['b']),
      );

      final ballots = await repo.getBallots(party.id);
      expect(ballots.singleWhere((b) => b.id == 'v1').memberId, 'm-1');
      expect(ballots.singleWhere((b) => b.id == 'v2').memberId, isNull,
          reason: 'anonymous ballots stay anonymous');
    });
  });
}
