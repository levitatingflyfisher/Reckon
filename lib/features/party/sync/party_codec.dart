import '../domain/entities/ballot.dart';
import '../domain/entities/party.dart';

/// JSON serialization for the blobs that get encrypted and relayed. Kept out of
/// the domain entities so the entities stay transport-free; this is the only
/// place the wire shape of a synced party/ballot is defined.
class PartyCodec {
  const PartyCodec._();

  static Map<String, dynamic> partyToJson(Party p) => {
        'id': p.id,
        'title': p.title,
        'votingMethod': p.votingMethod.name,
        'options': [
          for (final o in p.options) {'id': o.id, 'label': o.label},
        ],
        'createdAt': p.createdAt.toUtc().toIso8601String(),
        'closed': p.closed,
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
      );

  static Map<String, dynamic> ballotToJson(Ballot b) => {
        'id': b.id,
        'method': b.method.name,
        'approvals': b.approvals.toList(),
        'ranking': b.ranking,
      };

  /// Rebuild a [Ballot] from json, validating it against [party] via the same
  /// factories used locally. Throws [ArgumentError] if the ballot references
  /// options the party doesn't have.
  static Ballot ballotFromJson(Map<String, dynamic> j, Party party) {
    final id = j['id'] as String;
    final method = j['method'] as String;
    if (method == VotingMethod.ranked.name) {
      return Ballot.ranked(
        id: id,
        party: party,
        rankedOptionIds: (j['ranking'] as List).cast<String>(),
      );
    }
    return Ballot.approval(
      id: id,
      party: party,
      approvedOptionIds: (j['approvals'] as List).cast<String>(),
    );
  }
}
