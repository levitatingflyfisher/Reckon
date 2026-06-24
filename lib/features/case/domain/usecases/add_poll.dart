import 'package:uuid/uuid.dart';
import '../entities/poll.dart';
import '../repositories/poll_repository.dart';

class AddPoll {
  AddPoll(this._polls, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final PollRepository _polls;
  final Uuid _uuid;

  Future<Poll> call({
    required String caseId,
    required int lean,
    required Confidence confidence,
    String? rationale,
    DateTime? now,
  }) {
    return _polls.insertNext(
      id: _uuid.v4(),
      caseId: caseId,
      createdAt: now ?? DateTime.now(),
      lean: lean,
      confidence: confidence,
      rationale: rationale,
    );
  }
}
