import '../../../case/domain/entities/case.dart';
import '../../../case/domain/entities/poll.dart';
import '../../../outside_view/domain/entities/outside_view.dart';
import '../../../outside_view/domain/entities/user_profile.dart';
import '../../../predictions/domain/entities/model_prediction.dart';

class ExportBundle {
  const ExportBundle({
    required this.generatedAt,
    required this.profile,
    required this.cases,
  });

  final DateTime generatedAt;
  final UserProfile profile;
  final List<CaseExport> cases;
}

class CaseExport {
  const CaseExport({
    required this.case_,
    required this.polls,
    this.outsideView,
    this.resolution,
    this.predictions = const [],
  });

  final Case case_;
  final List<Poll> polls;
  final OutsideView? outsideView;
  final ResolutionExport? resolution;

  /// The forecaster-duel prediction/track-record rows logged against this
  /// case (`model_predictions`, kind `duelForecast` and others). Part of the
  /// backup round-trip (W4 F1) so restore genuinely "replaces" this history
  /// rather than silently destroying it — the confirm-dialog and
  /// docs/privacy-model.md copy both promise a replace, not a loss.
  final List<ModelPrediction> predictions;
}

class ResolutionExport {
  const ResolutionExport({
    required this.decidedAt,
    required this.chosenOption,
    required this.resolutionCheckDate,
    this.satisfactionScore,
    this.reflection,
  });

  final DateTime decidedAt;
  final String chosenOption;
  final DateTime resolutionCheckDate;
  final int? satisfactionScore;
  final String? reflection;
}
