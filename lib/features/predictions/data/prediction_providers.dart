import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/repositories/prediction_repository.dart';
import 'prediction_repository_impl.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(ref.watch(appDatabaseProvider));
});

final modelScorecardProvider =
    FutureProvider<List<ModelScorecardEntry>>((ref) {
  return ref.watch(predictionRepositoryProvider).scorecard();
});
