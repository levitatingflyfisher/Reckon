import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/case/data/case_repository_impl.dart';
import 'package:reckon/features/case/data/poll_repository_impl.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/domain/entities/criterion.dart';
import 'package:reckon/features/case/domain/entities/poll.dart';

void main() {
  late AppDatabase db;
  late CaseRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CaseRepositoryImpl(db);
  });

  tearDown(() => db.close());

  final sample = Case(
    id: 'case-1',
    createdAt: DateTime(2026, 4, 10),
    deadline: DateTime(2026, 5, 1),
    status: CaseStatus.open,
    question: 'Should I take the job?',
    optionA: 'Stay',
    optionB: 'Accept',
    statedCriteria: const [Criterion(label: 'comp', weight: 1.0)],
    stakes: Stakes.high,
    regretHorizon: RegretHorizon.years,
    category: 'career',
  );

  test('insert + getById roundtrip', () async {
    await repo.insert(sample);
    final fetched = await repo.getById('case-1');
    expect(fetched, isNotNull);
    expect(fetched!.question, 'Should I take the job?');
    expect(fetched.statedCriteria.first.label, 'comp');
  });

  test('getByStatus filters correctly', () async {
    await repo.insert(sample);
    final open = await repo.getByStatus(CaseStatus.open);
    final decided = await repo.getByStatus(CaseStatus.decided);
    expect(open, hasLength(1));
    expect(decided, isEmpty);
  });

  test('updateStatus changes status', () async {
    await repo.insert(sample);
    await repo.updateStatus('case-1', CaseStatus.decided);
    final fetched = await repo.getById('case-1');
    expect(fetched!.status, CaseStatus.decided);
  });

  group('markDecided', () {
    late PollRepositoryImpl polls;
    setUp(() {
      polls = PollRepositoryImpl(db);
    });

    test('reveals all polls and moves an open case to decided', () async {
      await repo.insert(sample);
      await polls.insertNext(
        id: 'p1',
        caseId: 'case-1',
        createdAt: DateTime(2026, 4, 11),
        lean: 50,
        confidence: Confidence.medium,
      );
      await polls.insertNext(
        id: 'p2',
        caseId: 'case-1',
        createdAt: DateTime(2026, 4, 12),
        lean: 60,
        confidence: Confidence.medium,
      );

      await repo.markDecided('case-1');

      final fetched = await repo.getById('case-1');
      expect(fetched!.status, CaseStatus.decided);
      final list = await polls.getByCaseId('case-1');
      expect(list.every((p) => p.revealed), isTrue);
    });

    test('is a no-op when the case is already in a later state', () async {
      await repo.insert(sample);
      await repo.updateStatus('case-1', CaseStatus.resolving);
      await repo.markDecided('case-1');
      final fetched = await repo.getById('case-1');
      expect(fetched!.status, CaseStatus.resolving,
          reason: 'must not regress status');
    });

    test('is a no-op when the case id is unknown', () async {
      await repo.markDecided('nope');
      expect(await repo.getById('nope'), isNull);
    });
  });
}
