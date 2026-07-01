import '../../features/case/domain/entities/case.dart';
import '../../features/outside_view/domain/entities/reference_class_entry.dart';
import '../../features/outside_view/domain/entities/user_profile.dart';
import '../../features/reveal/domain/entities/case_time_series.dart';
import '../../features/reveal/domain/entities/reveal_observation.dart';

class IntakeContext {
  const IntakeContext({
    required this.transcript,
    required this.userInput,
  });

  final List<IntakeTurn> transcript;
  final String userInput;
}

class IntakeTurn {
  const IntakeTurn({required this.role, required this.content});
  final IntakeRole role;
  final String content;
}

enum IntakeRole { user, assistant }

class OutsideViewResult {
  const OutsideViewResult({
    required this.baseRateSummary,
    required this.referenceClassUsed,
    required this.uncertaintyLevel,
    required this.stratificationFactors,
    required this.modelVersion,
  });

  final String baseRateSummary;
  final String referenceClassUsed;
  final String uncertaintyLevel;
  final Map<String, dynamic> stratificationFactors;
  final String modelVersion;
}

class MismatchResult {
  const MismatchResult({required this.mismatch, required this.observation});
  final bool mismatch;
  final String observation;
}

class CommunitySeed {
  const CommunitySeed({required this.lean, required this.rationale});
  final int lean;
  final String rationale;
}

/// A de-identified rewrite of a decision question, produced before anything
/// leaves the device via a bounty export. The sentinel (both fields empty)
/// marks a failed rewrite; callers must fall back to manual redaction, never
/// export un-checked text.
class RedactedQuestion {
  const RedactedQuestion({required this.title, required this.background});

  static const sentinel = RedactedQuestion(title: '', background: '');

  final String title;
  final String background;

  bool get isSentinel => title.isEmpty && background.isEmpty;
}

abstract class LlmService {
  /// Identifier of the active [ReckonModelSpec]. Prediction logging uses
  /// this to attribute outputs when Reckon supports multiple local models.
  String get modelVersion;

  Stream<String> conductIntake(IntakeContext ctx);

  Future<OutsideViewResult> synthesizeOutsideView(
    Case case_,
    ReferenceClassEntry ref,
    UserProfile profile,
  );

  Future<MismatchResult> detectRepollSentiment(int lean, String rationale);

  Future<RevealObservation> generateRevealObservation(
    CaseTimeSeries timeSeries,
  );

  /// One forecaster's sealed lean on [case_]. [persona] is an optional
  /// one-sentence stance (a "forecaster" on the resident model is exactly a
  /// persona + temperature); [temperature] overrides the structured-call
  /// default of 0.4.
  ///
  /// Error policy: failures return the sentinel `CommunitySeed(50, '')` — an
  /// EMPTY rationale marks a non-forecast. Callers that log forecasts must
  /// skip sentinels or the track record fills with model hiccups.
  Future<CommunitySeed> generateCommunitySeed(
    Case case_, {
    String? persona,
    double? temperature,
  });

  /// Rewrites a question's [title] and [background] so a stranger could read
  /// them without learning who wrote them (names, employers, exact places,
  /// ages and amounts generalised). Used by the bounty export; the result is
  /// ALWAYS routed through an editable preview — the model drafts, the user
  /// signs off.
  ///
  /// Error policy: failures return [RedactedQuestion.sentinel]; callers fall
  /// back to the original text flagged for manual redaction.
  Future<RedactedQuestion> redactQuestion({
    required String title,
    required String background,
  });
}
