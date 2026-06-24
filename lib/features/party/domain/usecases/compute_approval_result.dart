import '../entities/ballot.dart';
import '../entities/party.dart';
import '../entities/party_result.dart';

/// Tallies an approval-voting party.
///
/// Every option on the party is reported (those with zero approvals included),
/// sorted by approval count descending then by ascending optionId so the
/// ordering is deterministic. Percentages are of the total ballot count.
class ComputeApprovalResult {
  const ComputeApprovalResult();

  /// Margin (in percentage points of the ballot count) below which the top
  /// two options are considered a near-tie / contested split.
  static const double contestedMarginPct = 10.0;

  ApprovalResult call(Party party, List<Ballot> ballots) {
    final counts = <String, int>{for (final o in party.options) o.id: 0};
    for (final b in ballots) {
      for (final id in b.approvals) {
        // Defensive: ignore approvals for options not on the party.
        if (counts.containsKey(id)) counts[id] = counts[id]! + 1;
      }
    }

    final total = ballots.length;
    final tallies = counts.entries
        .map((e) => ApprovalTally(
              optionId: e.key,
              approvals: e.value,
              percentage: total == 0 ? 0 : e.value / total * 100,
            ))
        .toList()
      ..sort((a, b) {
        final byVotes = b.approvals.compareTo(a.approvals);
        return byVotes != 0 ? byVotes : a.optionId.compareTo(b.optionId);
      });

    final topVotes = tallies.isEmpty ? 0 : tallies.first.approvals;
    final winnerIds = topVotes == 0
        ? <String>[]
        : tallies
            .where((t) => t.approvals == topVotes)
            .map((t) => t.optionId)
            .toList();

    final isContested = _isContested(tallies, total);

    return ApprovalResult(
      method: VotingMethod.approval,
      ballotCount: total,
      tallies: tallies,
      winnerIds: winnerIds,
      isContested: isContested,
    );
  }

  bool _isContested(List<ApprovalTally> tallies, int total) {
    if (total == 0 || tallies.length < 2) return false;
    final first = tallies[0].approvals;
    if (first == 0) return false;
    final second = tallies[1].approvals;
    // An outright tie for first is contested; otherwise contested when the
    // top two are within the margin of each other.
    final marginPct = (first - second) / total * 100;
    return marginPct <= contestedMarginPct;
  }
}
