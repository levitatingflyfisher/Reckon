import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/record/domain/usecases/compute_calibration_report.dart';
import 'package:reckon/features/record/domain/usecases/compute_insight_cards.dart';

Case _case({String id = 'c', String? category}) => Case(
      id: id,
      createdAt: DateTime(2026, 4, 1),
      deadline: null,
      status: CaseStatus.closed,
      question: 'q',
      optionA: 'a',
      optionB: 'b',
      statedCriteria: const [Criterion(label: 'x', weight: 1.0)],
      stakes: Stakes.medium,
      regretHorizon: RegretHorizon.months,
      category: category,
    );

Poll _poll({
  required int n,
  required int lean,
  required Confidence conf,
  String caseId = 'c',
}) =>
    Poll(
      id: 'p-$n',
      caseId: caseId,
      createdAt: DateTime(2026, 4, n),
      pollNumber: n,
      lean: lean,
      confidence: conf,
    );

void main() {
  const uc = ComputeCalibrationReport();

  test('sampleCount reflects record count; hasEnoughData at 5', () {
    final empty = uc.call(const []);
    expect(empty.sampleCount, 0);
    expect(empty.hasEnoughData, isFalse);

    final four = uc.call(List.generate(4, (i) => ClosedCaseRecord(
          case_: _case(id: 'c$i'),
          polls: const [],
          satisfactionScore: 1,
        )));
    expect(four.hasEnoughData, isFalse);

    final five = uc.call(List.generate(5, (i) => ClosedCaseRecord(
          case_: _case(id: 'c$i'),
          polls: const [],
          satisfactionScore: 1,
        )));
    expect(five.hasEnoughData, isTrue);
  });

  test('category stats are grouped, averaged, and sorted by meanSat desc', () {
    final records = [
      ClosedCaseRecord(case_: _case(id: '1', category: 'career'), polls: const [], satisfactionScore: 2),
      ClosedCaseRecord(case_: _case(id: '2', category: 'career'), polls: const [], satisfactionScore: 0),
      ClosedCaseRecord(case_: _case(id: '3', category: 'finance'), polls: const [], satisfactionScore: -1),
      ClosedCaseRecord(case_: _case(id: '4', category: null), polls: const [], satisfactionScore: 1),
    ];
    final report = uc.call(records);
    expect(report.categoryStats.map((c) => c.category),
        ['career', 'uncategorized', 'finance']);
    expect(report.categoryStats.first.meanSatisfaction, 1.0);
    expect(report.categoryStats.first.count, 2);
  });

  test('confidence buckets use the last poll per case', () {
    final records = [
      ClosedCaseRecord(
        case_: _case(id: '1'),
        polls: [
          _poll(n: 1, lean: 50, conf: Confidence.low),
          _poll(n: 2, lean: 70, conf: Confidence.high),
        ],
        satisfactionScore: 2,
      ),
      ClosedCaseRecord(
        case_: _case(id: '2'),
        polls: [_poll(n: 1, lean: 50, conf: Confidence.high, caseId: '2')],
        satisfactionScore: 0,
      ),
      ClosedCaseRecord(
        case_: _case(id: '3'),
        polls: [_poll(n: 1, lean: 50, conf: Confidence.medium, caseId: '3')],
        satisfactionScore: 1,
      ),
    ];
    final report = uc.call(records);
    final high = report.confidenceBuckets
        .firstWhere((b) => b.label == 'high');
    expect(high.count, 2);
    expect(high.meanSatisfaction, 1.0); // (2 + 0) / 2
    expect(report.confidenceBuckets.any((b) => b.label == 'low'), isFalse,
        reason: 'low was not the last-poll confidence of any case');
  });

  test('meanLeanDrift averages max-min swing across cases with ≥2 polls', () {
    final records = [
      ClosedCaseRecord(
        case_: _case(id: '1'),
        polls: [
          _poll(n: 1, lean: 50, conf: Confidence.medium),
          _poll(n: 2, lean: 80, conf: Confidence.medium),
        ],
        satisfactionScore: 1,
      ),
      ClosedCaseRecord(
        case_: _case(id: '2'),
        polls: [
          _poll(n: 1, lean: 60, conf: Confidence.medium, caseId: '2'),
          _poll(n: 2, lean: 70, conf: Confidence.medium, caseId: '2'),
        ],
        satisfactionScore: 1,
      ),
      // Single-poll case should be excluded from the drift computation.
      ClosedCaseRecord(
        case_: _case(id: '3'),
        polls: [_poll(n: 1, lean: 50, conf: Confidence.medium, caseId: '3')],
        satisfactionScore: 0,
      ),
    ];
    final report = uc.call(records);
    expect(report.meanLeanDrift, 20.0); // (30 + 10) / 2
  });
}
