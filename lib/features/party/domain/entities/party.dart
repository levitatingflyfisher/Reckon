/// The voting system used to tally a [Party]'s ballots.
enum VotingMethod {
  /// Each participant approves any number of options; the option with the most
  /// approvals wins.
  approval,

  /// Each participant ranks options most→least preferred; resolved by
  /// Instant-Runoff Voting (IRV).
  ranked,
}

/// A single choosable option within a [Party].
class PartyOption {
  const PartyOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is PartyOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// How long a party stays open for voting once created.
const Duration kPartyLifetime = Duration(days: 7);

/// A group decision: a titled question, a fixed set of [options], and the
/// [votingMethod] used to resolve submitted ballots.
///
/// Immutable. A party opens at [createdAt] and is intended to close at
/// [expiresAt] (createdAt + 7 days) unless [closed] is set earlier.
class Party {
  const Party({
    required this.id,
    required this.title,
    required this.options,
    required this.votingMethod,
    required this.createdAt,
    this.closed = false,
    this.groupId,
    this.considered = false,
  });

  final String id;
  final String title;
  final List<PartyOption> options;
  final VotingMethod votingMethod;
  final DateTime createdAt;
  final bool closed;

  /// The persistent group this decision belongs to; null for the original
  /// one-shot (ungrouped) parties.
  final String? groupId;

  /// Considered mode, for the where-do-we-live class of decisions: tallies
  /// stay hidden while voting is open so nobody anchors on a running score,
  /// and closing the vote is the mutual reveal.
  final bool considered;

  /// The moment voting is intended to close: [createdAt] plus one week.
  DateTime get expiresAt => createdAt.add(kPartyLifetime);

  /// Whether the party has passed its [expiresAt] relative to [now].
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// The set of option ids defined on this party — used to validate ballots.
  Set<String> get optionIds => options.map((o) => o.id).toSet();

  /// Whether the tally must stay hidden right now. True only for a considered
  /// party that is still open — closing reveals, mutually, for everyone.
  /// (Doc note for the yellow paper: this is a *client-side* courtesy, not a
  /// cryptographic guarantee — every ballot-holding device can decrypt every
  /// ballot; considered mode changes what the UI shows, not what keys unlock.)
  bool get resultsSealed => considered && !closed;

  Party copyWith({bool? closed}) => Party(
        id: id,
        title: title,
        options: options,
        votingMethod: votingMethod,
        createdAt: createdAt,
        closed: closed ?? this.closed,
        groupId: groupId,
        considered: considered,
      );
}
