import 'package:http/http.dart' as http;

import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'anthropic_client.dart';
import 'anthropic_llm_service.dart';
import 'llm_service.dart';

/// Connected mode: calls a Cloudflare Worker proxy that holds the Anthropic key
/// server-side (the user never sees it). Same Messages API shape as BYOK — the
/// Worker forwards to Anthropic — so it reuses [AnthropicLlmService], pointed at
/// the Worker origin with an optional app token instead of a user key.
class ConnectedModeImpl implements LlmService {
  ConnectedModeImpl({
    required Uri workerBaseUrl,
    String? appToken,
    String model = defaultModel,
    http.Client? httpClient,
  }) : _inner = AnthropicLlmService(
          AnthropicClient(
            baseUrl: workerBaseUrl,
            headers: {
              if (appToken != null) 'authorization': 'Bearer $appToken',
            },
            model: model,
            httpClient: httpClient,
          ),
        );

  /// Server can override; this is the default the Worker requests.
  static const defaultModel = 'claude-sonnet-4-6';

  final AnthropicLlmService _inner;

  @override
  String get modelVersion => _inner.modelVersion;

  @override
  Stream<String> conductIntake(IntakeContext ctx) => _inner.conductIntake(ctx);

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
          Case case_, ReferenceClassEntry ref, UserProfile profile) =>
      _inner.synthesizeOutsideView(case_, ref, profile);

  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      _inner.detectRepollSentiment(lean, rationale);

  @override
  Future<RevealObservation> generateRevealObservation(
          CaseTimeSeries timeSeries) =>
      _inner.generateRevealObservation(timeSeries);

  @override
  Future<CommunitySeed> generateCommunitySeed(Case case_) =>
      _inner.generateCommunitySeed(case_);
}
