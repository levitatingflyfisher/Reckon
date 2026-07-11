import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';

/// JSON serialization for the blobs that get encrypted and relayed. Kept out of
/// the domain entities so the entities stay transport-free; this is the only
/// place the wire shape of a synced party/ballot is defined.
///
/// Persistent groups extend both shapes, always optionally (absent = the
/// legacy anonymous/ungrouped form, so pre-group blobs keep decoding):
///
///   party  += `considered: bool`,
///             `group: {id, name}` — the manifest a joiner uses to auto-create
///             the group locally. Driven only by the `group` argument; the
///             codec never invents a manifest it wasn't given.
///   ballot += `member: {id, displayName?}` — attribution for group decisions.
///
/// Doc note for the yellow paper / ADR: everything here rides INSIDE the
/// AES-GCM blobs. Group names, member ids and display names are visible to
/// key holders (the group), never to the relay — the Z-property is unchanged.
/// What DOES change is the peer-facing anonymity model: attributed ballots
/// mean members see who voted for what, by design (a household deciding
/// together), where the original party ballots were anonymous even to other
/// voters.
class PartyCodec {
  const PartyCodec._();

  static Map<String, dynamic> partyToJson(
    Party p, {
    ({String id, String name})? group,
  }) =>
      {
        'id': p.id,
        'title': p.title,
        'votingMethod': p.votingMethod.name,
        'options': [
          for (final o in p.options) {'id': o.id, 'label': o.label},
        ],
        'createdAt': p.createdAt.toUtc().toIso8601String(),
        'closed': p.closed,
        'considered': p.considered,
        if (group != null) 'group': {'id': group.id, 'name': group.name},
      };

  static Party partyFromJson(Map<String, dynamic> j) => Party(
        id: j['id'] as String,
        title: j['title'] as String,
        votingMethod: VotingMethod.values.firstWhere(
          (m) => m.name == j['votingMethod'],
          orElse: () => VotingMethod.approval,
        ),
        options: [
          for (final o in (j['options'] as List).cast<Map<String, dynamic>>())
            PartyOption(id: o['id'] as String, label: o['label'] as String),
        ],
        createdAt: DateTime.parse(j['createdAt'] as String),
        closed: (j['closed'] as bool?) ?? false,
        considered: (j['considered'] as bool?) ?? false,
        groupId: ((j['group'] as Map?)?['id']) as String?,
      );

  /// The group manifest carried by a party blob, if any — what a joining
  /// device needs to create the group locally under its original id.
  static ({String id, String name})? groupManifestOf(Map<String, dynamic> j) {
    final group = j['group'] as Map?;
    final id = group?['id'] as String?;
    final name = group?['name'] as String?;
    if (id == null || name == null) return null;
    return (id: id, name: name);
  }

  /// [memberDisplayName] is the sender's roster name for the ballot's member;
  /// the id comes from the ballot itself. Anonymous ballots (no memberId)
  /// never gain a member field.
  static Map<String, dynamic> ballotToJson(
    Ballot b, {
    String? memberDisplayName,
  }) =>
      {
        'id': b.id,
        'method': b.method.name,
        'approvals': b.approvals.toList(),
        'ranking': b.ranking,
        if (b.memberId != null)
          'member': {
            'id': b.memberId,
            if (memberDisplayName != null) 'displayName': memberDisplayName,
          },
      };

  /// Rebuild a [Ballot] from json, validating it against [party] via the same
  /// factories used locally. Throws [ArgumentError] if the ballot references
  /// options the party doesn't have.
  static Ballot ballotFromJson(Map<String, dynamic> j, Party party) {
    final id = j['id'] as String;
    final method = j['method'] as String;
    final memberId = ((j['member'] as Map?)?['id']) as String?;
    if (method == VotingMethod.ranked.name) {
      return Ballot.ranked(
        id: id,
        party: party,
        rankedOptionIds: (j['ranking'] as List).cast<String>(),
        memberId: memberId,
      );
    }
    return Ballot.approval(
      id: id,
      party: party,
      approvedOptionIds: (j['approvals'] as List).cast<String>(),
      memberId: memberId,
    );
  }

  /// The member attribution carried by a ballot blob, if any. The display
  /// name is optional — receivers use it to keep their roster current, but
  /// the id alone still attributes the ballot.
  static ({String id, String? displayName})? memberOf(Map<String, dynamic> j) {
    final member = j['member'] as Map?;
    final id = member?['id'] as String?;
    if (id == null) return null;
    return (id: id, displayName: member?['displayName'] as String?);
  }
}
