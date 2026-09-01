import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';
import 'package:reckon/core/auth/auth_providers.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/presentation/case_summary_screen.dart';
import 'package:reckon/features/case/presentation/home_screen.dart';
import 'package:reckon/features/case/presentation/repoll_screen.dart';
import 'package:reckon/features/onboarding/presentation/auth_tier_screen.dart';
import 'package:reckon/features/onboarding/presentation/first_case_prompt_screen.dart';
import 'package:reckon/features/onboarding/presentation/model_onboarding_screen.dart';
import 'package:reckon/features/party/data/party_providers.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/presentation/party_create_screen.dart';
import 'package:reckon/features/party/presentation/party_vote_screen.dart';
import 'package:reckon/features/party/sync/party_sync_providers.dart';
import 'package:reckon/features/reveal/presentation/resolution_checkin_screen.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

import '../features/party/presentation/party_screen_fakes.dart';

/// Roadmap item 24 / C5-primaryScreens: on every screen that owns a primary
/// action, that action must be reachable at 360 dp with the font one notch
/// up (1.3x, an ordinary Android setting), and nothing may overflow at
/// 320 dp x 3.0. Reckon's onboarding once failed exactly this: the only
/// working button was laid out below the bottom of the screen.
class _NothingDownloaded extends ModelDownloadService {
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async => false;
}

final _case = Case(
  id: 'c1',
  createdAt: DateTime(2026, 9, 1),
  deadline: DateTime(2026, 10, 1),
  status: CaseStatus.open,
  question: 'Should we move to the coast before the school year starts?',
  optionA: 'Move this summer',
  optionB: 'Stay another year',
  statedCriteria: const [],
  stakes: Stakes.high,
  regretHorizon: RegretHorizon.years,
);

/// Pumps [home] in Reckon's light theme behind a router, so screens that
/// navigate on their primary action have somewhere to go.
Widget _app(Widget home, {List<Override> overrides = const []}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: '/:rest(.*)',
        builder: (_, __) => const Scaffold(body: Text('ELSEWHERE')),
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(theme: ReckonTheme.light(), routerConfig: router),
  );
}

/// runPrimaryActionSweep checks reach and overflow, but OHButton ellipsizes
/// a long label instead of overflowing, which neither check sees. At
/// 360 dp x 1.3 the primary action's words must be whole.
Future<void> _expectWholeLabel(
  WidgetTester tester,
  Future<void> Function() pumpScreen,
  Finder primaryAction,
) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await pumpScreen();
  await tester.pumpAndSettle();
  await tester.ensureVisible(primaryAction.first);
  await tester.pumpAndSettle();
  final texts = find.descendant(
    of: primaryAction.first,
    matching: find.byType(RichText),
  );
  final paragraphs = [
    if (texts.evaluate().isNotEmpty)
      for (final e in texts.evaluate()) e.renderObject! as RenderParagraph
    else
      tester.renderObject<RenderParagraph>(primaryAction.first),
  ];
  for (final para in paragraphs) {
    final text = para.text.toPlainText();
    if (text.trim().isEmpty) continue; // an icon glyph
    expect(para.didExceedMaxLines, isFalse, reason: 'label cut: "$text"');
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Home: New case', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(
        _app(
          const HomeScreen(),
          overrides: [
            openCasesStreamProvider.overrideWith(
              (ref) => Stream.value([_case]),
            ),
          ],
        ),
      ),
      primaryAction: find.byType(FloatingActionButton),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(
        _app(
          const HomeScreen(),
          overrides: [
            openCasesStreamProvider.overrideWith(
              (ref) => Stream.value([_case]),
            ),
          ],
        ),
      ),
      find.byType(FloatingActionButton),
    );
  });

  testWidgets('Onboarding, privacy: Continue', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(_app(const AuthTierScreen())),
      primaryAction: find.text('Continue privately'),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(_app(const AuthTierScreen())),
      find.text('Continue privately'),
    );
  });

  testWidgets('Onboarding, model: Download', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(
        _app(
          const ModelOnboardingScreen(),
          overrides: [
            onDeviceModelSupportedProvider.overrideWithValue(true),
            selectedModelIdProvider.overrideWith((ref) async => null),
            modelDownloadServiceProvider.overrideWithValue(
              _NothingDownloaded(),
            ),
          ],
        ),
      ),
      primaryAction: find.textContaining('Download ('),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(
        _app(
          const ModelOnboardingScreen(),
          overrides: [
            onDeviceModelSupportedProvider.overrideWithValue(true),
            selectedModelIdProvider.overrideWith((ref) async => null),
            modelDownloadServiceProvider.overrideWithValue(
              _NothingDownloaded(),
            ),
          ],
        ),
      ),
      find.textContaining('Download ('),
    );
  });

  testWidgets('Onboarding, first case: Open', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(_app(const FirstCasePromptScreen())),
      primaryAction: find.byKey(const Key('first-case-open')),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(_app(const FirstCasePromptScreen())),
      find.byKey(const Key('first-case-open')),
    );
  });

  testWidgets('Summary: Save this decision', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(
        _app(
          CaseSummaryScreen(
            draft: CaseDraft(
              question: _case.question,
              optionA: _case.optionA,
              optionB: _case.optionB,
              stakes: Stakes.high,
              regretHorizon: RegretHorizon.years,
              deadline: null,
              statedCriteria: const [],
              category: null,
            ),
          ),
        ),
      ),
      primaryAction: find.byKey(const Key('case-summary-save')),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(
        _app(
          CaseSummaryScreen(
            draft: CaseDraft(
              question: _case.question,
              optionA: _case.optionA,
              optionB: _case.optionB,
              stakes: Stakes.high,
              regretHorizon: RegretHorizon.years,
              deadline: null,
              statedCriteria: const [],
              category: null,
            ),
          ),
        ),
      ),
      find.byKey(const Key('case-summary-save')),
    );
  });

  testWidgets('Check-in: Save', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(
        _app(
          RepollScreen(caseId: _case.id),
          overrides: [
            caseByIdProvider(_case.id).overrideWith((ref) async => _case),
          ],
        ),
      ),
      primaryAction: find.byKey(const Key('repoll-save')),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(
        _app(
          RepollScreen(caseId: _case.id),
          overrides: [
            caseByIdProvider(_case.id).overrideWith((ref) async => _case),
          ],
        ),
      ),
      find.byKey(const Key('repoll-save')),
    );
  });

  testWidgets('How it turned out: Done', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () =>
          tester.pumpWidget(_app(ResolutionCheckInScreen(caseId: _case.id))),
      primaryAction: find.byKey(const Key('resolution-done')),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(_app(ResolutionCheckInScreen(caseId: _case.id))),
      find.byKey(const Key('resolution-done')),
    );
  });

  testWidgets('Group vote, create: Start voting', (tester) async {
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(_app(const PartyCreateScreen())),
      primaryAction: find.text('Start voting'),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(_app(const PartyCreateScreen())),
      find.text('Start voting'),
    );
  });

  testWidgets('Group vote, ballot: Submit vote', (tester) async {
    final repo = FakePartyRepository();
    final party = await repo.createParty(
      title: 'Where do we go for the long weekend?',
      options: const [
        PartyOption(id: 'a', label: 'The lake cabin'),
        PartyOption(id: 'b', label: 'Grandparents in town'),
      ],
      votingMethod: VotingMethod.approval,
    );
    await runPrimaryActionSweep(
      tester,
      pumpScreen: () => tester.pumpWidget(
        _app(
          PartyVoteScreen(partyId: party.id),
          overrides: [
            partyRepositoryProvider.overrideWithValue(repo),
            partySyncServiceProvider.overrideWithValue(
              RecordingSyncService(repo),
            ),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository('m-me'),
            ),
          ],
        ),
      ),
      primaryAction: find.text('Submit vote'),
    );
    await _expectWholeLabel(
      tester,
      () => tester.pumpWidget(
        _app(
          PartyVoteScreen(partyId: party.id),
          overrides: [
            partyRepositoryProvider.overrideWithValue(repo),
            partySyncServiceProvider.overrideWithValue(
              RecordingSyncService(repo),
            ),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository('m-me'),
            ),
          ],
        ),
      ),
      find.text('Submit vote'),
    );
  });
}
