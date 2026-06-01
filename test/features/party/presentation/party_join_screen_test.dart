import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/database_providers.dart';
import 'package:reckon/features/party/presentation/party_join_screen.dart';
import 'package:reckon/features/party/sync/party_key_store.dart';
import 'package:reckon/features/party/sync/party_relay_resolver.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';

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
}
