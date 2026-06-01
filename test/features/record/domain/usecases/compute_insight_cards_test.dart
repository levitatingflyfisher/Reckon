import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/record/domain/usecases/compute_insight_cards.dart';

Case _c(String id, String category) => Case(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      deadline: null,
      status: CaseStatus.closed,
      question: 'q',
      optionA: 'a',
      optionB: 'b',
      statedCriteria: const [Criterion(label: 'comp', weight: 1)],
      stakes: Stakes.medium,
      regretHorizon: RegretHorizon.months,
      category: category,
    );

Poll _p(String caseId, int n, int lean) => Poll(
      id: '$caseId-$n',
      caseId: caseId,
      createdAt: DateTime(2026, 1, n),
      pollNumber: n,
      lean: lean,
      confidence: Confidence.medium,
      revealed: true,
    );

void main() {
  const uc = ComputeInsightCards();

  test('returns no cards when fewer than 5 records', () {
    final records = List.generate(
      4,
      (i) => ClosedCaseRecord(
        case_: _c('c$i', 'career'),
        polls: [_p('c$i', 1, 50)],
        satisfactionScore: 1,
      ),
    );
    expect(uc.call(records), isEmpty);
  });

  test('surfaces category pattern when categories differ and means diverge',
      () {
    final records = [
      for (var i = 0; i < 3; i++)
        ClosedCaseRecord(
          case_: _c('career-$i', 'career'),
          polls: [_p('career-$i', 1, 50)],
          satisfactionScore: 2,
        ),
      for (var i = 0; i < 3; i++)
        ClosedCaseRecord(
          case_: _c('rel-$i', 'relationship'),
          polls: [_p('rel-$i', 1, 50)],
          satisfactionScore: -1,
        ),
    ];
    final cards = uc.call(records);
    expect(cards, isNotEmpty);
    expect(cards.any((c) => c.title == 'Category patterns'), true);
  });
}
