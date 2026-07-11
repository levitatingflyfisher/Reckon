import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/presentation/party_create_screen.dart';

import 'party_screen_fakes.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PartyCreateScreen()),
      ),
    );
  }

  testWidgets('starts with a title field and two option fields', (t) async {
    await pump(t);
    // title + 2 options
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Start voting'), findsOneWidget);
  });

  testWidgets('Add option appends a field, up to the max', (t) async {
    await pump(t);
    await t.tap(find.text('Add option'));
    await t.pump();
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('Start voting is disabled until title + two options filled',
      (t) async {
    await pump(t);

    ElevatedButton button() => t.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start voting'));

    expect(button().onPressed, isNull); // nothing entered yet

    await t.enterText(find.byType(TextField).at(0), 'Where to eat?');
    await t.enterText(find.byType(TextField).at(1), 'Tacos');
    await t.enterText(find.byType(TextField).at(2), 'Sushi');
    await t.pump();

    expect(button().onPressed, isNotNull);
  });

  group('group-scoped creation', () {
    late FakePartyRepository repo;

    Future<void> pumpScoped(WidgetTester tester, {String? groupId}) async {
      repo = FakePartyRepository();
      final router = GoRouter(
        initialLocation:
            groupId == null ? '/party/create' : '/party/create?groupId=$groupId',
        routes: [
          GoRoute(
            path: '/party/create',
            builder: (_, s) =>
                PartyCreateScreen(groupId: s.uri.queryParameters['groupId']),
          ),
          GoRoute(
            path: '/party/:id/vote',
            builder: (_, __) => const Scaffold(body: Text('VOTE')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [partyRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester t) async {
      await t.enterText(find.byType(TextField).at(0), 'Where do we live?');
      await t.enterText(find.byType(TextField).at(1), 'City');
      await t.enterText(find.byType(TextField).at(2), 'Cabin');
      await t.pump();
    }

    testWidgets('a serious decision in a group is created sealed',
        (tester) async {
      await pumpScoped(tester, groupId: 'g1');
      await fill(tester);

      await tester.tap(find.text('Serious decision'));
      await tester.pump();
      // The grouped form is taller than the test viewport.
      await tester.scrollUntilVisible(find.text('Start voting'), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Start voting'));
      await tester.pumpAndSettle();

      final party = repo.parties.values.single;
      expect(party.groupId, 'g1');
      expect(party.considered, isTrue);
      expect(find.text('VOTE'), findsOneWidget);
    });

    testWidgets('the considered toggle defaults off', (tester) async {
      await pumpScoped(tester, groupId: 'g1');
      await fill(tester);
      await tester.scrollUntilVisible(find.text('Start voting'), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Start voting'));
      await tester.pumpAndSettle();

      expect(repo.parties.values.single.considered, isFalse);
    });

    testWidgets('an ungrouped decision offers no considered toggle',
        (tester) async {
      await pumpScoped(tester);
      expect(find.text('Serious decision'), findsNothing);
    });
  });
}
