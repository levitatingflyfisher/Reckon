import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/case.dart';
import '../domain/entities/criterion.dart';
import '../domain/repositories/case_repository.dart';

class CaseRepositoryImpl implements CaseRepository {
  CaseRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<void> insert(Case case_) async {
    await _db.into(_db.cases).insert(
          CasesCompanion.insert(
            id: case_.id,
            createdAt: case_.createdAt,
            deadline: Value(case_.deadline),
            status: case_.status.name,
            question: case_.question,
            optionA: case_.optionA,
            optionB: case_.optionB,
            statedCriteria:
                case_.statedCriteria.map((c) => c.toJson()).toList(),
            stakes: case_.stakes.name,
            regretHorizon: case_.regretHorizon.name,
            category: Value(case_.category),
          ),
        );
  }

  @override
  Future<Case?> getById(String id) async {
    final row = await (_db.select(_db.cases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToCase(row);
  }

  @override
  Future<List<Case>> getByStatus(CaseStatus status) async {
    final rows = await (_db.select(_db.cases)
          ..where((t) => t.status.equals(status.name)))
        .get();
    return rows.map(_rowToCase).toList();
  }

  @override
  Future<List<Case>> getClosed() => getByStatus(CaseStatus.closed);

  @override
  Future<void> updateStatus(String id, CaseStatus status) async {
    await (_db.update(_db.cases)..where((t) => t.id.equals(id))).write(
      CasesCompanion(status: Value(status.name)),
    );
  }

  @override
  Stream<List<Case>> watchAll() {
    final query = _db.select(_db.cases)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_rowToCase).toList());
  }

  @override
  Stream<List<Case>> watchActive() {
    final query = _db.select(_db.cases)
      ..where((t) => t.status.isNotIn(const ['closed']))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_rowToCase).toList());
  }

  @override
  Future<void> markDecided(String caseId) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.cases)
            ..where((t) => t.id.equals(caseId)))
          .getSingleOrNull();
      if (row == null || row.status != CaseStatus.open.name) return;
      await (_db.update(_db.polls)..where((t) => t.caseId.equals(caseId)))
          .write(const PollsCompanion(revealed: Value(true)));
      await (_db.update(_db.cases)..where((t) => t.id.equals(caseId))).write(
        CasesCompanion(status: Value(CaseStatus.decided.name)),
      );
    });
  }

  Case _rowToCase(CaseRow row) {
    final criteria = (row.statedCriteria)
        .map((raw) => Criterion.fromJson(raw as Map<String, dynamic>))
        .toList();
    return Case(
      id: row.id,
      createdAt: row.createdAt,
      deadline: row.deadline,
      status: CaseStatus.values.firstWhere(
        (e) => e.name == row.status,
        orElse: () => CaseStatus.open,
      ),
      question: row.question,
      optionA: row.optionA,
      optionB: row.optionB,
      statedCriteria: criteria,
      stakes: Stakes.values.firstWhere(
        (e) => e.name == row.stakes,
        orElse: () => Stakes.medium,
      ),
      regretHorizon: RegretHorizon.values.firstWhere(
        (e) => e.name == row.regretHorizon,
        orElse: () => RegretHorizon.months,
      ),
      category: row.category,
      communityVisible: row.communityVisible,
    );
  }
}
