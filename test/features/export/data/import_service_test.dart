import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';
import 'package:reckon/features/export/data/import_service.dart';
import 'package:reckon/features/export/domain/entities/export_bundle.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';

/// [ImportService] rehydrates [AppDatabase] from an [ExportBundle] — the
/// mirror image of [ExportService.gather()]. Destructive: wipes every table
/// this app owns (plus `model_predictions`, which has an enforced FK to
/// `cases` but is NOT part of the backup payload) and re-inserts inside one
/// transaction, FK-safe (SANCTUARY-BRIEF §2.5, §4.W2).
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final now = DateTime.utc(2026, 6, 1);

  ExportBundle bundleWith({
    List<CaseExport> cases = const [],
    UserProfile profile = const UserProfile(),
  }) =>
      ExportBundle(generatedAt: now, profile: profile, cases: cases);

  test('restoreAll writes a case, poll, outside view, and resolution',
      () async {
    final bundle = bundleWith(cases: [
      CaseExport(
        case_: Case(
          id: 'c1',
          createdAt: now,
          deadline: null,
          status: CaseStatus.decided,
          question: 'Marry now or wait?',
          optionA: 'Wait',
          optionB: 'Marry',
          statedCriteria: const [Criterion(label: 'trust', weight: 0.5)],
          stakes: Stakes.high,
          regretHorizon: RegretHorizon.years,
          category: 'relationship',
          communityVisible: true,
        ),
        polls: [
          Poll(
            id: 'p1',
            caseId: 'c1',
            createdAt: now,
            pollNumber: 1,
            lean: 60,
            confidence: Confidence.high,
            rationale: 'gut says marry',
            revealed: true,
          ),
        ],
        outsideView: OutsideView(
          id: 'ov1',
          caseId: 'c1',
          generatedAt: now,
          baseRateSummary: 'summary',
          referenceClassUsed: 'relationship / marriage',
          uncertaintyLevel: 'low',
          stratificationFactors: const {'age': 30},
          llmMode: 'private',
          modelVersion: 'gemma-3-1b-it',
          citations: const [
            Citation(author: 'A', title: 'A Study', url: 'https://x'),
          ],
        ),
        resolution: ResolutionExport(
          decidedAt: now,
          chosenOption: 'Marry',
          resolutionCheckDate: now.add(const Duration(days: 30)),
          satisfactionScore: 8,
          reflection: 'glad',
        ),
      ),
    ], profile: const UserProfile(sesBracket: 'middle', religiosity: 'low'));

    await ImportService(db).restoreAll(bundle);

    final cases = await db.select(db.cases).get();
    expect(cases, hasLength(1));
    expect(cases.first.question, 'Marry now or wait?');
    expect(cases.first.communityVisible, isTrue);
    expect(cases.first.statedCriteria, hasLength(1));

    final polls = await db.select(db.polls).get();
    expect(polls, hasLength(1));
    expect(polls.first.caseId, 'c1');
    expect(polls.first.revealed, isTrue);

    final views = await db.select(db.outsideViews).get();
    expect(views, hasLength(1));
    expect(views.first.citations, hasLength(1));

    final resolutions = await db.select(db.resolutions).get();
    expect(resolutions, hasLength(1));
    expect(resolutions.first.caseId, 'c1');
    expect(resolutions.first.satisfactionScore, 8);

    final profile = await (db.select(db.userProfile)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    expect(profile.sesBracket, 'middle');
  });

  test('restoreAll wipes existing data before inserting', () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'old',
          createdAt: now,
          status: 'open',
          question: 'old question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: 'low',
          regretHorizon: 'weeks',
        ));

    final bundle = bundleWith(cases: [
      CaseExport(
        case_: Case(
          id: 'new',
          createdAt: now,
          deadline: null,
          status: CaseStatus.open,
          question: 'new question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: Stakes.low,
          regretHorizon: RegretHorizon.weeks,
        ),
        polls: const [],
      ),
    ]);

    await ImportService(db).restoreAll(bundle);

    final cases = await db.select(db.cases).get();
    expect(cases, hasLength(1));
    expect(cases.first.id, 'new');
  });

  test('restoreAll on an empty bundle wipes the database clean', () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'old',
          createdAt: now,
          status: 'open',
          question: 'old question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: 'low',
          regretHorizon: 'weeks',
        ));

    await ImportService(db).restoreAll(bundleWith());

    expect(await db.select(db.cases).get(), isEmpty);
  });

  // The FK landmine: model_predictions.caseId references Cases with NO
  // cascade (drift default = SQLite "NO ACTION"). It is not part of
  // ExportBundle/the backup payload, so a naive wipe of only
  // {resolutions, outsideViews, polls, cases} throws
  // SQLITE_CONSTRAINT_FOREIGNKEY the moment a user who has ever run the duel
  // (which logs predictions) tries to restore. A fresh-DB round-trip test
  // would NOT catch this — it must be seeded explicitly.
  test('restoreAll succeeds even when model_predictions references a '
      'to-be-wiped case (FK-safe order)', () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'c-old',
          createdAt: now,
          status: 'open',
          question: 'old question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: 'low',
          regretHorizon: 'weeks',
        ));
    await db.into(db.modelPredictions).insert(ModelPredictionsCompanion.insert(
          id: 'mp1',
          caseId: 'c-old',
          modelVersion: 'gemma-3-1b-it',
          kind: 'outside_view',
          predictedAt: now,
          payload: const {'foo': 'bar'},
        ));

    final bundle = bundleWith(cases: [
      CaseExport(
        case_: Case(
          id: 'c-new',
          createdAt: now,
          deadline: null,
          status: CaseStatus.open,
          question: 'new question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: Stakes.low,
          regretHorizon: RegretHorizon.weeks,
        ),
        polls: const [],
      ),
    ]);

    await ImportService(db).restoreAll(bundle);

    final cases = await db.select(db.cases).get();
    expect(cases, hasLength(1));
    expect(cases.first.id, 'c-new');

    // model_predictions is duel-scoped history over the wiped case; it is
    // not part of the backup payload, so it is cleared rather than orphaned.
    final predictions = await db.select(db.modelPredictions).get();
    expect(predictions, isEmpty);
  });

  test('restoreAll rolls back entirely on failure (single transaction)',
      () async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'keep-me',
          createdAt: now,
          status: 'open',
          question: 'keep-me question',
          optionA: 'a',
          optionB: 'b',
          statedCriteria: const [],
          stakes: 'low',
          regretHorizon: 'weeks',
        ));

    // A poll with no matching case in the same bundle violates the FK on
    // insert — this must roll back the whole transaction, not leave a
    // half-wiped database.
    final bundle = ExportBundle(
      generatedAt: now,
      profile: const UserProfile(),
      cases: [
        CaseExport(
          case_: Case(
            id: 'c-new',
            createdAt: now,
            deadline: null,
            status: CaseStatus.open,
            question: 'new question',
            optionA: 'a',
            optionB: 'b',
            statedCriteria: const [],
            stakes: Stakes.low,
            regretHorizon: RegretHorizon.weeks,
          ),
          polls: [
            Poll(
              id: 'p-orphan',
              caseId: 'does-not-exist',
              createdAt: now,
              pollNumber: 1,
              lean: 0,
              confidence: Confidence.low,
            ),
          ],
        ),
      ],
    );

    await expectLater(ImportService(db).restoreAll(bundle), throwsException);

    // The original data must still be present — the failed restore rolled
    // back rather than leaving a wiped-but-not-reinserted database.
    final cases = await db.select(db.cases).get();
    expect(cases, hasLength(1));
    expect(cases.first.id, 'keep-me');
  });
}
