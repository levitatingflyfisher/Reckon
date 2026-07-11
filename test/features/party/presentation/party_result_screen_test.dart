import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/presentation/party_result_screen.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';

import 'party_screen_fakes.dart';

/// The result screen is the other half of the sync wiring: for a shared or
/// joined party it must pull remote ballots (on open, on demand, and
/// periodically while the screen is up) and closing the vote must reach the
/// relay — otherwise remote guests keep voting into a void.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakePartyRepository repo;
  late RecordingSyncService sync;

  setUp(() {
    repo = FakePartyRepository();
    sync = RecordingSyncService(repo);
  });

  const options = [
    PartyOption(id: 'a', label: 'Tacos'),
    PartyOption(id: 'b', label: 'Sushi'),
  ];

  Future<Party> makeParty() => repo.createParty(
        title: 'Dinner?',
        options: options,
        votingMethod: VotingMethod.approval,
      );

  Ballot remoteBallot(Party party, String id) =>
      Ballot.approval(id: id, party: party, approvedOptionIds: const ['b']);

  Future<void> pump(WidgetTester tester, String partyId) async {
    final router = GoRouter(
      initialLocation: '/party/$partyId/result',
      routes: [
        GoRoute(
          path: '/party/:id/result',
          builder: (_, s) =>
              PartyResultScreen(partyId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/party/:id/vote',
          builder: (_, __) => const Scaffold(body: Text('VOTE')),
        ),
        GoRoute(
          path: '/intake',
          builder: (_, __) => const Scaffold(body: Text('INTAKE')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partyRepositoryProvider.overrideWithValue(repo),
          partySyncServiceProvider.overrideWithValue(sync),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Dispose the screen so its periodic pull timer is cancelled before the
  /// test ends (pending timers fail the test otherwise).
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('opening the result screen pulls remote ballots',
      (tester) async {
    final party = await makeParty();
    sync.pendingRemote[party.id] = [remoteBallot(party, 'remote-1')];

    await pump(tester, party.id);

    expect(sync.pullCount, greaterThanOrEqualTo(1));
    expect(find.text('1 vote(s) · approval'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the refresh button pulls ballots cast since opening',
      (tester) async {
    final party = await makeParty();
    await pump(tester, party.id);
    expect(find.text('0 vote(s) · approval'), findsOneWidget);

    sync.pendingRemote[party.id] = [remoteBallot(party, 'remote-2')];
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('1 vote(s) · approval'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the screen keeps pulling on its own while open',
      (tester) async {
    final party = await makeParty();
    await pump(tester, party.id);
    final afterOpen = sync.pullCount;

    sync.pendingRemote[party.id] = [remoteBallot(party, 'remote-3')];
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(sync.pullCount, greaterThan(afterOpen));
    expect(find.text('1 vote(s) · approval'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('closing a synced party closes it on the relay too',
      (tester) async {
    final party = await makeParty();
    await pump(tester, party.id);

    await tester.tap(find.text('Close voting'));
    await tester.pumpAndSettle();

    expect(sync.closedOnRelay, isTrue);
    expect(find.text('Close voting'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a local-only party shows no refresh affordance and never pulls',
      (tester) async {
    sync.synced = false;
    final party = await makeParty();
    await pump(tester, party.id);

    expect(find.byIcon(Icons.refresh), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    expect(sync.pullCount, 0);
    await unmount(tester);
  });
}
