import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/llm/anthropic_key_store.dart';
import '../../../core/llm/forecaster_llm.dart';
import '../../../core/llm/llm_providers.dart';
import '../../../core/llm/model_spec.dart';
import '../../predictions/data/prediction_providers.dart';
import '../domain/entities/forecaster.dart';
import '../domain/repositories/forecaster_repository.dart';
import '../domain/usecases/run_duel.dart';
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

/// Enabled forecasters that can run HERE, NOW — this gates the "Run the
/// duel" button. Personas and the local model need the resident on-device
/// model (never on web, and only once downloaded); BYOK needs a stored key;
/// openaiCompat needs a base URL; bounty bots are import-only.
///
/// Invalidate after roster edits, key changes, and model downloads.
final runnableForecastersProvider =
    FutureProvider<List<Forecaster>>((ref) async {
  final enabled = await ref.watch(enabledForecastersProvider.future);

  // Resident-model availability, resolved once for the whole roster.
  // Await the persisted selection FIRST: reading the sync spec provider too
  // early falls back to the default spec (same trap as intake's gate).
  var residentReady = false;
  if (!kIsWeb) {
    final selectedId = await ref.watch(selectedModelIdProvider.future);
    final spec = ReckonModelSpec.byId(selectedId);
    residentReady =
        await ref.watch(modelDownloadServiceProvider).isDownloaded(spec);
  }
  final hasKey = await ref.watch(hasAnthropicKeyProvider.future);

  return [
    for (final f in enabled)
      if (switch (f.kind) {
        ForecasterKind.persona || ForecasterKind.localModel => residentReady,
        ForecasterKind.anthropicByok => hasKey,
        ForecasterKind.openaiCompat =>
          (f.config['base_url'] as String?)?.isNotEmpty == true,
        ForecasterKind.bountyBot => false,
      })
        f,
  ];
});

/// The duel runner, wired to the per-forecaster backend resolver. Callers
/// invalidate `duelForecastsForCaseProvider(caseId)` after a run so the
/// sealed count refreshes.
final runDuelProvider = Provider<RunDuel>((ref) {
  return RunDuel(
    ref.watch(forecasterRepositoryProvider),
    ref.watch(predictionRepositoryProvider),
    (forecaster) => llmServiceForForecaster(ref, forecaster),
  );
});
