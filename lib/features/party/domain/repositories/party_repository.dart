import '../entities/ballot.dart';
import '../entities/party.dart';

/// Persistence + voting boundary for ReckonParty.
///
/// Stage 1 defines this interface only; a concrete implementation backed by
/// the Worker/backend is wired up in a later stage. [computeResult] returns a
/// method-specific result object ([ApprovalResult] or [RankedResult]); callers
/// switch on the party's [VotingMethod].
abstract class PartyRepository {
  /// Create and persist a new party, returning the stored entity.
  Future<Party> createParty({
    required String title,
    required List<PartyOption> options,
    required VotingMethod votingMethod,
  });

  /// Fetch a party by id, or null if it does not exist.
  Future<Party?> getParty(String id);

  /// Record one participant's [ballot] for the party with [partyId].
  Future<void> submitBallot(String partyId, Ballot ballot);

  /// Close voting on a party early (before its natural expiry).
  Future<void> closeParty(String partyId);

  /// Tally the party's ballots and return the outcome. The concrete type is an
  /// [ApprovalResult] or [RankedResult] depending on the party's method.
  Future<Object> computeResult(String partyId);
}
