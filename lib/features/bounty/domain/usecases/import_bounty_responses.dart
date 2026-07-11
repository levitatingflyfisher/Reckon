import 'package:uuid/uuid.dart';

import '../../../case/domain/entities/case.dart';
import '../../../forecasters/domain/entities/forecaster.dart';
import '../../../forecasters/domain/repositories/forecaster_repository.dart';
import '../../../predictions/domain/entities/model_prediction.dart';
import '../../../predictions/domain/repositories/prediction_repository.dart';
import '../bounty_codec.dart';

/// What one paste did. Rejected reasons are human-readable and name the bot
/// and the rule it tripped — never the forecast's content (the app keeps
/// imported forecasts sealed until the reveal, same as the duel's).
class BountyImportResult {
  const BountyImportResult({
    required this.imported,
    required this.duplicates,
    required this.rejected,
  });

  /// New sealed forecasts logged from this paste.
  final int imported;

  /// This bot already answered this case (idempotence) — re-pasting a file
  /// never inflates anyone's track record.
  final int duplicates;

  /// Responses that violated a rule, with the reason.
  final List<String> rejected;
}

/// Turns pasted BountyResponse JSON into sealed duel forecasts.
///
/// Each accepted response:
///  * joins the roster as a `bountyBot` forecaster (id `bounty:<bot.name>`)
///    — created only if absent, because the roster is the user's: a rename
///    or disable survives every future import;
///  * logs one `duelForecast` prediction whose payload carries
///    `{lean, rationale, forecasterId, forecasterName}` — exactly the duel's
///    shape, so imported bots render in the reveal table, stay sealed on the
///    open case, score at resolution under the same per-prediction alignment
///    rule, and earn weight on the deference map with zero extra plumbing.
///
/// Protocol rules enforced (reckonBounty spec v0.1):
///  * one response per bot per request — within a paste the latest
///    `created_at` wins (§3.2);
///  * a `request_id` naming a different request is rejected — a forecast
///    about another question must not enter this case's record;
///  * responses created after the case's deadline (the request's `reply_by`)
///    are excluded from scored comparison (§3.1).
class ImportBountyResponses {
  ImportBountyResponses(
    this._forecasters,
    this._predictions, {
    Uuid? uuid,
    DateTime Function()? now,
  })  : _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now;

  final ForecasterRepository _forecasters;
  final PredictionRepository _predictions;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Throws [FormatException] (with a precise message) when [rawJson] is not
  /// parseable at all; per-response rule violations land in
  /// [BountyImportResult.rejected] instead so one bad entry never blocks the
  /// rest of the paste.
  Future<BountyImportResult> call(Case case_, String rawJson) async {
    final parsed = BountyCodec.parseResponses(rawJson);

    // One response per bot: latest created_at wins; without timestamps the
    // last one in the paste does.
    final byBot = <String, ParsedBountyResponse>{};
    for (final r in parsed) {
      final prev = byBot[r.botName];
      if (prev == null ||
          r.createdAt == null ||
          prev.createdAt == null ||
          !r.createdAt!.isBefore(prev.createdAt!)) {
        byBot[r.botName] = r;
      }
    }

    final alreadyForecast = (await _predictions.forCase(case_.id))
        .where((p) => p.kind == PredictionKind.duelForecast)
        .map((p) => p.payload['forecasterId'])
        .whereType<String>()
        .toSet();
    final roster = {for (final f in await _forecasters.all()) f.id};

    var imported = 0, duplicates = 0;
    final rejected = <String>[];
    for (final r in byBot.values) {
      if (r.requestId != null && r.requestId != case_.id) {
        rejected.add('${r.botName}: answers a different request '
            '(${r.requestId}).');
        continue;
      }
      final deadline = case_.deadline;
      if (deadline != null &&
          r.createdAt != null &&
          r.createdAt!.isAfter(deadline)) {
        rejected.add('${r.botName}: answered after the reply-by deadline, '
            'so it sits out the scored comparison.');
        continue;
      }
      final int lean;
      try {
        lean = BountyCodec.leanFor(r,
            optionA: case_.optionA, optionB: case_.optionB);
      } on FormatException catch (e) {
        rejected.add(e.message);
        continue;
      }

      final forecasterId = 'bounty:${r.botName}';
      if (alreadyForecast.contains(forecasterId)) {
        duplicates++;
        continue;
      }
      if (!roster.contains(forecasterId)) {
        await _forecasters.upsert(Forecaster(
          id: forecasterId,
          displayName: r.botName,
          kind: ForecasterKind.bountyBot,
          config: {if (r.botModel != null) 'model': r.botModel},
          createdAt: _now(),
        ));
        roster.add(forecasterId);
      }
      await _predictions.log(ModelPrediction(
        id: _uuid.v4(),
        caseId: case_.id,
        // Same '<backend-model>#<forecasterId>' shape as the duel's rows.
        modelVersion: '${r.botModel ?? 'undisclosed'}#$forecasterId',
        kind: PredictionKind.duelForecast,
        predictedAt: r.createdAt ?? _now(),
        payload: {
          'lean': lean,
          'rationale': r.rationale,
          'forecasterId': forecasterId,
          'forecasterName': r.botName,
          'source': 'bounty',
          if (r.responseId != null) 'responseId': r.responseId,
        },
      ));
      alreadyForecast.add(forecasterId);
      imported++;
    }

    return BountyImportResult(
      imported: imported,
      duplicates: duplicates,
      rejected: rejected,
    );
  }
}
