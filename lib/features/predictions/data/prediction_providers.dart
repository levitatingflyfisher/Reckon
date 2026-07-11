import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/entities/model_prediction.dart';
import '../domain/repositories/prediction_repository.dart';
import 'prediction_repository_impl.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(ref.watch(appDatabaseProvider));
});

final modelScorecardProvider =
    FutureProvider<List<ModelScorecardEntry>>((ref) {
  return ref.watch(predictionRepositoryProvider).scorecard();
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
