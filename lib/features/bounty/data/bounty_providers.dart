import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/llm/llm_providers.dart';
import '../../forecasters/data/forecaster_providers.dart';
import '../../predictions/data/prediction_providers.dart';
import '../domain/usecases/import_bounty_responses.dart';
import '../domain/usecases/redact_question.dart';

/// Redaction drafts on the resident model. The resolver swallows the
/// builder's construction throws (AiUnavailableOnWeb, model-not-downloaded)
/// into null — those platforms simply start the preview in manual mode.
final redactQuestionProvider = Provider<RedactQuestion>((ref) {
  return RedactQuestion(() async {
    try {
      return await ref.read(llmServiceProvider.future);
    } catch (_) {
      return null;
    }
  });
});

/// Paste-import for BountyResponse JSON. Callers invalidate
/// `duelForecastsForCaseProvider(caseId)` (the sealed count) and
/// `forecastersProvider` (new bots join the roster) after a successful
/// import.
final importBountyResponsesProvider = Provider<ImportBountyResponses>((ref) {
  return ImportBountyResponses(
    ref.watch(forecasterRepositoryProvider),
    ref.watch(predictionRepositoryProvider),
  );
});
