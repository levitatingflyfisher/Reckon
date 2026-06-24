import 'package:http/http.dart' as http;

import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'anthropic_client.dart';
import 'anthropic_llm_service.dart';
import 'llm_service.dart';

/// Bring-Your-Own-Key mode: calls the Anthropic API directly with the user's
/// own key (held in secure storage, never sent anywhere but Anthropic). A thin
/// wrapper that points [AnthropicLlmService] at `api.anthropic.com`.
class ByokModeImpl implements LlmService {
  ByokModeImpl({
    required String apiKey,
    String model = defaultModel,
    http.Client? httpClient,
  }) : _inner = AnthropicLlmService(
          AnthropicClient(
            baseUrl: Uri.parse('https://api.anthropic.com'),
            headers: {'x-api-key': apiKey},
            model: model,
            httpClient: httpClient,
          ),
        );

  /// Balanced default; the user can pick another Claude model in settings.
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
