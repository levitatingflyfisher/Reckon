import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';
import 'llm_service.dart';

/// Base for LLM backends not yet built (Connected, BYOK). Every operation
/// throws [UnimplementedError] tagged with [label]; subclasses supply only
/// their [modelVersion] and the label.
abstract class DeferredLlmService implements LlmService {
  const DeferredLlmService(this.label);

  final String label;

  Never _deferred() => throw UnimplementedError(label);

  @override
  Stream<String> conductIntake(IntakeContext ctx) => _deferred();

  @override
  Future<OutsideViewResult> synthesizeOutsideView(
          Case case_, ReferenceClassEntry ref, UserProfile profile) =>
      _deferred();

  @override
  Future<MismatchResult> detectRepollSentiment(int lean, String rationale) =>
      _deferred();

  @override
  Future<RevealObservation> generateRevealObservation(
          CaseTimeSeries timeSeries) =>
      _deferred();

  @override
  Future<CommunitySeed> generateCommunitySeed(Case case_) => _deferred();
}
