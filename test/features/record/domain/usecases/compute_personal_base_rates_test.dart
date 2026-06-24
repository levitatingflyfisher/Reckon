import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/record/domain/usecases/compute_insight_cards.dart';
import 'package:reckon/features/record/domain/usecases/compute_personal_base_rates.dart';

Case _c(String id, String? category) => Case(
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

Poll _p(String caseId, Confidence confidence) => Poll(
      id: '$caseId-1',
      caseId: caseId,
      createdAt: DateTime(2026, 1, 1),
      pollNumber: 1,
      lean: 50,
      confidence: confidence,
      revealed: true,
    );

ClosedCaseRecord _r(String id,
        {String? category, required Confidence confidence, required int score}) =>
    ClosedCaseRecord(
      case_: _c(id, category),
      polls: [_p(id, confidence)],
      satisfactionScore: score,
    );

void main() {
  const uc = ComputePersonalBaseRates();

  test('glad-rate and mean per category, sorted by glad-rate desc', () {
    final result = uc.call([
      _r('a1', category: 'career', confidence: Confidence.medium, score: 2),
      _r('a2', category: 'career', confidence: Confidence.medium, score: -1),
      _r('b1', category: 'family', confidence: Confidence.medium, score: 2),
      _r('b2', category: 'family', confidence: Confidence.medium, score: 1),
    ]);

    expect(result.sampleCount, 4);
    expect(result.byCategory.first.label, 'family'); // higher glad-rate first
    final family = result.byCategory.firstWhere((r) => r.label == 'family');
    final career = result.byCategory.firstWhere((r) => r.label == 'career');
    expect(family.gladRate, 1.0); // 2/2 glad
    expect(career.gladRate, 0.5); // 1/2 glad
    expect(career.meanSatisfaction, closeTo(0.5, 1e-9)); // (2 + -1)/2
  });

  test('confidence buckets are ordered low → high', () {
    final result = uc.call([
      _r('h', confidence: Confidence.high, score: 1),
      _r('l', confidence: Confidence.low, score: 1),
      _r('m', confidence: Confidence.medium, score: 1),
    ]);
    expect(result.byConfidence.map((r) => r.label).toList(),
        ['low', 'medium', 'high']);
  });

  test('overconfidence gap is negative when confident calls fared worse', () {
    // High-confidence cases: 1 of 2 glad (0.5). Low-confidence: 2 of 2 (1.0).
    final result = uc.call([
      _r('h1', confidence: Confidence.high, score: 2),
      _r('h2', confidence: Confidence.high, score: -2),
      _r('l1', confidence: Confidence.low, score: 1),
      _r('l2', confidence: Confidence.low, score: 1),
    ]);
    // gap = gladRate(high) - gladRate(low) = 0.5 - 1.0
    expect(result.overconfidenceGap, closeTo(-0.5, 1e-9));
  });

  test('gap is null with only one confidence level present', () {
    final result = uc.call([
      _r('m1', confidence: Confidence.medium, score: 1),
      _r('m2', confidence: Confidence.medium, score: -1),
    ]);
    expect(result.overconfidenceGap, isNull);
  });

  test('records with no polls are skipped for the confidence curve', () {
    final result = uc.call([
      ClosedCaseRecord(
          case_: _c('np', 'career'), polls: const [], satisfactionScore: 1),
      _r('m', confidence: Confidence.medium, score: 1),
    ]);
    expect(result.sampleCount, 2); // both count toward category rates
    expect(result.byConfidence, hasLength(1)); // only the one with a poll
    expect(result.byConfidence.single.label, 'medium');
  });

  test('hasEnoughData mirrors the 5-sample threshold', () {
    final few = uc.call([
      for (var i = 0; i < 4; i++)
        _r('c$i', confidence: Confidence.medium, score: 1),
    ]);
    expect(few.hasEnoughData, isFalse);
    final enough = uc.call([
      for (var i = 0; i < 5; i++)
        _r('c$i', confidence: Confidence.medium, score: 1),
    ]);
    expect(enough.hasEnoughData, isTrue);
  });
}
