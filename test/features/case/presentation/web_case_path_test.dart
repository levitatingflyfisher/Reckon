import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/core/llm/llm_providers.dart';
import 'package:reckon/core/llm/model_download_service.dart';
import 'package:reckon/core/llm/model_spec.dart';
import 'package:reckon/core/notifications/local_notification_service.dart';
import 'package:reckon/core/notifications/notification_providers.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/repositories/case_repository.dart';
import 'package:reckon/features/case/presentation/case_summary_screen.dart';
import 'package:reckon/features/case/presentation/intake_screen.dart';
import 'package:reckon/features/outside_view/presentation/outside_view_screen.dart';

/// Audit finding 1 (the rest of it): on a build with no on-device model
/// runtime (the web PWA), New decision led only to an apology. The
/// six-field "Does this look right?" form never needed a model, so a
/// decision can be written down by hand; the steps that do need the model
/// (the outside view) say so plainly instead of failing.
class _Cases implements CaseRepository {
  final inserted = <Case>[];
  @override
  Future<void> insert(Case c) async => inserted.add(c);
  @override
  Future<Case?> getById(String id) async =>
      inserted.where((c) => c.id == id).firstOrNull;
  @override
  Future<List<Case>> getByStatus(CaseStatus s) async =>
      inserted.where((c) => c.status == s).toList();
  @override
  Future<List<Case>> getClosed() async => const [];
  @override
  Future<void> updateStatus(String id, CaseStatus s) async {}
  @override
  Stream<List<Case>> watchAll() => Stream.value(inserted);
  @override
  Stream<List<Case>> watchActive() => Stream.value(inserted);
  @override
  Future<void> markDecided(String id) async {}
}

class _NothingDownloaded extends ModelDownloadService {
  @override
  Future<bool> isDownloaded(ReckonModelSpec spec) async => false;
}

/// A browser: nothing can be scheduled, and nothing asks.
class _NoReminders extends LocalNotificationService {
  var asked = false;
  @override
  bool get canScheduleReminders => false;
  @override
  Future<bool> requestPermissions() async {
    asked = true;
    return false;
  }
}

void main() {
  late _Cases cases;
  late _NoReminders notif;

  Widget app({bool runtime = false}) {
    final router = GoRouter(
      initialLocation: '/intake',
      routes: [
        GoRoute(path: '/intake', builder: (_, __) => const IntakeScreen()),
        GoRoute(
          path: '/case-summary',
          builder: (_, s) => CaseSummaryScreen(draft: s.extra! as CaseDraft),
        ),
        GoRoute(
          path: '/case/:id',
          builder: (_, s) =>
              Scaffold(body: Text('DECISION ${s.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/stratification',
          builder: (_, __) => const Scaffold(body: Text('STRATIFICATION')),
        ),
        GoRoute(
            path: '/', builder: (_, __) => const Scaffold(body: Text('HOME'))),
      ],
    );
    return ProviderScope(
      overrides: [
        onDeviceModelSupportedProvider.overrideWithValue(runtime),
        selectedModelIdProvider.overrideWith((ref) async => null),
        modelDownloadServiceProvider.overrideWithValue(_NothingDownloaded()),
        caseRepositoryProvider.overrideWithValue(cases),
        localNotificationServiceProvider.overrideWithValue(notif),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    cases = _Cases();
    notif = _NoReminders();
  });

  testWidgets('with no model, New decision explains itself and still lets '
      'you write a decision down', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Plain explanation of what works here and what needs the phone app.
    expect(find.textContaining("can’t run"), findsOneWidget);
    expect(find.textContaining('Android app'), findsOneWidget);
    expect(find.textContaining('coming to the web'), findsNothing);

    await tester.tap(find.text('Write it down myself'));
    await tester.pumpAndSettle();
    expect(find.byType(CaseSummaryScreen), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Repaint the kitchen this spring?');
    await tester.enterText(fields.at(1), 'Paint it in April');
    await tester.enterText(fields.at(2), 'Wait until autumn');
    await tester.pump();

    final save = find.byKey(const Key('case-summary-save'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(cases.inserted, hasLength(1));
    // Straight to the decision: the outside-view questions only feed the
    // model, and a browser has no reminders to be told are off.
    expect(find.text('DECISION ${cases.inserted.single.id}'), findsOneWidget);
    expect(find.text('STRATIFICATION'), findsNothing);
    expect(find.text('Reminders are off'), findsNothing);
    expect(notif.asked, isFalse);
  });

  testWidgets('with no model, the outside view says what it needs instead of '
      'failing', (tester) async {
    cases.inserted.add(Case(
      id: 'c1',
      createdAt: DateTime(2026, 9, 1),
      deadline: null,
      status: CaseStatus.open,
      question: 'Repaint the kitchen this spring?',
      optionA: 'April',
      optionB: 'Autumn',
      statedCriteria: const [],
      stakes: Stakes.low,
      regretHorizon: RegretHorizon.months,
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        onDeviceModelSupportedProvider.overrideWithValue(false),
        caseRepositoryProvider.overrideWithValue(cases),
      ],
      child: const MaterialApp(home: OutsideViewScreen(caseId: 'c1')),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('on-device model'), findsOneWidget);
    expect(find.textContaining("Couldn’t"), findsNothing);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('on a phone with no model downloaded, a decision written down '
      'by hand also goes straight to the decision', (tester) async {
    await tester.pumpWidget(app(runtime: true));
    await tester.pumpAndSettle();

    expect(find.text('Open Settings'), findsOneWidget);
    await tester.tap(find.text('Write it down myself'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Repaint the kitchen this spring?');
    await tester.enterText(fields.at(1), 'Paint it in April');
    await tester.enterText(fields.at(2), 'Wait until autumn');
    await tester.pump();
    final save = find.byKey(const Key('case-summary-save'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // No model on disk, so the outside-view questions would lead to an
    // outside view that can't be written.
    expect(find.text('STRATIFICATION'), findsNothing);
    expect(find.text('DECISION ${cases.inserted.single.id}'), findsOneWidget);
  });

  testWidgets('with the runtime but no model on disk, the outside view says '
      'what it needs', (tester) async {
    cases.inserted.add(Case(
      id: 'c2',
      createdAt: DateTime(2026, 9, 1),
      deadline: null,
      status: CaseStatus.open,
      question: 'Repaint the kitchen this spring?',
      optionA: 'April',
      optionB: 'Autumn',
      statedCriteria: const [],
      stakes: Stakes.low,
      regretHorizon: RegretHorizon.months,
    ));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        onDeviceModelSupportedProvider.overrideWithValue(true),
        selectedModelIdProvider.overrideWith((ref) async => null),
        modelDownloadServiceProvider.overrideWithValue(_NothingDownloaded()),
        caseRepositoryProvider.overrideWithValue(cases),
      ],
      child: const MaterialApp(home: OutsideViewScreen(caseId: 'c2')),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Download one in Settings'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
}
