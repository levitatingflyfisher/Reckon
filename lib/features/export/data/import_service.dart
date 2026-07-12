import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../case/domain/entities/case.dart';
import '../../case/domain/entities/poll.dart';
import '../../outside_view/domain/entities/outside_view.dart';
import '../domain/entities/export_bundle.dart';

/// Rehydrates [AppDatabase] from an [ExportBundle] — the mirror image of
/// [ExportService.gather()]. Used only by the encrypted-backup restore path
/// (`lib/features/sanctuary_backup/data/backup_serializer.dart`).
///
/// **Destructive.** Wipes every case-scoped table this app owns and
/// re-inserts inside ONE transaction, in FK-safe order (children before
/// parents on wipe, parents before children on insert) — SANCTUARY-BRIEF
/// §2.5. A failure anywhere rolls the whole transaction back; there is no
/// partial restore.
///
/// `model_predictions` (the forecaster-duel prediction/track-record history)
/// **is** part of [ExportBundle] (W4 F1 — the confirm-dialog copy and
/// docs/privacy-model.md both promise restore "replaces" this data, so it
/// must genuinely round-trip, not be silently destroyed). It is still wiped
/// before the parent `cases` rows are wiped, same as every other
/// case-scoped table — its `caseId` column has an enforced foreign key to
/// `cases` with no cascade (`model_predictions_table.dart`), so leaving it
/// out of the wipe would throw `SQLITE_CONSTRAINT_FOREIGNKEY`. Rows for a
/// case that is present in the bundle are re-inserted right after that case;
/// rows for a case that has been dropped from the bundle (e.g. the backup
/// predates a case created since) have nothing to attach to and are left
/// cleared, matching the promised replace semantics.
///
/// Party sync (`parties`, `party_ballots`, `groups`, `group_members`,
/// `forecasters`) is untouched: none of those tables reference `cases`, they
/// are not part of the backup payload, and this writer never opens them
/// (SANCTUARY-BRIEF §4.W2 — "party sync untouched").
class ImportService {
  ImportService(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();
  final AppDatabase _db;
  final Uuid _uuid;

  Future<void> restoreAll(ExportBundle bundle) async {
    await _db.transaction(() async {
      // Wipe children before parents (PRAGMA foreign_keys = ON).
      await _db.delete(_db.resolutions).go();
      await _db.delete(_db.modelPredictions).go();
      await _db.delete(_db.outsideViews).go();
      await _db.delete(_db.polls).go();
      await _db.delete(_db.cases).go();

      // Re-insert parents before children.
      for (final entry in bundle.cases) {
        await _db.into(_db.cases).insert(_caseCompanion(entry.case_));

        for (final poll in entry.polls) {
          await _db.into(_db.polls).insert(_pollCompanion(poll));
        }

        final outsideView = entry.outsideView;
        if (outsideView != null) {
          await _db
              .into(_db.outsideViews)
              .insert(_outsideViewCompanion(outsideView));
        }

        final resolution = entry.resolution;
        if (resolution != null) {
          // ResolutionExport carries no id/caseId of its own (nested under
          // CaseExport, one-per-case) — mint a fresh row id on restore.
          await _db.into(_db.resolutions).insert(
                ResolutionsCompanion.insert(
                  id: _uuid.v4(),
                  caseId: entry.case_.id,
                  decidedAt: resolution.decidedAt,
                  chosenOption: resolution.chosenOption,
                  resolutionCheckDate: resolution.resolutionCheckDate,
                  satisfactionScore: Value(resolution.satisfactionScore),
                  reflection: Value(resolution.reflection),
                ),
              );
        }

        for (final prediction in entry.predictions) {
          await _db.into(_db.modelPredictions).insert(
                ModelPredictionsCompanion.insert(
                  id: prediction.id,
                  caseId: entry.case_.id,
                  modelVersion: prediction.modelVersion,
                  kind: prediction.kind.name,
                  predictedAt: prediction.predictedAt,
                  payload: prediction.payload,
                  score: Value(prediction.score),
                  scoredAt: Value(prediction.scoredAt),
                ),
              );
        }
      }

      await _db.into(_db.userProfile).insertOnConflictUpdate(
            UserProfileCompanion.insert(
              id: const Value(1),
              sesBracket: Value(bundle.profile.sesBracket),
              religiosity: Value(bundle.profile.religiosity),
              relationshipStatus: Value(bundle.profile.relationshipStatus),
            ),
          );
    });
  }

  CasesCompanion _caseCompanion(Case c) => CasesCompanion.insert(
        id: c.id,
        createdAt: c.createdAt,
        deadline: Value(c.deadline),
        status: c.status.name,
        question: c.question,
        optionA: c.optionA,
        optionB: c.optionB,
        statedCriteria: c.statedCriteria.map((crit) => crit.toJson()).toList(),
        stakes: c.stakes.name,
        regretHorizon: c.regretHorizon.name,
        category: Value(c.category),
        communityVisible: Value(c.communityVisible),
      );

  PollsCompanion _pollCompanion(Poll p) => PollsCompanion.insert(
        id: p.id,
        caseId: p.caseId,
        createdAt: p.createdAt,
        pollNumber: p.pollNumber,
        lean: p.lean,
        rationale: Value(p.rationale),
        confidence: p.confidence.name,
        revealed: Value(p.revealed),
      );

  OutsideViewsCompanion _outsideViewCompanion(OutsideView v) =>
      OutsideViewsCompanion.insert(
        id: v.id,
        caseId: v.caseId,
        generatedAt: v.generatedAt,
        baseRateSummary: v.baseRateSummary,
        referenceClassUsed: v.referenceClassUsed,
        uncertaintyLevel: v.uncertaintyLevel,
        stratificationFactors: v.stratificationFactors,
        llmMode: v.llmMode,
        modelVersion: v.modelVersion,
        citations: Value(v.citations.map((c) => c.toJson()).toList()),
      );
}
