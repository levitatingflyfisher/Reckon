import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../record/data/record_providers.dart';
import '../domain/entities/forecaster_weights.dart';
import '../domain/entities/model_prediction.dart';
import '../domain/repositories/prediction_repository.dart';
import '../domain/usecases/compute_forecaster_weights.dart';
import 'prediction_repository_impl.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// The deference map for the /forecasters screen. Watches the shared
/// closed-case records, so invalidating closedCaseRecordsProvider (the
/// check-in choke point) recomputes this too; unscored predictions cannot
/// change it, so duel runs need no extra invalidation.
final forecasterWeightsProvider =
    FutureProvider<ForecasterWeights>((ref) async {
  final records = await ref.watch(closedCaseRecordsProvider.future);
  final repo = ref.watch(predictionRepositoryProvider);
  final perCase =
      await Future.wait(records.map((r) => repo.forCase(r.case_.id)));
  return const ComputeForecasterWeights()(
    predictions: [for (final list in perCase) ...list],
    records: records,
  );
});

/// The sealed duel forecasts on a case, oldest first. While the case is open
/// the UI may surface only their COUNT (R1: nothing shown during elicitation
/// may depend on model forecasts); content is for the reveal screen.
/// Invalidate after a duel run.
final duelForecastsForCaseProvider =
    FutureProvider.family<List<ModelPrediction>, String>((ref, caseId) async {
  final all = await ref.watch(predictionRepositoryProvider).forCase(caseId);
  return [
    for (final p in all)
      if (p.kind == PredictionKind.duelForecast) p,
  ];
});
