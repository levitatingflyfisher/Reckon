import 'package:uuid/uuid.dart';

import '../../../../core/llm/llm_service.dart';
import '../../../case/domain/entities/case.dart';
import '../../../predictions/domain/entities/model_prediction.dart';
import '../../../predictions/domain/repositories/prediction_repository.dart';
import '../entities/forecaster.dart';
import '../repositories/forecaster_repository.dart';

/// Maps a forecaster onto the backend it runs on, or `null` when it cannot
/// run here (see `llmServiceForForecaster` in core/llm, the production
/// implementation).
typedef ForecasterServiceResolver = Future<LlmService?> Function(Forecaster);

/// What a duel did. `ran + skipped + failed` covers every enabled forecaster.
class DuelResult {
  const DuelResult({
    required this.ran,
    required this.skipped,
    required this.failed,
  });

  /// New sealed forecasts logged this run.
  final int ran;

  /// Sat out: already forecast on this case (idempotence) or not runnable
  /// here (bounty bots, missing key/model).
  final int skipped;

  /// Model errors and sentinel outputs — nothing was logged for these; the
  /// user can simply run the duel again.
  final int failed;
}

/// Runs the duel on one open case: every enabled, runnable forecaster gives
/// its lean exactly once, logged as a sealed `duelForecast` prediction.
///
/// Honesty invariants upheld here:
///  * R1 — forecasts are logged but stay SEALED: nothing in this usecase (or
///    the open-case UI) exposes lean/rationale before the user's own reveal.
///  * Sentinel guard — a `CommunitySeed` with an empty rationale is a model
///    hiccup, not a forecast; logging it would pollute every forecaster's
///    track record with 50/50 noise, so it is counted as failed and dropped.
///  * Idempotence — one forecast per (case, forecaster), keyed on the
///    payload's forecasterId; re-running the duel never duplicates rows.
///
/// Forecasters run sequentially by design: on-device persona forecasters
/// share ONE resident flutter_gemma model, and concurrent chats over it are
/// not safe (the plugin holds a single active session).
class RunDuel {
  RunDuel(
    this._forecasters,
    this._predictions,
    this._resolve, {
    Uuid? uuid,
    DateTime Function()? now,
  })  : _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now;

  final ForecasterRepository _forecasters;
  final PredictionRepository _predictions;
  final ForecasterServiceResolver _resolve;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<DuelResult> call(Case case_) async {
    final roster = await _forecasters.enabled();
    final alreadyForecast = (await _predictions.forCase(case_.id))
        .where((p) => p.kind == PredictionKind.duelForecast)
        .map((p) => p.payload['forecasterId'])
        .whereType<String>()
        .toSet();

    var ran = 0, skipped = 0, failed = 0;
    for (final forecaster in roster) {
      if (alreadyForecast.contains(forecaster.id)) {
        skipped++;
        continue;
      }
      final service = await _resolve(forecaster);
      if (service == null) {
        skipped++;
        continue;
      }
      try {
        final seed = await service.generateCommunitySeed(
          case_,
          persona: forecaster.config['persona'] as String?,
          temperature:
              (forecaster.config['temperature'] as num?)?.toDouble(),
        );
        if (seed.rationale.trim().isEmpty) {
          failed++; // sentinel — never logged
          continue;
        }
        await _predictions.log(ModelPrediction(
          id: _uuid.v4(),
          caseId: case_.id,
          // '<backend-model>#<forecasterId>' so the scorecard can split the
          // same model running under different personas.
          modelVersion: '${service.modelVersion}#${forecaster.id}',
          kind: PredictionKind.duelForecast,
          predictedAt: _now(),
          payload: {
            'lean': seed.lean,
            'rationale': seed.rationale,
            'forecasterId': forecaster.id,
            'forecasterName': forecaster.displayName,
          },
        ));
        ran++;
      } catch (_) {
        // Backends promise sentinel-not-throw, but a duel must survive a
        // rogue one: fail this forecaster, keep dueling.
        failed++;
      }
    }
    return DuelResult(ran: ran, skipped: skipped, failed: failed);
  }
}
