import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/case/presentation/case_detail_screen.dart';
import 'package:reckon/features/forecasters/data/forecaster_providers.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';
import 'package:reckon/features/outside_view/data/outside_view_providers.dart';
import 'package:reckon/features/predictions/data/prediction_providers.dart';

import '../../forecasters/in_memory_fakes.dart';

const _caseId = 'case-entry';

Case _case(CaseStatus status) => Case(
      id: _caseId,
      createdAt: DateTime.utc(2026, 7, 11),
      deadline: null,
      status: status,
      question: 'Move to the cabin?',
      optionA: 'Stay in town',
      optionB: 'Move',
      statedCriteria: const [],
      stakes: Stakes.high,
      regretHorizon: RegretHorizon.years,
      category: 'relocation',
    );

void main() {
  Widget harness(CaseStatus status) => ProviderScope(
        overrides: [
          caseByIdProvider.overrideWith((ref, id) async => _case(status)),
          pollsForCaseProvider.overrideWith((ref, id) async => <Poll>[]),
          outsideViewForCaseProvider.overrideWith((ref, id) async => null),
          forecasterRepositoryProvider
              .overrideWithValue(InMemoryForecasterRepository()),
          predictionRepositoryProvider
              .overrideWithValue(InMemoryPredictionRepository()),
          runnableForecastersProvider
              .overrideWith((ref) async => <Forecaster>[]),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/case/$_caseId',
            routes: [
              GoRoute(
                path: '/case/:caseId',
                builder: (_, state) => CaseDetailScreen(
                    caseId: state.pathParameters['caseId']!),
              ),
              GoRoute(
                path: '/bounty/:caseId',
                builder: (_, __) =>
                    const Scaffold(body: Text('BOUNTY-STUB')),
              ),
            ],
          ),
        ),
      );

  testWidgets('an open case offers "Ask outside bots" in the overflow menu',
      (tester) async {
    await tester.pumpWidget(harness(CaseStatus.open));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask outside bots'));
    await tester.pumpAndSettle();

    expect(find.text('BOUNTY-STUB'), findsOneWidget);
  });

  testWidgets('a resolving case has no bounty entry (imports are for open '
      'cases only)', (tester) async {
    await tester.pumpWidget(harness(CaseStatus.resolving));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });
}
