import 'party.dart';

/// One option's standing in an [ApprovalResult].
class ApprovalTally {
  const ApprovalTally({
    required this.optionId,
    required this.approvals,
    required this.percentage,
  });

  final String optionId;

  /// Number of ballots that approved this option.
  final int approvals;

  /// [approvals] as a fraction of the total ballot count, in [0, 100].
  /// Zero when there are no ballots.
  final double percentage;
}

/// The outcome of an approval-voting [Party].
///
/// [tallies] are sorted by [ApprovalTally.approvals] descending, with ties
/// broken by ascending optionId for determinism.
class ApprovalResult {
  const ApprovalResult({
    required this.method,
    required this.ballotCount,
    required this.tallies,
    required this.winnerIds,
    required this.isContested,
  });

  final VotingMethod method;

  /// Total number of (non-discarded) ballots counted.
  final int ballotCount;

  final List<ApprovalTally> tallies;

  /// The leading option id(s). More than one id means a tie for first place.
  final List<String> winnerIds;

  /// Heuristic flag: the result is "contested"/bimodal when the top two
  /// options are within a small margin of each other (a near-tie), signalling
  /// the group is split rather than aligned.
  final bool isContested;
}

/// One candidate's tally within a single IRV round.
class RankedRoundTally {
  const RankedRoundTally({required this.optionId, required this.votes});

  final String optionId;

  /// First-choice votes among still-active candidates this round.
  final int votes;
}

/// A single Instant-Runoff Voting round.
class RankedRound {
  const RankedRound({
    required this.roundNumber,
    required this.tallies,
    required this.exhaustedBallots,
    required this.eliminatedOptionId,
    required this.winnerOptionId,
  });

  /// 1-based round index.
  final int roundNumber;

  /// Per-candidate tallies for this round, sorted by votes descending then
  /// ascending optionId.
  final List<RankedRoundTally> tallies;

  /// Ballots that had no remaining ranked-and-active preference this round.
  final int exhaustedBallots;

  /// The candidate eliminated at the end of this round, or null if the round
  /// produced a winner (no elimination needed).
  final String? eliminatedOptionId;

  /// The candidate that reached a majority this round, or null if the round
  /// ended in an elimination.
  final String? winnerOptionId;
}

/// The outcome of a ranked (IRV) [Party].
class RankedResult {
  const RankedResult({
    required this.method,
    required this.ballotCount,
    required this.winnerId,
    required this.rounds,
    required this.isContested,
  });

  final VotingMethod method;

  /// Total number of (non-empty) ballots counted.
  final int ballotCount;

  /// The winning option id, or null when there were no usable ballots.
  final String? winnerId;

  /// Round-by-round elimination history, in order.
  final List<RankedRound> rounds;

  /// Heuristic flag: the contest went the distance — the winner only emerged
  /// after eliminations (more than one round) and never held an outright
  /// first-round majority, signalling a split/bimodal electorate.
  final bool isContested;
}
