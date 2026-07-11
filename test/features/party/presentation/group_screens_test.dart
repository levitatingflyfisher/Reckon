import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/auth/auth_providers.dart';
import 'package:reckon/features/party/data/group_providers.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/presentation/group_create_screen.dart';
import 'package:reckon/features/party/presentation/group_home_screen.dart';
import 'package:reckon/features/party/presentation/groups_screen.dart';

import 'party_screen_fakes.dart';

/// The group surfaces: the list of circles you decide with, creating one
/// (name + your own display name — the first user-entered identity in the
/// app, kept local), and a group's home with roster + decision history.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakePartyRepository partyRepo;
  late FakeGroupRepository groups;

  setUp(() {
    partyRepo = FakePartyRepository();
    groups = FakeGroupRepository(partyRepo);
  });

  Future<void> pump(WidgetTester tester, String initial) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
        GoRoute(
            path: '/groups/create',
            builder: (_, __) => const GroupCreateScreen()),
        GoRoute(
          path: '/group/:id',
          builder: (_, s) => GroupHomeScreen(groupId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/party/create',
          builder: (_, s) => Scaffold(
              body: Text(
                  'CREATE-FOR ${s.uri.queryParameters['groupId'] ?? 'none'}')),
        ),
        GoRoute(
          path: '/party/:id/result',
          builder: (_, s) =>
              Scaffold(body: Text('RESULT ${s.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partyRepositoryProvider.overrideWithValue(partyRepo),
          groupRepositoryProvider.overrideWithValue(groups),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository('m-me')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('GroupsScreen', () {
    testWidgets('empty state invites creating the first group',
        (tester) async {
      await pump(tester, '/groups');
      expect(find.textContaining('No groups yet'), findsOneWidget);
    });

    testWidgets('lists groups and opens a group home', (tester) async {
      await groups.createGroup(name: 'The household', id: 'g1');
      await groups.createGroup(name: 'Book club', id: 'g2');

      await pump(tester, '/groups');
      expect(find.text('The household'), findsOneWidget);
      expect(find.text('Book club'), findsOneWidget);

      await tester.tap(find.text('The household'));
      await tester.pumpAndSettle();
      expect(find.text('The household'), findsOneWidget); // now the app bar
    });

    testWidgets('the create affordance leads to the create screen',
        (tester) async {
      await pump(tester, '/groups');
      await tester.tap(find.text('New group'));
      await tester.pumpAndSettle();
      expect(find.text('Create group'), findsOneWidget);
    });
  });

  group('GroupCreateScreen', () {
    testWidgets('creates the group, adds yourself, and lands on its home',
        (tester) async {
      await pump(tester, '/groups/create');

      await tester.enterText(
          find.byType(TextField).at(0), 'The household');
      await tester.enterText(find.byType(TextField).at(1), 'Sam');
      await tester.pump();
      await tester.tap(find.text('Create group'));
      await tester.pumpAndSettle();

      expect(groups.groups.values.map((g) => g.name), ['The household']);
      final groupId = groups.groups.keys.single;
      final roster = await groups.membersOf(groupId);
      expect(roster.single.memberId, 'm-me');
      expect(roster.single.displayName, 'Sam');
      // Landed on the group home.
      expect(find.text('The household'), findsOneWidget);
      expect(find.text('New decision'), findsOneWidget);
    });

    testWidgets('needs both a group name and your name', (tester) async {
      await pump(tester, '/groups/create');
      await tester.enterText(find.byType(TextField).at(0), 'The household');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Create group'));
      expect(button.onPressed, isNull);
    });
  });

  group('GroupHomeScreen', () {
    testWidgets('shows roster and decision history', (tester) async {
      await groups.createGroup(name: 'The household', id: 'g1');
      await groups.addMember(
          groupId: 'g1', memberId: 'm-me', displayName: 'Sam');
      await groups.addMember(
          groupId: 'g1', memberId: 'm-ada', displayName: 'Ada');
      await partyRepo.createParty(
        title: 'Where do we live?',
        options: const [
          PartyOption(id: 'a', label: 'City'),
          PartyOption(id: 'b', label: 'Cabin'),
        ],
        votingMethod: VotingMethod.approval,
        groupId: 'g1',
        considered: true,
      );

      await pump(tester, '/group/g1');
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Where do we live?'), findsOneWidget);

      await tester.tap(find.text('Where do we live?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('RESULT'), findsOneWidget);
    });

    testWidgets('New decision is pre-scoped to the group', (tester) async {
      await groups.createGroup(name: 'The household', id: 'g1');
      await pump(tester, '/group/g1');

      await tester.tap(find.text('New decision'));
      await tester.pumpAndSettle();
      expect(find.text('CREATE-FOR g1'), findsOneWidget);
    });

    testWidgets('an unknown group says so instead of erroring',
        (tester) async {
      await pump(tester, '/group/ghost');
      expect(find.textContaining('not on this device'), findsOneWidget);
    });
  });
}
