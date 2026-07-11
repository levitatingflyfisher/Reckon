import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../domain/entities/forecaster.dart';
import '../domain/repositories/forecaster_repository.dart';
import 'forecaster_repository_impl.dart';

final forecasterRepositoryProvider = Provider<ForecasterRepository>((ref) {
  return ForecasterRepositoryImpl(ref.watch(appDatabaseProvider));
});

/// The full roster (lazily seeded with the default personas on first read).
/// Invalidate after any roster mutation.
final forecastersProvider = FutureProvider<List<Forecaster>>((ref) {
  return ref.watch(forecasterRepositoryProvider).all();
});

/// Only the forecasters that will actually run in the next duel.
final enabledForecastersProvider = FutureProvider<List<Forecaster>>((ref) {
  return ref.watch(forecasterRepositoryProvider).enabled();
});
