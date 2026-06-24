import '../entities/ballot.dart';
import '../entities/party.dart';
import '../entities/party_result.dart';

/// Resolves a ranked party by Instant-Runoff Voting (IRV).
///
/// Algorithm, each round:
///   1. Tally first choices among still-active candidates. For each ballot,
///      walk its ranking top→bottom and credit its highest-ranked candidate
///      that has not yet been eliminated. A ballot whose every ranked
///      preference has been eliminated is *exhausted* and contributes no vote
///      this round (and every later round).
///   2. If a candidate holds a strict majority of the votes cast this round
///      (> half of the non-exhausted ballots), that candidate wins. If only
///      one active candidate remains, it wins by default.
///   3. Otherwise eliminate the candidate with the fewest votes and repeat.
///      Votes transfer automatically next round via step 1.
///
/// Tie-break for elimination is deterministic: among candidates tied for the
/// fewest votes, eliminate the one whose optionId is lexicographically
/// greatest. (Equivalently: the lexicographically smallest id survives
/// longest.) This makes results reproducible without external randomness.
class ComputeRankedResult {
  const ComputeRankedResult();

  RankedResult call(Party party, List<Ballot> ballots) {
    // Empty ballots express no preference and never count.
    final usable = ballots.where((b) => b.ranking.isNotEmpty).toList();
    final ballotCount = usable.length;

    if (party.options.isEmpty || ballotCount == 0) {
      return RankedResult(
        method: VotingMethod.ranked,
        ballotCount: ballotCount,
        winnerId: null,
        rounds: const [],
        isContested: false,
      );
    }

    final active = party.optionIds;
    final rounds = <RankedRound>[];
    String? winner;
    var roundNumber = 0;

    while (true) {
      roundNumber++;
      final counts = <String, int>{for (final id in active) id: 0};
      var exhausted = 0;

      for (final b in usable) {
        final choice = _highestActive(b, active);
        if (choice == null) {
          exhausted++;
        } else {
          counts[choice] = counts[choice]! + 1;
        }
      }

      final tallies = _sortedTallies(counts);
      final votesCast = ballotCount - exhausted;

      // Majority is a strict majority of votes actually cast this round.
      final topVotes = tallies.isEmpty ? 0 : tallies.first.votes;
      final hasMajority = votesCast > 0 && topVotes * 2 > votesCast;

      if (hasMajority || active.length <= 1) {
        winner = topVotes == 0 ? null : tallies.first.optionId;
        rounds.add(RankedRound(
          roundNumber: roundNumber,
          tallies: tallies,
          exhaustedBallots: exhausted,
          eliminatedOptionId: null,
          winnerOptionId: winner,
        ));
        break;
      }

      final eliminated = _chooseEliminated(counts);
      rounds.add(RankedRound(
        roundNumber: roundNumber,
        tallies: tallies,
        exhaustedBallots: exhausted,
        eliminatedOptionId: eliminated,
        winnerOptionId: null,
      ));
      active.remove(eliminated);
    }

    // Contested heuristic: the winner needed eliminations to emerge — i.e. no
    // single option held an outright majority in round 1.
    final isContested = winner != null && rounds.length > 1;

    return RankedResult(
      method: VotingMethod.ranked,
      ballotCount: ballotCount,
      winnerId: winner,
      rounds: rounds,
      isContested: isContested,
    );
  }

  /// The ballot's highest-ranked preference that is still active, or null if
  /// the ballot is exhausted.
  String? _highestActive(Ballot b, Set<String> active) {
    for (final id in b.ranking) {
      if (active.contains(id)) return id;
    }
    return null;
  }

  List<RankedRoundTally> _sortedTallies(Map<String, int> counts) {
    return counts.entries
        .map((e) => RankedRoundTally(optionId: e.key, votes: e.value))
        .toList()
      ..sort((a, b) {
        final byVotes = b.votes.compareTo(a.votes);
        return byVotes != 0 ? byVotes : a.optionId.compareTo(b.optionId);
      });
  }

  /// Pick the candidate to eliminate: fewest votes, ties broken by
  /// lexicographically greatest optionId.
  String _chooseEliminated(Map<String, int> counts) {
    final minVotes =
        counts.values.reduce((a, b) => a < b ? a : b);
    final lowest = counts.entries
        .where((e) => e.value == minVotes)
        .map((e) => e.key)
        .toList()
      ..sort();
    return lowest.last;
  }
}
