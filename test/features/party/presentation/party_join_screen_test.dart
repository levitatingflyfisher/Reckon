import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/auth/auth_providers.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/database_providers.dart';
import 'package:reckon/features/party/data/group_providers.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/presentation/party_join_screen.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_relay_resolver.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';

import 'party_screen_fakes.dart';

/// Screen-level wiring for joining. The join *logic* (decrypt + import over a
/// channel) is covered by `party_sync_providers_test` and `sync_over_channel`;
/// here we verify the screen's button state, its call into the sync service,
/// and its error handling — without real crypto, which doesn't advance under
/// the widget tester's fake clock.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, {PartyRelayResolver? resolver}) async {
    final router = GoRouter(
      initialLocation: '/party/join',
      routes: [
        GoRoute(
            path: '/party/join', builder: (_, __) => const PartyJoinScreen()),
        GoRoute(
          path: '/party/:id/vote',
          builder: (_, state) =>
              Scaffold(body: Text('VOTING ${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          partyKeyStoreProvider.overrideWithValue(InMemoryPartyKeyStore()),
          if (resolver != null)
            partyRelayResolverProvider.overrideWithValue(resolver),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Join does nothing while the link field is empty',
      (tester) async {
    // Resolver would throw if join ran; an empty field must not run it.
    await pump(tester,
        resolver: (_) async => throw StateError('should not connect'));

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't join"), findsNothing);
    expect(find.text('Join a party'), findsOneWidget); // still on the screen
  });

  testWidgets('an invalid link shows an error and stays on the join screen',
      (tester) async {
    await pump(tester,
        resolver: (_) async => throw StateError('should not connect'));

    await tester.enterText(find.byType(TextField), 'https://example.com/nope');
    await tester.pump();
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't join"), findsOneWidget);
    expect(find.text('Join a party'), findsOneWidget); // still here
  });

  group('joining a group decision', () {
    late FakePartyRepository repo;
    late FakeGroupRepository groups;
    late RecordingSyncService sync;

    Party groupedParty() => Party(
          id: 'p1',
          title: 'Where do we live?',
          options: const [
            PartyOption(id: 'a', label: 'City'),
            PartyOption(id: 'b', label: 'Cabin'),
          ],
          votingMethod: VotingMethod.approval,
          createdAt: DateTime.utc(2026, 7, 11),
          groupId: 'g1',
        );

    Future<void> pumpFaked(WidgetTester tester) async {
      repo = FakePartyRepository();
      groups = FakeGroupRepository(repo);
      sync = RecordingSyncService(repo, groupsFake: groups)
        ..joinResult = groupedParty();
      final router = GoRouter(
        initialLocation: '/party/join',
        routes: [
          GoRoute(
              path: '/party/join',
              builder: (_, __) => const PartyJoinScreen()),
          GoRoute(
            path: '/party/:id/vote',
            builder: (_, __) => const Scaffold(body: Text('VOTE')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            partyRepositoryProvider.overrideWithValue(repo),
            groupRepositoryProvider.overrideWithValue(groups),
            partySyncServiceProvider.overrideWithValue(sync),
            authRepositoryProvider
                .overrideWithValue(FakeAuthRepository('m-me')),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> join(WidgetTester tester) async {
      await tester.enterText(
          find.byType(TextField).first, 'https://r.example/join/p1#k=x');
      await tester.pump();
      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();
    }

    testWidgets('prompts for your name and adds you to the roster',
        (tester) async {
      await pumpFaked(tester);
      await join(tester);

      // The group came along with the decision; now the app asks who you are.
      expect(find.textContaining('The household'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Ada');
      await tester.pump();
      await tester.tap(find.text('Join the group'));
      await tester.pumpAndSettle();

      final roster = await groups.membersOf('g1');
      expect(roster.single.memberId, 'm-me');
      expect(roster.single.displayName, 'Ada');
      expect(find.text('VOTE'), findsOneWidget);
    });

    testWidgets('declining the name still joins the decision',
        (tester) async {
      await pumpFaked(tester);
      await join(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(await groups.membersOf('g1'), isEmpty);
      expect(find.text('VOTE'), findsOneWidget);
    });

    testWidgets('a known member is not re-prompted', (tester) async {
      await pumpFaked(tester);
      await groups.addMember(
          groupId: 'g1', memberId: 'm-me', displayName: 'Ada');
      await join(tester);

      expect(find.text('Join the group'), findsNothing);
      expect(find.text('VOTE'), findsOneWidget);
    });
  });
}
