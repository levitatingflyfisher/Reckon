import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/domain/usecases/compute_approval_result.dart';

Party _party() => Party(
      id: 'p1',
      title: 'Lunch',
      options: const [
        PartyOption(id: 'a', label: 'Tacos'),
        PartyOption(id: 'b', label: 'Pizza'),
        PartyOption(id: 'c', label: 'Sushi'),
      ],
      votingMethod: VotingMethod.approval,
      createdAt: DateTime.utc(2026, 6, 12),
    );

Ballot _b(Party p, String id, List<String> approvals) =>
    Ballot.approval(id: id, party: p, approvedOptionIds: approvals);

void main() {
  const uc = ComputeApprovalResult();

  test('counts approvals and sorts descending', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a', 'b']),
      _b(p, '2', ['a']),
      _b(p, '3', ['a', 'c']),
      _b(p, '4', ['b']),
    ]);
    expect(result.ballotCount, 4);
    expect(result.tallies.map((t) => t.optionId).toList(), ['a', 'b', 'c']);
    expect(result.tallies.map((t) => t.approvals).toList(), [3, 2, 1]);
    expect(result.winnerIds, ['a']);
  });

  test('percentages are of total ballot count', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a']),
      _b(p, '2', ['a']),
      _b(p, '3', ['b']),
      _b(p, '4', ['b']),
    ]);
    final byId = {for (final t in result.tallies) t.optionId: t};
    expect(byId['a']!.percentage, 50.0);
    expect(byId['b']!.percentage, 50.0);
    expect(byId['c']!.percentage, 0.0);
  });

  test('ties for first surface every winner and sort by optionId', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a']),
      _b(p, '2', ['b']),
    ]);
    expect(result.winnerIds, ['a', 'b']);
    // Tie broken lexicographically in the ordering.
    expect(result.tallies.first.optionId, 'a');
    expect(result.isContested, isTrue);
  });

  test('all options reported even with zero approvals', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a']),
    ]);
    expect(result.tallies, hasLength(3));
    expect(result.tallies.last.approvals, 0);
  });

  test('empty ballots list yields zero counts and no winner', () {
    final p = _party();
    final result = uc.call(p, []);
    expect(result.ballotCount, 0);
    expect(result.winnerIds, isEmpty);
    expect(result.tallies.every((t) => t.approvals == 0), isTrue);
    expect(result.tallies.every((t) => t.percentage == 0), isTrue);
    expect(result.isContested, isFalse);
  });

  test('all-empty ballots count as ballots but no approvals', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', const []),
      _b(p, '2', const []),
    ]);
    expect(result.ballotCount, 2);
    expect(result.winnerIds, isEmpty);
  });

  test('single-option party still tallies', () {
    final p = Party(
      id: 'p2',
      title: 'Only one',
      options: const [PartyOption(id: 'x', label: 'X')],
      votingMethod: VotingMethod.approval,
      createdAt: DateTime.utc(2026, 6, 12),
    );
    final result = uc.call(p, [
      Ballot.approval(id: '1', party: p, approvedOptionIds: const ['x']),
    ]);
    expect(result.winnerIds, ['x']);
    expect(result.tallies.single.percentage, 100.0);
  });

  test('clear runaway winner is not contested', () {
    final p = _party();
    final result = uc.call(p, [
      _b(p, '1', ['a']),
      _b(p, '2', ['a']),
      _b(p, '3', ['a']),
      _b(p, '4', ['a']),
      _b(p, '5', ['b']),
    ]);
    // a=4, b=1 of 5 ballots => 60pt margin, not contested.
    expect(result.isContested, isFalse);
  });
}
