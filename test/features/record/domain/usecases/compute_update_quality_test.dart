import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/record/domain/usecases/compute_insight_cards.dart';
import 'package:reckon/features/record/domain/usecases/compute_update_quality.dart';

void main() {
  const compute = ComputeUpdateQuality();

  Case makeCase(String id) => Case(
        id: id,
        createdAt: DateTime(2026, 4, 10),
        deadline: null,
        status: CaseStatus.closed,
        question: 'q',
        optionA: 'a',
        optionB: 'b',
        statedCriteria: const [],
        stakes: Stakes.medium,
        regretHorizon: RegretHorizon.months,
        category: null,
      );

  ClosedCaseRecord record(
    String caseId, {
    required List<int> leans,
    String? chosenOption = 'b',
    int satisfaction = 2,
  }) =>
      ClosedCaseRecord(
        case_: makeCase(caseId),
        polls: [
          for (var i = 0; i < leans.length; i++)
            Poll(
              id: '$caseId-p$i',
              caseId: caseId,
              createdAt: DateTime(2026, 4, 10 + i),
              pollNumber: i + 1,
              lean: leans[i],
              confidence: Confidence.medium,
            ),
        ],
        satisfactionScore: satisfaction,
        chosenOption: chosenOption,
      );

  test('empty input has no signal', () {
    final q = compute(const []);
    expect(q.sampleCount, 0);
    expect(q.mean, isNull);
    expect(q.hasEnoughData, isFalse);
  });

  test('moving toward the option you ended up glad about scores positive',
      () {
    // p_chosen went .4 -> .8, satisfaction +2: (0.8-0.4) * 2 = 0.8
    final q = compute([record('c1', leans: const [40, 80])]);
    expect(q.sampleCount, 1);
    expect(q.mean, closeTo(0.8, 1e-9));
  });

  test('moving toward the option you came to regret scores negative', () {
    // Moved toward b, but b felt wrong: 0.4 * -2 = -0.8
    final q = compute([
      record('c1', leans: const [40, 80], satisfaction: -2),
    ]);
    expect(q.mean, closeTo(-0.8, 1e-9));
  });

  test('orientation respects the chosen option', () {
    // Leans drift toward b while the user finally chose a and was glad:
    // p_chosen .6 -> .2, diff -.4, * 2 = -0.8 — drifted away from the
    // option that turned out right.
    final q = compute([
      record('c1', leans: const [40, 80], chosenOption: 'a'),
    ]);
    expect(q.mean, closeTo(-0.8, 1e-9));
  });

  test('a single case clamps to [-1, +1]', () {
    // (0.9 - 0.1) * 2 = 1.6 -> clamped to 1.
    final up = compute([record('c1', leans: const [10, 90])]);
    expect(up.mean, closeTo(1.0, 1e-9));
    // (0.1 - 0.9) * 2 = -1.6 -> clamped to -1.
    final down = compute([record('c1', leans: const [90, 10])]);
    expect(down.mean, closeTo(-1.0, 1e-9));
  });

  test('only the first and last polls matter — intermediate wobble is free',
      () {
    final q = compute([
      record('c1', leans: const [40, 5, 95, 80]),
    ]);
    expect(q.mean, closeTo(0.8, 1e-9));
  });

  test('neutral satisfaction carries no signal', () {
    final q = compute([
      record('c1', leans: const [40, 80], satisfaction: 0),
    ]);
    expect(q.mean, closeTo(0.0, 1e-9));
    expect(q.sampleCount, 1);
  });

  test('cases with fewer than two polls or no chosen option are excluded',
      () {
    final q = compute([
      record('c1', leans: const [40]),
      record('c2', leans: const [40, 80], chosenOption: null),
      record('c3', leans: const [40, 80]),
    ]);
    expect(q.sampleCount, 1);
    expect(q.mean, closeTo(0.8, 1e-9));
  });

  test('aggregates the mean over qualifying cases and gates at five', () {
    final q = compute([
      for (var i = 0; i < 5; i++)
        record('c$i', leans: const [40, 80]), // 0.8 each
    ]);
    expect(q.sampleCount, 5);
    expect(q.mean, closeTo(0.8, 1e-9));
    expect(q.hasEnoughData, isTrue);

    final few = compute([
      for (var i = 0; i < 4; i++) record('c$i', leans: const [40, 80]),
    ]);
    expect(few.hasEnoughData, isFalse);
  });
}
