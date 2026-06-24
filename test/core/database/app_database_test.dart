import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('database opens and creates all tables', () async {
    final tables = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    ).get();
    final names = tables.map((r) => r.data['name'] as String).toList();
    expect(
      names,
      containsAll([
        'cases',
        'polls',
        'resolutions',
        'outside_views',
        'reference_classes',
        'user_profile',
        'community_forecasts',
      ]),
    );
  });

  test('user_profile has a single row with id=1 on create', () async {
    final row = await db.select(db.userProfile).getSingle();
    expect(row.id, 1);
    expect(row.sesBracket, isNull);
  });

  test('outside_views has a citations column (schema v3)', () async {
    final cols = await db
        .customSelect("PRAGMA table_info('outside_views')")
        .get();
    final names = cols.map((r) => r.data['name'] as String).toList();
    expect(names, contains('citations'));
  });

  test('migrates v2 -> v3: adds citations column, preserving existing rows',
      () async {
    // Build a v2-shaped database by hand: outside_views without the citations
    // column, one existing row, and user_version = 2.
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE outside_views (
        id TEXT NOT NULL PRIMARY KEY,
        case_id TEXT NOT NULL,
        generated_at INTEGER NOT NULL,
        base_rate_summary TEXT NOT NULL,
        reference_class_used TEXT NOT NULL,
        uncertainty_level TEXT NOT NULL,
        stratification_factors TEXT NOT NULL,
        llm_mode TEXT NOT NULL,
        model_version TEXT NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO outside_views VALUES "
      "('ov-old','c-old',1700000000,'sum','rc','low','{}','private','gemma');",
    );
    raw.execute('PRAGMA user_version = 2');

    // Opening AppDatabase triggers onUpgrade(2 -> 3).
    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final cols = await upgraded
        .customSelect("PRAGMA table_info('outside_views')")
        .get();
    final names = cols.map((r) => r.data['name'] as String).toList();
    expect(names, contains('citations'),
        reason: 'onUpgrade should add the citations column');

    final rows = await upgraded
        .customSelect('SELECT id, citations FROM outside_views')
        .get();
    expect(rows, hasLength(1), reason: 'existing row must survive migration');
    expect(rows.first.data['id'], 'ov-old');
    expect(rows.first.data['citations'], isNull);
  });

  test('foreign keys are enforced — orphan child insert is rejected',
      () async {
    await expectLater(
      db.into(db.polls).insert(PollsCompanion.insert(
            id: 'p-orphan',
            caseId: 'no-such-case',
            createdAt: DateTime.utc(2026, 6, 1),
            pollNumber: 1,
            lean: 50,
            confidence: 'medium',
          )),
      throwsA(predicate(
          (e) => e.toString().toUpperCase().contains('FOREIGN KEY'))),
    );
  });
}
