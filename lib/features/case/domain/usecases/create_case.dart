import 'package:uuid/uuid.dart';
import '../entities/case.dart';
import '../entities/criterion.dart';
import '../repositories/case_repository.dart';

class CreateCase {
  CreateCase(this._cases, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final CaseRepository _cases;
  final Uuid _uuid;

  Future<Case> call({
    required String question,
    required String optionA,
    required String optionB,
    required List<Criterion> criteria,
    required Stakes stakes,
    required RegretHorizon regretHorizon,
    DateTime? deadline,
    String? category,
    DateTime? now,
  }) async {
    final case_ = Case(
      id: _uuid.v4(),
      createdAt: now ?? DateTime.now(),
      deadline: deadline,
      status: CaseStatus.open,
      question: question,
      optionA: optionA,
      optionB: optionB,
      statedCriteria: criteria,
      stakes: stakes,
      regretHorizon: regretHorizon,
      category: category,
    );
    await _cases.insert(case_);
    return case_;
  }
}
