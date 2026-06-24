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
  });

  final String id;
  final String title;
  final List<PartyOption> options;
  final VotingMethod votingMethod;
  final DateTime createdAt;
  final bool closed;

  /// The moment voting is intended to close: [createdAt] plus one week.
  DateTime get expiresAt => createdAt.add(kPartyLifetime);

  /// Whether the party has passed its [expiresAt] relative to [now].
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// The set of option ids defined on this party — used to validate ballots.
  Set<String> get optionIds => options.map((o) => o.id).toSet();

  Party copyWith({bool? closed}) => Party(
        id: id,
        title: title,
        options: options,
        votingMethod: votingMethod,
        createdAt: createdAt,
        closed: closed ?? this.closed,
      );
}
