import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/auth/auth_providers.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/presentation/party_vote_screen.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';

import 'party_screen_fakes.dart';

/// The vote screen is the sync layer's front door: a vote on a shared/joined
/// party must also reach the relay (the service call no screen made before the
/// wiring fix), a push failure must never lose the local vote, and a purely
/// local party must stay local. The real service→relay path is covered by the
/// LAN integration test; here we pin the screen's calls and failure handling.
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

  Future<void> pump(WidgetTester tester, String partyId,
      {FakeAuthRepository? auth}) async {
    final router = GoRouter(
      initialLocation: '/party/$partyId/vote',
      routes: [
        GoRoute(
          path: '/party/:id/vote',
          builder: (_, s) => PartyVoteScreen(partyId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/party/:id/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partyRepositoryProvider.overrideWithValue(repo),
          partySyncServiceProvider.overrideWithValue(sync),
          authRepositoryProvider
              .overrideWithValue(auth ?? FakeAuthRepository('m-me')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> vote(WidgetTester tester, String optionLabel) async {
    await tester.tap(find.text(optionLabel));
    await tester.pump();
    await tester.tap(find.text('Submit vote'));
    await tester.pumpAndSettle();
  }

  testWidgets('a vote on a synced party is pushed to the sync service',
      (tester) async {
    final party = await makeParty();
    await pump(tester, party.id);
    await vote(tester, 'Tacos');

    expect(find.text('RESULT'), findsOneWidget);
    expect(sync.pushed, hasLength(1));
    expect(sync.pushed.single.approvals, {'a'});
    expect(repo.ballots[party.id], hasLength(1));
  });

  testWidgets('a failed push still saves the vote locally and moves on',
      (tester) async {
    sync.failPush = true;
    final party = await makeParty();
    await pump(tester, party.id);
    await vote(tester, 'Tacos');

    expect(find.text('RESULT'), findsOneWidget);
    expect(find.textContaining('Saved on this device'), findsOneWidget);
    expect(repo.ballots[party.id], hasLength(1),
        reason: 'the local store is the source of truth — losing the vote '
            'because the host was unreachable would be worse than late sync');
    expect(sync.pushed, isEmpty);
  });

  testWidgets('a vote on a local-only party stays local, without complaint',
      (tester) async {
    sync.synced = false;
    final party = await makeParty();
    await pump(tester, party.id);
    await vote(tester, 'Sushi');

    expect(find.text('RESULT'), findsOneWidget);
    expect(find.textContaining('Saved on this device'), findsNothing);
    expect(sync.pushed, isEmpty);
    expect(repo.ballots[party.id], hasLength(1));
  });

  testWidgets('a vote in a group decision is attributed to this member',
      (tester) async {
    final party = await repo.createParty(
      title: 'Where do we live?',
      options: options,
      votingMethod: VotingMethod.approval,
      groupId: 'g1',
    );
    await pump(tester, party.id);
    await vote(tester, 'Tacos');

    expect(repo.ballots[party.id]!.single.memberId, 'm-me',
        reason: 'group decisions are attributed — the ghost account id is '
            'the member id');
  });

  testWidgets('a vote on an ungrouped party stays anonymous', (tester) async {
    final party = await makeParty();
    await pump(tester, party.id);
    await vote(tester, 'Tacos');

    expect(repo.ballots[party.id]!.single.memberId, isNull);
  });

  testWidgets(
      'a secure-storage failure on a group party surfaces and leaves the '
      'submit button alive', (tester) async {
    final party = await repo.createParty(
      title: 'Where do we live?',
      options: options,
      votingMethod: VotingMethod.approval,
      groupId: 'g1',
    );
    await pump(tester, party.id, auth: _ThrowingAuthRepository());
    await vote(tester, 'Tacos');

    // The failure is named, nothing was stored, and the voter can retry —
    // a silent permanently-dead button would strand the ballot.
    expect(find.textContaining("Couldn't submit"), findsOneWidget);
    expect(repo.ballots[party.id] ?? const [], isEmpty);
    expect(find.text('Submit vote'), findsOneWidget,
        reason: '_submitting must reset so a retry is possible');
  });
}

/// The known Android failure mode: flutter_secure_storage throwing while the
/// keystore is unavailable (e.g. right after unlock).
class _ThrowingAuthRepository extends FakeAuthRepository {
  @override
  Future<String> getOrCreateAccountId() async =>
      throw StateError('keystore unavailable');
}
