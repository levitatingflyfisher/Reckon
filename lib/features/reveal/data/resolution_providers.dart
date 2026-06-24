import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import 'resolution_repository.dart';
import 'resolution_repository_impl.dart';

final resolutionRepositoryProvider = Provider<ResolutionRepository>((ref) {
  return ResolutionRepositoryImpl(
    ref.watch(appDatabaseProvider),
    predictions: ref.watch(predictionRepositoryProvider),
  );
});
