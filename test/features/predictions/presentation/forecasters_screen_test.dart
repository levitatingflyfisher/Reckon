import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/predictions/data/prediction_providers.dart';
import 'package:reckon/features/predictions/domain/entities/forecaster_weights.dart';
import 'package:reckon/features/predictions/presentation/forecasters_screen.dart';
import 'package:reckon/features/record/data/record_providers.dart';
import 'package:reckon/features/record/domain/entities/update_quality.dart';

ForecasterWeightEntry _entry({
  required String id,
  required String name,
  bool isUser = false,
  required int n,
  double? mean,
  double? weight,
  List<CategoryScore> byCategory = const [],
}) =>
    ForecasterWeightEntry(
      forecasterId: id,
      displayName: name,
      isUser: isUser,
      sampleCount: n,
      meanScore: mean,
      byCategory: byCategory,
      weight: weight,
    );

void main() {
  Widget harness(ForecasterWeights weights, UpdateQuality quality) =>
      ProviderScope(
        overrides: [
          forecasterWeightsProvider.overrideWith((ref) async => weights),
          updateQualityProvider.overrideWith((ref) async => quality),
        ],
        child: const MaterialApp(home: ForecastersScreen()),
      );

  final richWeights = ForecasterWeights(
    resolvedCaseCount: 8,
    entries: [
      _entry(
        id: ForecasterWeights.userEntryId,
        name: 'You',
        isUser: true,
        n: 8,
        mean: 0.55,
        weight: 0.6,
        byCategory: const [
          CategoryScore(label: 'career', meanScore: 0.7, sampleCount: 5),
          CategoryScore(label: 'home', meanScore: 0.3, sampleCount: 3),
        ],
      ),
      _entry(
        id: 'persona-base-rate-skeptic',
        name: 'Base-rate skeptic',
        n: 6,
        mean: 0.1,
        weight: 0.4,
      ),
      _entry(id: 'f-new', name: 'Steelman advocate', n: 2, mean: 0.9),
    ],
  );

  testWidgets('shows earned weight, never verdicts', (tester) async {
    await tester.pumpWidget(harness(
      richWeights,
      const UpdateQuality(mean: 0.4, sampleCount: 7),
    ));
    await tester.pumpAndSettle();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Base-rate skeptic'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    // The language contract: weights are earned, nobody "beats" anybody.
    expect(find.textContaining('earned weight'), findsWidgets);
    expect(find.textContaining('beats'), findsNothing);
  });

  testWidgets('low-n entries are listed but not compared', (tester) async {
    await tester.pumpWidget(harness(
      richWeights,
      const UpdateQuality(mean: 0.4, sampleCount: 7),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Steelman advocate'), findsOneWidget);
    // 2 of 5 scored forecasts -> 3 more before comparison is honest.
    expect(find.textContaining('3 more'), findsOneWidget);
  });

  testWidgets('per-category record expands on tap', (tester) async {
    await tester.pumpWidget(harness(
      richWeights,
      const UpdateQuality(mean: 0.4, sampleCount: 7),
    ));
    await tester.pumpAndSettle();

    expect(find.text('career'), findsNothing);
    await tester.tap(find.text('You'));
    await tester.pumpAndSettle();
    expect(find.text('career'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('positive update quality gets positive framing',
      (tester) async {
    await tester.pumpWidget(harness(
      richWeights,
      const UpdateQuality(mean: 0.4, sampleCount: 7),
    ));
    await tester.pumpAndSettle();

    expect(find.text('YOUR UPDATES'), findsOneWidget);
    expect(find.textContaining('toward the option you ended up glad about'),
        findsOneWidget);
  });

  testWidgets('too little data shows honest progress copy, no comparisons',
      (tester) async {
    await tester.pumpWidget(harness(
      ForecasterWeights(
        resolvedCaseCount: 2,
        entries: [
          _entry(
            id: ForecasterWeights.userEntryId,
            name: 'You',
            isUser: true,
            n: 2,
            mean: 0.5,
          ),
        ],
      ),
      const UpdateQuality(mean: null, sampleCount: 0),
    ));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Not enough resolved decisions'), findsOneWidget);
    expect(find.textContaining('resolve 3 more'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('survives a narrow screen at large text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: harness(
        richWeights,
        const UpdateQuality(mean: 0.4, sampleCount: 7),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
