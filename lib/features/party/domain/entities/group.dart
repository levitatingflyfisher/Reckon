/// A persistent decision-making circle — a household, a couple, a founding
/// team. Where a [Party] is one decision, a group is the people who keep
/// deciding together: it scopes parties into a shared history and gives
/// ballots names. Immutable; local-first (names and rosters leave the device
/// only inside end-to-end-encrypted party blobs).
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    this.archived = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Archived groups are hidden from lists but never deleted — their
  /// decision history stays reachable.
  final bool archived;

  Group copyWith({String? name, bool? archived}) => Group(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );
}

/// One person's membership in a [Group]. [memberId] is their stable ghost
/// account id — the same id that attributes their ballots — and
/// [displayName] is what the group sees. One membership per person per group.
class GroupMember {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.displayName,
    required this.joinedAt,
  });

  final String id;
  final String groupId;
  final String memberId;
  final String displayName;
  final DateTime joinedAt;
}
