import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/reveal/data/resolution_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ResolutionRepositoryImpl repo;
  late CaseRepositoryImpl cases;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ResolutionRepositoryImpl(db);
    cases = CaseRepositoryImpl(db);
    await cases.insert(Case(
      id: 'c1',
      createdAt: DateTime(2026, 4, 10),
      deadline: null,
      status: CaseStatus.decided,
      question: 'q',
      optionA: 'a',
      optionB: 'b',
      statedCriteria: const [Criterion(label: 'x', weight: 1.0)],
      stakes: Stakes.medium,
      regretHorizon: RegretHorizon.months,
      category: null,
    ));
  });

  tearDown(() => db.close());

  Future<int> resolutionCount() async {
    final rows = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .get();
    return rows.length;
  }

  test('create inserts a resolution row and flips case status to resolving',
      () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    final case_ = await cases.getById('c1');
    expect(case_!.status, CaseStatus.resolving);
    expect(await resolutionCount(), 1);
  });

  test('create is idempotent — re-entry updates the existing row', () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    await repo.create(
      caseId: 'c1',
      chosenOption: 'b',
      decidedAt: DateTime(2026, 4, 12),
      resolutionCheckDate: DateTime(2026, 11, 12),
    );
    expect(await resolutionCount(), 1, reason: 'must not insert a duplicate');
    final row = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .getSingle();
    expect(row.chosenOption, 'b');
    expect(row.resolutionCheckDate, DateTime(2026, 11, 12));
  });

  test('scoredResolutions returns (caseId, satisfactionScore) tuples only for scored rows',
      () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    expect(await repo.scoredResolutions(), isEmpty,
        reason: 'pre-satisfaction rows must be excluded');
    await repo.recordSatisfaction(
      caseId: 'c1',
      satisfactionScore: 1,
    );
    final list = await repo.scoredResolutions();
    expect(list, hasLength(1));
    expect(list.single.caseId, 'c1');
    expect(list.single.satisfactionScore, 1);
  });

  test('recordSatisfaction writes score + closes the case', () async {
    await repo.create(
      caseId: 'c1',
      chosenOption: 'a',
      decidedAt: DateTime(2026, 4, 11),
      resolutionCheckDate: DateTime(2026, 10, 11),
    );
    await repo.recordSatisfaction(
      caseId: 'c1',
      satisfactionScore: 2,
      reflection: 'glad I chose a',
    );
    final case_ = await cases.getById('c1');
    expect(case_!.status, CaseStatus.closed);
    final row = await (db.select(db.resolutions)
          ..where((t) => t.caseId.equals('c1')))
        .getSingle();
    expect(row.satisfactionScore, 2);
    expect(row.reflection, 'glad I chose a');
  });
}
