import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/outside_view/data/outside_view_repository_impl.dart';
import 'package:reckon/features/outside_view/domain/entities/citation.dart';
import 'package:reckon/features/outside_view/domain/entities/outside_view.dart';
import 'package:reckon/features/outside_view/domain/entities/user_profile.dart';

OutsideView _viewWith(List<Citation> citations) => OutsideView(
      id: 'ov-1',
      caseId: 'c-1',
      generatedAt: DateTime.utc(2026, 6, 1),
      baseRateSummary: 'summary',
      referenceClassUsed: 'relationship / marriage',
      uncertaintyLevel: 'low',
      stratificationFactors: const {'ses': 'middle'},
      llmMode: 'private',
      modelVersion: 'gemma-3-1b-it',
      citations: citations,
    );

void main() {
  late AppDatabase db;
  late OutsideViewRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = OutsideViewRepositoryImpl(db);
  });

  tearDown(() => db.close());

  // Outside views reference a case (FK enforced), so insert the parent first.
  Future<void> insertCase(String id) =>
      db.into(db.cases).insert(CasesCompanion.insert(
            id: id,
            createdAt: DateTime.utc(2026, 6, 1),
            status: 'open',
            question: 'q',
            optionA: 'a',
            optionB: 'b',
            statedCriteria: const [],
            stakes: 'high',
            regretHorizon: 'years',
          ));

  test('getUserProfile returns empty profile initially', () async {
    final profile = await repo.getUserProfile();
    expect(profile.hasAny, false);
  });

  test('saveUserProfile + getUserProfile roundtrip', () async {
    await repo.saveUserProfile(const UserProfile(
      sesBracket: 'upper-middle',
      religiosity: 'weekly',
      relationshipStatus: 'married',
    ));
    final profile = await repo.getUserProfile();
    expect(profile.sesBracket, 'upper-middle');
    expect(profile.religiosity, 'weekly');
  });

  test('save + getForCase round-trips citations', () async {
    await insertCase('c-1');
    await repo.save(_viewWith(const [
      Citation(author: 'A', title: 'Study One', url: 'https://example.org/a'),
      Citation(author: 'B', title: 'Study Two', url: ''),
    ]));

    final got = await repo.getForCase('c-1');
    expect(got, isNotNull);
    expect(got!.citations, hasLength(2));
    expect(got.citations[0].author, 'A');
    expect(got.citations[0].title, 'Study One');
    expect(got.citations[0].url, 'https://example.org/a');
    expect(got.citations[1].hasLink, isFalse);
  });

  test('getForCase coerces a NULL citations column to an empty list',
      () async {
    // Simulates a row written before the citations column existed (upgraded
    // install): insert directly with citations absent → NULL.
    await insertCase('c-legacy');
    await db.into(db.outsideViews).insert(
          OutsideViewsCompanion.insert(
            id: 'ov-legacy',
            caseId: 'c-legacy',
            generatedAt: DateTime.utc(2026, 1, 1),
            baseRateSummary: 'old',
            referenceClassUsed: 'career',
            uncertaintyLevel: 'medium',
            stratificationFactors: const {},
            llmMode: 'private',
            modelVersion: 'gemma-3-1b-it',
          ),
        );

    final got = await repo.getForCase('c-legacy');
    expect(got, isNotNull);
    expect(got!.citations, isEmpty);
  });
}
