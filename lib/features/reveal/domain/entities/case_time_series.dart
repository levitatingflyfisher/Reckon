import '../../../case/domain/entities/criterion.dart';
import '../../../case/domain/entities/poll.dart';

class CaseTimeSeries {
  const CaseTimeSeries({
    required this.polls,
    required this.statedCriteria,
    required this.category,
    required this.deadline,
    required this.finalChoice,
  });

  final List<Poll> polls;
  final List<Criterion> statedCriteria;
  final String category;
  final DateTime? deadline;
  final String finalChoice;
}
