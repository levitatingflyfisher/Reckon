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

  Future<CommunitySeed> generateCommunitySeed(Case case_);
}
