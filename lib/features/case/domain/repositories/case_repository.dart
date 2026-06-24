import '../entities/case.dart';

abstract class CaseRepository {
  Future<void> insert(Case case_);
  Future<Case?> getById(String id);
  Future<List<Case>> getByStatus(CaseStatus status);
  Future<List<Case>> getClosed();
  Future<void> updateStatus(String id, CaseStatus status);
  Stream<List<Case>> watchAll();
  Stream<List<Case>> watchActive();

  /// Atomically reveal every poll for [caseId] and transition the case to
  /// [CaseStatus.decided], but only if it is currently [CaseStatus.open].
  /// A no-op if the case is missing or already in a later state — so it is
  /// safe to call from the reveal screen on re-entry.
  Future<void> markDecided(String caseId);
}
