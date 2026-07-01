import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/predictions/domain/entities/forecaster_weights.dart';
import 'package:reckon/features/predictions/domain/entities/model_prediction.dart';
import 'package:reckon/features/predictions/domain/usecases/compute_forecaster_weights.dart';
import 'package:reckon/features/record/domain/usecases/compute_insight_cards.dart';

void main() {
  const compute = ComputeForecasterWeights();

  Case makeCase(String id, {String? category}) => Case(
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
        category: category,
      );

  Poll makePoll(String caseId, int pollNumber, int lean) => Poll(
        id: '$caseId-p$pollNumber',
        caseId: caseId,
        createdAt: DateTime(2026, 4, 10 + pollNumber),
        pollNumber: pollNumber,
        lean: lean,
        confidence: Confidence.medium,
      );

  ClosedCaseRecord record(
    String caseId, {
    List<int> leans = const [80],
    String? chosenOption = 'b',
    int satisfaction = 2,
    String? category,
  }) =>
      ClosedCaseRecord(
        case_: makeCase(caseId, category: category),
        polls: [
          for (var i = 0; i < leans.length; i++)
            makePoll(caseId, i + 1, leans[i]),
        ],
        satisfactionScore: satisfaction,
        chosenOption: chosenOption,
      );

  ModelPrediction scoredDuel(
    String id, {
    required String caseId,
    required String forecasterId,
    required double score,
    String? forecasterName,
  }) =>
      ModelPrediction(
        id: id,
        caseId: caseId,
        modelVersion: 'gemma#$forecasterId',
        kind: PredictionKind.duelForecast,
        predictedAt: DateTime(2026, 4, 11),
        payload: {
          'lean': 80,
          'rationale': 'r',
          'forecasterId': forecasterId,
          if (forecasterName != null) 'forecasterName': forecasterName,
        },
        score: score,
        scoredAt: DateTime(2026, 10, 12),
      );

  test('empty inputs yield a weightless user entry and not-enough-data',
      () {
    final weights = compute(predictions: const [], records: const []);
    expect(weights.hasEnoughData, isFalse);
    expect(weights.resolvedCaseCount, 0);
    final you = weights.entries.single;
    expect(you.isUser, isTrue);
    expect(you.sampleCount, 0);
    expect(you.meanScore, isNull);
    expect(you.weight, isNull);
  });

  test('user and forecasters are scored by the same rule and share '
      'normalized earned weight', () {
    // Five closed cases: user's final poll lean 80, chose b, glad (+2)
    // -> user sample score .6 each, mean .6.
    final records = [
      for (var i = 0; i < 5; i++) record('c$i'),
    ];
    // One forecaster with persisted scores of .2 on each case.
    final predictions = [
      for (var i = 0; i < 5; i++)
        scoredDuel('d$i',
            caseId: 'c$i',
            forecasterId: 'f1',
            forecasterName: 'Base-rate skeptic',
            score: 0.2),
    ];
    final weights = compute(predictions: predictions, records: records);
    expect(weights.hasEnoughData, isTrue);
    expect(weights.resolvedCaseCount, 5);

    final you = weights.entries.singleWhere((e) => e.isUser);
    final f1 = weights.entries.singleWhere((e) => !e.isUser);
    expect(you.sampleCount, 5);
    expect(you.meanScore, closeTo(0.6, 1e-9));
    expect(f1.displayName, 'Base-rate skeptic');
    expect(f1.sampleCount, 5);
    expect(f1.meanScore, closeTo(0.2, 1e-9));

    // raw = max(0, (mean+1)/2): you .8, f1 .6 -> weights .8/1.4 and .6/1.4.
    expect(you.weight, closeTo(0.8 / 1.4, 1e-9));
    expect(f1.weight, closeTo(0.6 / 1.4, 1e-9));
    expect(you.weight! + f1.weight!, closeTo(1.0, 1e-9));

    // Eligible entries are sorted by earned weight, best first.
    expect(weights.entries.first.isUser, isTrue);
  });

  test('the user entry scores the FINAL pre-decision poll', () {
    // Early poll leaned hard to a, final poll to b; user chose b, glad.
    final weights = compute(
      predictions: const [],
      records: [record('c1', leans: [20, 80])],
    );
    final you = weights.entries.single;
    expect(you.sampleCount, 1);
    expect(you.meanScore, closeTo(0.6, 1e-9));
  });

  test('entries below five samples are listed but carry no weight', () {
    final records = [for (var i = 0; i < 5; i++) record('c$i')];
    final predictions = [
      scoredDuel('d1', caseId: 'c0', forecasterId: 'f2', score: 1.0),
      scoredDuel('d2', caseId: 'c1', forecasterId: 'f2', score: 1.0),
    ];
    final weights = compute(predictions: predictions, records: records);
    final f2 = weights.entries.singleWhere((e) => e.forecasterId == 'f2');
    expect(f2.sampleCount, 2);
    expect(f2.meanScore, closeTo(1.0, 1e-9));
    expect(f2.eligible, isFalse);
    expect(f2.weight, isNull,
        reason: 'a hot streak of 2 must not outrank an earned record of 5');
    // The user, alone eligible, holds all the weight.
    final you = weights.entries.singleWhere((e) => e.isUser);
    expect(you.weight, closeTo(1.0, 1e-9));
  });

  test('a negative mean floors at zero earned weight', () {
    final records = [for (var i = 0; i < 5; i++) record('c$i')];
    final predictions = [
      for (var i = 0; i < 5; i++)
        scoredDuel('d$i', caseId: 'c$i', forecasterId: 'fbad', score: -1.0),
    ];
    final weights = compute(predictions: predictions, records: records);
    final bad = weights.entries.singleWhere((e) => e.forecasterId == 'fbad');
    expect(bad.eligible, isTrue);
    expect(bad.weight, closeTo(0.0, 1e-9));
    final you = weights.entries.singleWhere((e) => e.isUser);
    expect(you.weight, closeTo(1.0, 1e-9));
  });

  test('per-category means split by the case category', () {
    final records = [
      record('c1', category: 'career'),
      record('c2', category: 'home'),
      record('c3'), // null category -> uncategorized
    ];
    final predictions = [
      scoredDuel('d1', caseId: 'c1', forecasterId: 'f1', score: 1.0),
      scoredDuel('d2', caseId: 'c2', forecasterId: 'f1', score: 0.0),
      scoredDuel('d3', caseId: 'c3', forecasterId: 'f1', score: -1.0),
    ];
    final weights = compute(predictions: predictions, records: records);
    final f1 = weights.entries.singleWhere((e) => e.forecasterId == 'f1');
    final byLabel = {for (final c in f1.byCategory) c.label: c};
    expect(byLabel['career']!.meanScore, closeTo(1.0, 1e-9));
    expect(byLabel['career']!.sampleCount, 1);
    expect(byLabel['home']!.meanScore, closeTo(0.0, 1e-9));
    expect(byLabel['uncategorized']!.meanScore, closeTo(-1.0, 1e-9));

    final you = weights.entries.singleWhere((e) => e.isUser);
    expect({for (final c in you.byCategory) c.label},
        {'career', 'home', 'uncategorized'});
  });

  test('unscored rows, non-duel kinds, and rows without a forecasterId are '
      'ignored', () {
    final records = [record('c1')];
    final predictions = [
      // Unscored duel — still pending resolution elsewhere.
      ModelPrediction(
        id: 'pending',
        caseId: 'c1',
        modelVersion: 'm#f1',
        kind: PredictionKind.duelForecast,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'lean': 80, 'forecasterId': 'f1'},
      ),
      // Observation kind with a legacy blanket score.
      ModelPrediction(
        id: 'obs',
        caseId: 'c1',
        modelVersion: 'm',
        kind: PredictionKind.revealObservation,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'summary': 's'},
        score: 1.0,
        scoredAt: DateTime(2026, 10, 12),
      ),
      // Scored duel missing its forecasterId — nothing to attribute it to.
      ModelPrediction(
        id: 'anon',
        caseId: 'c1',
        modelVersion: 'm',
        kind: PredictionKind.duelForecast,
        predictedAt: DateTime(2026, 4, 11),
        payload: const {'lean': 80},
        score: 1.0,
        scoredAt: DateTime(2026, 10, 12),
      ),
    ];
    final weights = compute(predictions: predictions, records: records);
    expect(weights.entries.where((e) => !e.isUser), isEmpty);
  });

  test('records without polls or a chosen option add no user samples', () {
    final weights = compute(
      predictions: const [],
      records: [
        record('c1', leans: const []),
        record('c2', chosenOption: null),
        record('c3'),
      ],
    );
    final you = weights.entries.single;
    expect(you.sampleCount, 1);
    expect(weights.resolvedCaseCount, 3);
  });

  test('the user entry uses the reserved id', () {
    final weights = compute(predictions: const [], records: const []);
    expect(weights.entries.single.forecasterId, ForecasterWeights.userEntryId);
  });
}
