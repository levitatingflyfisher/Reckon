import '../entities/poll.dart';

abstract class PollRepository {
  Future<void> insert(Poll poll);
  Future<List<Poll>> getByCaseId(String caseId);
  Future<void> markAllRevealed(String caseId);

  /// Atomically allocate the next sequential pollNumber for [caseId] and
  /// insert a new row. Implementations must perform the read-and-write inside
  /// a single transaction so concurrent callers cannot receive the same
  /// number.
  Future<Poll> insertNext({
    required String id,
    required String caseId,
    required DateTime createdAt,
    required int lean,
    required Confidence confidence,
    String? rationale,
  });
}
