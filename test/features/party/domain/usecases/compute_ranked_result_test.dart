import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/usecases/compute_ranked_result.dart';

Party _party({List<PartyOption>? options}) => Party(
      id: 'p1',
      title: 'Where to eat?',
      options: options ??
          const [
            PartyOption(id: 'a', label: 'Tacos'),
            PartyOption(id: 'b', label: 'Pizza'),
            PartyOption(id: 'c', label: 'Sushi'),
          ],
      votingMethod: VotingMethod.ranked,
      createdAt: DateTime.utc(2026, 6, 12),
    );

Ballot _b(Party p, String id, List<String> ranking) =>
    Ballot.ranked(id: id, party: p, rankedOptionIds: ranking);

void main() {
  const uc = ComputeRankedResult();

  test('majority in round 1 wins immediately, single round', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c']),
      _b(p, '2', ['a', 'c', 'b']),
      _b(p, '3', ['a', 'b', 'c']),
      _b(p, '4', ['b', 'a', 'c']),
      _b(p, '5', ['c', 'b', 'a']),
    ]);
    // a has 3/5 first choices => outright majority.
    expect(result.winnerId, 'a');
    expect(result.rounds, hasLength(1));
    expect(result.rounds.single.winnerOptionId, 'a');
    expect(result.rounds.single.eliminatedOptionId, isNull);
    expect(result.isContested, isFalse);
  });

  test('multi-round elimination with vote transfer', () {
    final p = _party();
    // Round 1: a=2, b=2, c=1. No majority (need >2.5).
    // c eliminated; its single ballot (c,a,...) transfers to a.
    // Round 2: a=3, b=2 => a wins.
    final result = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c']),
      _b(p, '2', ['a', 'b', 'c']),
      _b(p, '3', ['b', 'a', 'c']),
      _b(p, '4', ['b', 'a', 'c']),
      _b(p, '5', ['c', 'a', 'b']),
    ]);
    expect(result.rounds, hasLength(2));
    expect(result.rounds[0].eliminatedOptionId, 'c');
    expect(result.rounds[0].winnerOptionId, isNull);
    expect(result.winnerId, 'a');
    final r2 = {for (final t in result.rounds[1].tallies) t.optionId: t.votes};
    expect(r2['a'], 3); // transferred c ballot landed on a
    expect(r2['b'], 2);
    expect(result.isContested, isTrue); // needed a round to resolve
  });

  test('exhausted ballots: truncated preferences drop out', () {
    final p = _party();
    // Round 1: a=2, b=2, c=1. c eliminated.
    // The c-only ballot ('5') has no further preference => exhausted.
    // Round 2: a=2, b=2, one exhausted ballot. No majority among 4 cast,
    // and >2 needed. Tie a=2,b=2 => eliminate lexicographically-greatest 'b'.
    // Round 3: a=2 (only active candidate) wins.
    final result = uc.call(p, [
      _b(p, '1', ['a']),
      _b(p, '2', ['a']),
      _b(p, '3', ['b']),
      _b(p, '4', ['b']),
      _b(p, '5', ['c']),
    ]);
    expect(result.rounds[0].eliminatedOptionId, 'c');
    expect(result.rounds[0].exhaustedBallots, 0);
    expect(result.rounds[1].exhaustedBallots, 1); // ballot 5 now exhausted
    expect(result.winnerId, 'a');
  });

  test('tie-break eliminates lexicographically greatest id, deterministic', () {
    final p = _party();
    // a=1, b=1, c=1 all tied for last. Eliminate 'c' (greatest id).
    final r1 = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c']),
      _b(p, '2', ['b', 'c', 'a']),
      _b(p, '3', ['c', 'a', 'b']),
    ]);
    expect(r1.rounds[0].eliminatedOptionId, 'c');

    // Re-running with the same input gives the same elimination order.
    final r2 = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c']),
      _b(p, '2', ['b', 'c', 'a']),
      _b(p, '3', ['c', 'a', 'b']),
    ]);
    expect(
      r2.rounds.map((r) => r.eliminatedOptionId).toList(),
      r1.rounds.map((r) => r.eliminatedOptionId).toList(),
    );
  });

  test('every preference exhausted leaves a winner among survivors', () {
    final p = _party();
    // All ballots rank only c. c has 100% so it wins round 1.
    final result = uc.call(p, [
      _b(p, '1', ['c']),
      _b(p, '2', ['c']),
    ]);
    expect(result.winnerId, 'c');
    expect(result.rounds, hasLength(1));
  });

  test('empty ballots list yields no winner and no rounds', () {
    final p = _party();
    final result = uc.call(p, []);
    expect(result.winnerId, isNull);
    expect(result.rounds, isEmpty);
    expect(result.ballotCount, 0);
    expect(result.isContested, isFalse);
  });

  test('all-empty ballots are ignored, no winner', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', const []),
      _b(p, '2', const []),
    ]);
    expect(result.ballotCount, 0);
    expect(result.winnerId, isNull);
  });

  test('single-option party: that option wins round 1', () {
    final p = _party(options: const [PartyOption(id: 'x', label: 'X')]);
    final result = uc.call(p, [
      _b(p, '1', ['x']),
      _b(p, '2', ['x']),
    ]);
    expect(result.winnerId, 'x');
    expect(result.rounds, hasLength(1));
    expect(result.isContested, isFalse);
  });

  test('winner emerges only after several eliminations is contested', () {
    final p = _party(options: const [
      PartyOption(id: 'a', label: 'A'),
      PartyOption(id: 'b', label: 'B'),
      PartyOption(id: 'c', label: 'C'),
      PartyOption(id: 'd', label: 'D'),
    ]);
    // R1: a=3, b=3, c=2, d=1 (9 ballots, need >4.5). d eliminated.
    // d's ballot ['d','c',...] -> c. R2: a=3,b=3,c=3. Tie for last among all;
    // eliminate 'c' (greatest of the tied-lowest = all three at 3... actually
    // lowest is 3, tie of a,b,c -> eliminate c).
    // c ballots ['c','a',...]x2 + transferred ['d','c','a'] -> a. R3 a=6,b=3 => a.
    final result = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c', 'd']),
      _b(p, '2', ['a', 'b', 'c', 'd']),
      _b(p, '3', ['a', 'b', 'c', 'd']),
      _b(p, '4', ['b', 'a', 'c', 'd']),
      _b(p, '5', ['b', 'a', 'c', 'd']),
      _b(p, '6', ['b', 'a', 'c', 'd']),
      _b(p, '7', ['c', 'a', 'b', 'd']),
      _b(p, '8', ['c', 'a', 'b', 'd']),
      _b(p, '9', ['d', 'c', 'a', 'b']),
    ]);
    expect(result.rounds.length, greaterThan(1));
    expect(result.rounds.first.eliminatedOptionId, 'd');
    expect(result.winnerId, 'a');
    expect(result.isContested, isTrue);
  });

  test('round tallies are sorted votes desc then optionId asc', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a', 'b', 'c']),
      _b(p, '2', ['b', 'a', 'c']),
    ]);
    final r1 = result.rounds.first.tallies;
    // a=1,b=1,c=0 -> a before b (tie, optionId asc), then c.
    expect(r1.map((t) => t.optionId).toList(), ['a', 'b', 'c']);
  });
}
