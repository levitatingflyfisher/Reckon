import 'criterion.dart';

enum CaseStatus { open, decided, resolving, closed }

enum Stakes { low, medium, high }

enum RegretHorizon { weeks, months, years }

class Case {
  const Case({
    required this.id,
    required this.createdAt,
    required this.deadline,
    required this.status,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.statedCriteria,
    required this.stakes,
    required this.regretHorizon,
    this.category,
    this.communityVisible = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? deadline;
  final CaseStatus status;
  final String question;
  final String optionA;
  final String optionB;
  final List<Criterion> statedCriteria;
  final Stakes stakes;
  final RegretHorizon regretHorizon;
  final String? category;

  /// Reserved for the Phase-3 community layer; persisted but not yet surfaced.
  final bool communityVisible;

  Case copyWith({
    CaseStatus? status,
    String? category,
  }) =>
      Case(
        id: id,
        createdAt: createdAt,
        deadline: deadline,
        status: status ?? this.status,
        question: question,
        optionA: optionA,
        optionB: optionB,
        statedCriteria: statedCriteria,
        stakes: stakes,
        regretHorizon: regretHorizon,
        category: category ?? this.category,
        communityVisible: communityVisible,
      );
}
