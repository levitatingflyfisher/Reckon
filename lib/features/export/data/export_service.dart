import '../../../core/database/app_database.dart';
import '../../case/domain/entities/case.dart';
import '../../case/domain/entities/criterion.dart';
import '../../case/domain/entities/poll.dart';
import '../../outside_view/domain/entities/citation.dart';
import '../../outside_view/domain/entities/outside_view.dart';
import '../../outside_view/domain/entities/user_profile.dart';
import '../domain/entities/export_bundle.dart';

/// Gathers every user-owned row from the database into an [ExportBundle].
/// Reference-class seed content is excluded — it is bundled with the app,
/// not user data.
class ExportService {
  ExportService(this._db);
  final AppDatabase _db;

  Future<ExportBundle> gather({DateTime? now}) async {
    final cases = await _db.select(_db.cases).get();
    final polls = await _db.select(_db.polls).get();
    final outsideViews = await _db.select(_db.outsideViews).get();
    final resolutions = await _db.select(_db.resolutions).get();
    final profileRow = await (_db.select(_db.userProfile)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();

    final pollsByCase = <String, List<Poll>>{};
    for (final row in polls) {
      pollsByCase.putIfAbsent(row.caseId, () => []).add(_toPoll(row));
    }
    for (final list in pollsByCase.values) {
      list.sort((a, b) => a.pollNumber.compareTo(b.pollNumber));
    }

    final outsideByCase = {
      for (final row in outsideViews) row.caseId: _toOutsideView(row),
    };
    final resolutionByCase = {
      for (final row in resolutions) row.caseId: _toResolution(row),
    };

    final sortedCases = [...cases]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ExportBundle(
      generatedAt: now ?? DateTime.now(),
      profile: _toProfile(profileRow),
      cases: sortedCases
          .map((row) => CaseExport(
                case_: _toCase(row),
                polls: pollsByCase[row.id] ?? const [],
                outsideView: outsideByCase[row.id],
                resolution: resolutionByCase[row.id],
              ))
          .toList(),
    );
  }

  Case _toCase(CaseRow row) => Case(
        id: row.id,
        createdAt: row.createdAt,
        deadline: row.deadline,
        status: CaseStatus.values.firstWhere(
          (e) => e.name == row.status,
          orElse: () => CaseStatus.open,
        ),
        question: row.question,
        optionA: row.optionA,
        optionB: row.optionB,
        statedCriteria: row.statedCriteria
            .map((raw) => Criterion.fromJson(raw as Map<String, dynamic>))
            .toList(),
        stakes: Stakes.values.firstWhere(
          (e) => e.name == row.stakes,
          orElse: () => Stakes.medium,
        ),
        regretHorizon: RegretHorizon.values.firstWhere(
          (e) => e.name == row.regretHorizon,
          orElse: () => RegretHorizon.months,
        ),
        category: row.category,
        communityVisible: row.communityVisible,
      );

  Poll _toPoll(PollRow row) => Poll(
        id: row.id,
        caseId: row.caseId,
        createdAt: row.createdAt,
        pollNumber: row.pollNumber,
        lean: row.lean,
        confidence: Confidence.values.firstWhere(
          (e) => e.name == row.confidence,
          orElse: () => Confidence.medium,
        ),
        rationale: row.rationale,
        revealed: row.revealed,
      );

  OutsideView _toOutsideView(OutsideViewRow row) => OutsideView(
        id: row.id,
        caseId: row.caseId,
        generatedAt: row.generatedAt,
        baseRateSummary: row.baseRateSummary,
        referenceClassUsed: row.referenceClassUsed,
        uncertaintyLevel: row.uncertaintyLevel,
        stratificationFactors: row.stratificationFactors,
        llmMode: row.llmMode,
        modelVersion: row.modelVersion,
        citations: Citation.listFromDynamic(row.citations),
      );

  ResolutionExport _toResolution(ResolutionRow row) => ResolutionExport(
        decidedAt: row.decidedAt,
        chosenOption: row.chosenOption,
        resolutionCheckDate: row.resolutionCheckDate,
        satisfactionScore: row.satisfactionScore,
        reflection: row.reflection,
      );

  UserProfile _toProfile(UserProfileRow? row) => UserProfile(
        sesBracket: row?.sesBracket,
        religiosity: row?.religiosity,
        relationshipStatus: row?.relationshipStatus,
      );
}
