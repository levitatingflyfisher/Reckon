import '../repositories/case_repository.dart';

class MarkDecided {
  MarkDecided(this._cases);
  final CaseRepository _cases;

  Future<void> call(String caseId) => _cases.markDecided(caseId);
}
