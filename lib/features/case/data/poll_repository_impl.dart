import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/poll.dart';
import '../domain/repositories/poll_repository.dart';

class PollRepositoryImpl implements PollRepository {
  PollRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> insert(Poll poll) async {
    await _db.into(_db.polls).insert(_companion(poll));
  }

  @override
  Future<List<Poll>> getByCaseId(String caseId) async {
    final rows = await (_db.select(_db.polls)
          ..where((t) => t.caseId.equals(caseId))
          ..orderBy([(t) => OrderingTerm.asc(t.pollNumber)]))
        .get();
    return rows.map(_rowToPoll).toList();
  }

  @override
  Future<void> markAllRevealed(String caseId) async {
    await (_db.update(_db.polls)..where((t) => t.caseId.equals(caseId))).write(
      const PollsCompanion(revealed: Value(true)),
    );
  }

  @override
  Future<Poll> insertNext({
    required String id,
    required String caseId,
    required DateTime createdAt,
    required int lean,
    required Confidence confidence,
    String? rationale,
  }) {
    return _db.transaction(() async {
      final max = _db.polls.pollNumber.max();
      final row = await (_db.selectOnly(_db.polls)
            ..addColumns([max])
            ..where(_db.polls.caseId.equals(caseId)))
          .getSingle();
      final next = (row.read(max) ?? 0) + 1;
      final poll = Poll(
        id: id,
        caseId: caseId,
        createdAt: createdAt,
        pollNumber: next,
        lean: lean,
        confidence: confidence,
        rationale: rationale,
        revealed: false,
      );
      await _db.into(_db.polls).insert(_companion(poll));
      return poll;
    });
  }

  PollsCompanion _companion(Poll poll) => PollsCompanion.insert(
        id: poll.id,
        caseId: poll.caseId,
        createdAt: poll.createdAt,
        pollNumber: poll.pollNumber,
        lean: poll.lean,
        rationale: Value(poll.rationale),
        confidence: poll.confidence.name,
        revealed: Value(poll.revealed),
      );

  Poll _rowToPoll(PollRow r) => Poll(
        id: r.id,
        caseId: r.caseId,
        createdAt: r.createdAt,
        pollNumber: r.pollNumber,
        lean: r.lean,
        confidence: Confidence.values.firstWhere(
          (e) => e.name == r.confidence,
          orElse: () => Confidence.medium,
        ),
        rationale: r.rationale,
        revealed: r.revealed,
      );
}
