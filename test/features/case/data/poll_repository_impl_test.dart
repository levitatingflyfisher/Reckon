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
  late PollRepositoryImpl polls;
  late CaseRepositoryImpl cases;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    polls = PollRepositoryImpl(db);
    cases = CaseRepositoryImpl(db);
    await cases.insert(Case(
      id: 'c1',
      createdAt: DateTime(2026, 4, 10),
      deadline: null,
      status: CaseStatus.open,
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

  test('insertNext assigns pollNumber 1 on first insert', () async {
    final poll = await polls.insertNext(
      id: 'p1',
      caseId: 'c1',
      createdAt: DateTime(2026, 4, 11),
      lean: 60,
      confidence: Confidence.medium,
    );
    expect(poll.pollNumber, 1);
  });

  test('insertNext assigns sequential numbers on sequential calls', () async {
    for (var i = 0; i < 3; i++) {
      await polls.insertNext(
        id: 'p$i',
        caseId: 'c1',
        createdAt: DateTime(2026, 4, 11 + i),
        lean: 50 + i,
        confidence: Confidence.medium,
      );
    }
    final all = await polls.getByCaseId('c1');
    expect(all.map((p) => p.pollNumber), [1, 2, 3]);
  });

  test('insertNext produces unique pollNumbers under concurrent calls',
      () async {
    // Fire three concurrent inserts. Before the transaction fix, the
    // read-then-write pattern races and multiple polls can share a
    // pollNumber. The transaction-wrapped implementation must assign
    // three distinct numbers.
    final results = await Future.wait([
      polls.insertNext(
        id: 'pa',
        caseId: 'c1',
        createdAt: DateTime(2026, 4, 11),
        lean: 50,
        confidence: Confidence.low,
      ),
      polls.insertNext(
        id: 'pb',
        caseId: 'c1',
        createdAt: DateTime(2026, 4, 11),
        lean: 60,
        confidence: Confidence.medium,
      ),
      polls.insertNext(
        id: 'pc',
        caseId: 'c1',
        createdAt: DateTime(2026, 4, 11),
        lean: 70,
        confidence: Confidence.high,
      ),
    ]);
    final numbers = results.map((p) => p.pollNumber).toSet();
    expect(numbers, {1, 2, 3});
  });

  test('getByCaseId returns polls ordered by pollNumber', () async {
    await polls.insertNext(
      id: 'p1',
      caseId: 'c1',
      createdAt: DateTime(2026, 4, 11),
      lean: 50,
      confidence: Confidence.medium,
    );
    await polls.insertNext(
      id: 'p2',
      caseId: 'c1',
      createdAt: DateTime(2026, 4, 12),
      lean: 60,
      confidence: Confidence.medium,
    );
    final list = await polls.getByCaseId('c1');
    expect(list.map((p) => p.pollNumber), [1, 2]);
  });

  test('markAllRevealed flips the revealed flag for every poll in the case',
      () async {
    await polls.insertNext(
      id: 'p1',
      caseId: 'c1',
      createdAt: DateTime(2026, 4, 11),
      lean: 50,
      confidence: Confidence.medium,
    );
    await polls.insertNext(
      id: 'p2',
      caseId: 'c1',
      createdAt: DateTime(2026, 4, 12),
      lean: 60,
      confidence: Confidence.medium,
    );
    await polls.markAllRevealed('c1');
    final list = await polls.getByCaseId('c1');
    expect(list.every((p) => p.revealed), isTrue);
  });
}
