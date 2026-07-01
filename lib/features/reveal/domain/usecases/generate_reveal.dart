import 'package:uuid/uuid.dart';

import '../../../../core/llm/llm_service.dart';
import '../../../case/domain/entities/case.dart';
import '../../../case/domain/entities/poll.dart';
import '../../../predictions/domain/entities/model_prediction.dart';
import '../../../predictions/domain/repositories/prediction_repository.dart';
import '../entities/case_time_series.dart';
import '../entities/reveal_observation.dart';

class GenerateReveal {
  GenerateReveal(this._llm, this._predictions, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final LlmService _llm;
  final PredictionRepository _predictions;
  final Uuid _uuid;

  Future<RevealObservation> call({
    required Case case_,
    required List<Poll> polls,
    required String chosenOption,
  }) async {
    // Fingerprint of the poll series the reveal would narrate. A cached
    // observation is only valid for the exact series it was generated over —
    // if the user added a poll since (count or last poll changed), the cached
    // narrative describes a stale timeline and must be regenerated.
    final pollCount = polls.length;
    final lastPollId = polls.isEmpty ? null : polls.last.id;

    // Reuse a previously generated observation if the user re-enters the
    // reveal (e.g. a `decided` case tapping "Set resolution date"): avoids a
    // redundant on-device LLM run and a duplicate prediction log.
    final prior = await _predictions.forCase(case_.id);
    for (final p in prior) {
      // Reuse only a reveal generated for the SAME chosen option AND the same
      // poll series — otherwise a user who explores/commits option B would be
      // shown the option-A narrative cached from the default selection, or a
      // narrative that predates their latest poll. (Legacy cache entries
      // without a fingerprint fail the match and regenerate once.)
      if (p.kind == PredictionKind.revealObservation &&
          p.payload['chosenOption'] == chosenOption &&
          p.payload['pollCount'] == pollCount &&
          p.payload['lastPollId'] == lastPollId) {
        final text = p.payload['text'];
        if (text is String && text.isNotEmpty) {
          return RevealObservation(text: text);
        }
      }
    }

    final finalChoice =
        chosenOption == 'a' ? case_.optionA : case_.optionB;
    final ts = CaseTimeSeries(
      polls: polls,
      statedCriteria: case_.statedCriteria,
      category: case_.category ?? 'uncategorized',
      deadline: case_.deadline,
      finalChoice: finalChoice,
    );
    final observation = await _llm.generateRevealObservation(ts);

    await _predictions.log(ModelPrediction(
      id: _uuid.v4(),
      caseId: case_.id,
      modelVersion: _llm.modelVersion,
      kind: PredictionKind.revealObservation,
      predictedAt: DateTime.now(),
      payload: {
        'text': observation.text,
        'chosenOption': chosenOption,
        'pollCount': pollCount,
        'lastPollId': lastPollId,
      },
    ));

    return observation;
  }
}
