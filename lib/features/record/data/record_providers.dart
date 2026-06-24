import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../case/data/case_providers.dart';
import '../../case/domain/entities/case.dart';
import '../../case/domain/entities/poll.dart';
import '../../reveal/data/resolution_providers.dart';
import '../domain/entities/calibration_report.dart';
import '../domain/entities/clarity_score.dart';
import '../domain/entities/insight_card.dart';
import '../domain/entities/personal_base_rates.dart';
import '../domain/usecases/compute_calibration_report.dart';
import '../domain/usecases/compute_clarity_score.dart';
import '../domain/usecases/compute_insight_cards.dart';
import '../domain/usecases/compute_personal_base_rates.dart';

/// Zip scored resolutions against each case's poll history. Shared between
/// the insight-cards and calibration-report providers since they consume
/// the same shape.
Future<List<ClosedCaseRecord>> _buildClosedCaseRecords(Ref ref) async {
  final resolutions =
      await ref.watch(resolutionRepositoryProvider).scoredResolutions();
  final caseRepo = ref.watch(caseRepositoryProvider);
  final pollRepo = ref.watch(pollRepositoryProvider);

  final records = await Future.wait(resolutions.map((r) async {
    final fetched = await Future.wait([
      caseRepo.getById(r.caseId),
      pollRepo.getByCaseId(r.caseId),
    ]);
    final case_ = fetched[0] as Case?;
    final polls = fetched[1] as List<Poll>;
    if (case_ == null) return null;
    return ClosedCaseRecord(
      case_: case_,
      polls: polls,
      satisfactionScore: r.satisfactionScore,
    );
  }));
  return records.whereType<ClosedCaseRecord>().toList();
}

final clarityScoreProvider = FutureProvider<ClarityScore>((ref) async {
  final resolutions =
      await ref.watch(resolutionRepositoryProvider).scoredResolutions();
  final scores = resolutions.map((r) => r.satisfactionScore).toList();
  return const ComputeClarityScore().call(scores);
});

final insightCardsProvider = FutureProvider<List<InsightCard>>((ref) async {
  return const ComputeInsightCards().call(await _buildClosedCaseRecords(ref));
});

final closedCasesProvider = FutureProvider<List<Case>>((ref) async {
  return ref.watch(caseRepositoryProvider).getClosed();
});

final calibrationReportProvider =
    FutureProvider<CalibrationReport>((ref) async {
  return const ComputeCalibrationReport()
      .call(await _buildClosedCaseRecords(ref));
});

/// Your own decision base rates mined from history (the "second brain") —
/// glad-rate by category and by how confident you felt, plus an overconfidence
/// signal. Same record source as the calibration report.
final personalBaseRatesProvider =
    FutureProvider<PersonalBaseRates>((ref) async {
  return const ComputePersonalBaseRates()
      .call(await _buildClosedCaseRecords(ref));
});
