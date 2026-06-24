import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';

Party _party(VotingMethod method) => Party(
      id: 'p1',
      title: 'Where to eat?',
      options: const [
        PartyOption(id: 'a', label: 'Tacos'),
        PartyOption(id: 'b', label: 'Pizza'),
        PartyOption(id: 'c', label: 'Sushi'),
      ],
      votingMethod: method,
      createdAt: DateTime.utc(2026, 6, 12, 9),
    );

void main() {
  group('Party', () {
    test('expiresAt is createdAt + 7 days', () {
      final p = _party(VotingMethod.approval);
      expect(p.expiresAt, DateTime.utc(2026, 6, 19, 9));
      expect(p.expiresAt.difference(p.createdAt), const Duration(days: 7));
    });

    test('isExpired is false before expiry and true at/after expiry', () {
      final p = _party(VotingMethod.approval);
      expect(p.isExpired(DateTime.utc(2026, 6, 18)), isFalse);
      // Exactly at expiry counts as expired.
      expect(p.isExpired(DateTime.utc(2026, 6, 19, 9)), isTrue);
      expect(p.isExpired(DateTime.utc(2026, 6, 20)), isTrue);
    });

    test('optionIds reflects the options', () {
      expect(_party(VotingMethod.ranked).optionIds, {'a', 'b', 'c'});
    });

    test('copyWith toggles closed without disturbing other fields', () {
      final p = _party(VotingMethod.approval);
      final closed = p.copyWith(closed: true);
      expect(closed.closed, isTrue);
      expect(p.closed, isFalse);
      expect(closed.id, p.id);
      expect(closed.expiresAt, p.expiresAt);
    });
  });

  group('Ballot validation', () {
    test('approval ballot collapses duplicates into a set', () {
      final b = Ballot.approval(
        id: 'v1',
        party: _party(VotingMethod.approval),
        approvedOptionIds: ['a', 'a', 'b'],
      );
      expect(b.approvals, {'a', 'b'});
      expect(b.method, VotingMethod.approval);
      expect(b.ranking, isEmpty);
    });

    test('approval ballot rejects unknown options', () {
      expect(
        () => Ballot.approval(
          id: 'v1',
          party: _party(VotingMethod.approval),
          approvedOptionIds: ['a', 'zzz'],
        ),
        throwsArgumentError,
      );
    });

    test('empty approval ballot is allowed and reports isEmpty', () {
      final b = Ballot.approval(
        id: 'v1',
        party: _party(VotingMethod.approval),
        approvedOptionIds: const [],
      );
      expect(b.isEmpty, isTrue);
    });

    test('ranked ballot preserves order', () {
      final b = Ballot.ranked(
        id: 'v1',
        party: _party(VotingMethod.ranked),
        rankedOptionIds: const ['c', 'a', 'b'],
      );
      expect(b.ranking, ['c', 'a', 'b']);
      expect(b.approvals, isEmpty);
    });

    test('ranked ballot rejects duplicate preferences', () {
      expect(
        () => Ballot.ranked(
          id: 'v1',
          party: _party(VotingMethod.ranked),
          rankedOptionIds: const ['a', 'b', 'a'],
        ),
        throwsArgumentError,
      );
    });

    test('ranked ballot rejects unknown options', () {
      expect(
        () => Ballot.ranked(
          id: 'v1',
          party: _party(VotingMethod.ranked),
          rankedOptionIds: const ['a', 'nope'],
        ),
        throwsArgumentError,
      );
    });

    test('truncated ranked ballot (subset of options) is allowed', () {
      final b = Ballot.ranked(
        id: 'v1',
        party: _party(VotingMethod.ranked),
        rankedOptionIds: const ['b'],
      );
      expect(b.ranking, ['b']);
      expect(b.isEmpty, isFalse);
    });

    test('empty ranked ballot reports isEmpty', () {
      final b = Ballot.ranked(
        id: 'v1',
        party: _party(VotingMethod.ranked),
        rankedOptionIds: const [],
      );
      expect(b.isEmpty, isTrue);
    });
  });
}
