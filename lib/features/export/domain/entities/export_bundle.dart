import '../../../case/domain/entities/case.dart';
import '../../../case/domain/entities/poll.dart';
import '../../../outside_view/domain/entities/outside_view.dart';
import '../../../outside_view/domain/entities/user_profile.dart';

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
  });

  final Case case_;
  final List<Poll> polls;
  final OutsideView? outsideView;
  final ResolutionExport? resolution;
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
