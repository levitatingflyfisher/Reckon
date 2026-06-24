import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/case/presentation/case_detail_screen.dart';
import '../features/case/presentation/case_summary_screen.dart';
import '../features/case/presentation/home_screen.dart';
import '../features/case/presentation/intake_screen.dart';
import '../features/case/presentation/repoll_screen.dart';
import '../features/glossary/presentation/glossary_detail_screen.dart';
import '../features/glossary/presentation/glossary_screen.dart';
import '../features/onboarding/presentation/auth_tier_screen.dart';
import '../features/onboarding/presentation/first_case_prompt_screen.dart';
import '../features/onboarding/presentation/model_onboarding_screen.dart';
import '../features/predictions/presentation/model_scorecard_screen.dart';
import '../features/outside_view/presentation/outside_view_screen.dart';
import '../features/outside_view/presentation/stratification_screen.dart';
import '../features/party/presentation/party_create_screen.dart';
import '../features/party/presentation/party_join_screen.dart';
import '../features/party/presentation/party_result_screen.dart';
import '../features/party/presentation/party_vote_screen.dart';
import '../features/record/presentation/record_screen.dart';
import '../features/record/presentation/settings_screen.dart';
import '../features/reveal/presentation/resolution_checkin_screen.dart';
import '../features/reveal/presentation/resolution_date_screen.dart';
import '../features/reveal/presentation/reveal_screen.dart';
import '../core/auth/auth_providers.dart';
import 'app_shell.dart';

/// The router is constructed once per session. The onboarding flag is read
/// (not watched) so subsequent invalidations of [onboardingCompleteProvider]
/// do not tear down navigation state. Callers must wait for that provider to
/// have a concrete value (see `_Bootstrap` in `main.dart`) before building
/// the app that consumes this provider.
final routerProvider = Provider<GoRouter>((ref) {
  final skipOnboarding =
      ref.read(onboardingCompleteProvider).valueOrNull == true;
  return GoRouter(
    initialLocation: skipOnboarding ? '/' : '/onboarding/auth',
    routes: [
      GoRoute(
        path: '/onboarding/auth',
        builder: (_, __) => const AuthTierScreen(),
      ),
      GoRoute(
        path: '/onboarding/model',
        builder: (_, __) => const ModelOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/first-case',
        builder: (_, __) => const FirstCasePromptScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/record', builder: (_, __) => const RecordScreen()),
          GoRoute(
              path: '/glossary', builder: (_, __) => const GlossaryScreen()),
          GoRoute(
            path: '/glossary/:id',
            builder: (_, state) =>
                GlossaryDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/intake',
        builder: (_, __) => const IntakeScreen(),
      ),
      GoRoute(
        path: '/case-summary',
        builder: (_, state) =>
            CaseSummaryScreen(draft: state.extra! as CaseDraft),
      ),
      GoRoute(
        path: '/stratification',
        builder: (_, state) =>
            StratificationScreen(caseId: state.extra! as String),
      ),
      GoRoute(
        path: '/outside-view/:caseId',
        builder: (_, state) =>
            OutsideViewScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/case/:caseId',
        builder: (_, state) =>
            CaseDetailScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/repoll/:caseId',
        builder: (_, state) =>
            RepollScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/reveal/:caseId',
        builder: (_, state) =>
            RevealScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/resolution-date/:caseId',
        builder: (_, state) =>
            ResolutionDateScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/resolution-checkin/:caseId',
        builder: (_, state) =>
            ResolutionCheckInScreen(caseId: state.pathParameters['caseId']!),
      ),
      GoRoute(
        path: '/model-scorecard',
        builder: (_, __) => const ModelScorecardScreen(),
      ),
      GoRoute(
        path: '/party/create',
        builder: (_, __) => const PartyCreateScreen(),
      ),
      GoRoute(
        path: '/party/join',
        builder: (_, __) => const PartyJoinScreen(),
      ),
      GoRoute(
        path: '/party/:id/vote',
        builder: (_, state) =>
            PartyVoteScreen(partyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/party/:id/result',
        builder: (_, state) =>
            PartyResultScreen(partyId: state.pathParameters['id']!),
      ),
    ],
  );
});
