import 'party.dart';

/// One participant's vote in a [Party].
///
/// A ballot carries both shapes; which one is meaningful depends on the
/// party's [VotingMethod]:
///   * [VotingMethod.approval] — [approvals], an unordered set of approved
///     option ids (order irrelevant, duplicates impossible).
///   * [VotingMethod.ranked] — [ranking], an ordered list of option ids,
///     most→least preferred, with no duplicates.
///
/// Construct via [Ballot.approval] or [Ballot.ranked] so the unused shape is
/// always empty and the populated shape is validated against a [Party].
class Ballot {
  const Ballot._({
    required this.id,
    required this.method,
    required this.approvals,
    required this.ranking,
  });

  /// An approval ballot: the participant approves [approvedOptionIds].
  ///
  /// Order and repetition are irrelevant — they collapse into a set. Every id
  /// must reference an option that exists on [party].
  factory Ballot.approval({
    required String id,
    required Party party,
    required Iterable<String> approvedOptionIds,
  }) {
    assert(party.votingMethod == VotingMethod.approval,
        'approval ballot built for a ${party.votingMethod.name} party');
    final approvals = approvedOptionIds.toSet();
    final valid = party.optionIds;
    final unknown = approvals.difference(valid);
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown,
        'approvedOptionIds',
        'approval ballot references unknown option(s)',
      );
    }
    return Ballot._(
      id: id,
      method: VotingMethod.approval,
      approvals: Set.unmodifiable(approvals),
      ranking: const [],
    );
  }

  /// A ranked ballot: [rankedOptionIds] ordered most→least preferred.
  ///
  /// The list must contain no duplicates and every id must reference an option
  /// that exists on [party]. A ballot may rank a subset of options (a
  /// truncated ballot is legal).
  factory Ballot.ranked({
    required String id,
    required Party party,
    required List<String> rankedOptionIds,
  }) {
    assert(party.votingMethod == VotingMethod.ranked,
        'ranked ballot built for a ${party.votingMethod.name} party');
    if (rankedOptionIds.toSet().length != rankedOptionIds.length) {
      throw ArgumentError.value(
        rankedOptionIds,
        'rankedOptionIds',
        'ranked ballot contains duplicate preferences',
      );
    }
    final valid = party.optionIds;
    final unknown = rankedOptionIds.where((o) => !valid.contains(o)).toSet();
    if (unknown.isNotEmpty) {
      throw ArgumentError.value(
        unknown,
        'rankedOptionIds',
        'ranked ballot references unknown option(s)',
      );
    }
    return Ballot._(
      id: id,
      method: VotingMethod.ranked,
      approvals: const {},
      ranking: List.unmodifiable(rankedOptionIds),
    );
  }

  final String id;
  final VotingMethod method;

  /// Approved option ids (approval ballots). Empty for ranked ballots.
  final Set<String> approvals;

  /// Ordered preferences most→least (ranked ballots). Empty for approval.
  final List<String> ranking;

  /// Whether this ballot expresses no preference at all (a blank vote).
  bool get isEmpty => method == VotingMethod.approval
      ? approvals.isEmpty
      : ranking.isEmpty;
}
