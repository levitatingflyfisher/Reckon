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

  group('schema v5 — forecasters + persistent groups', () {
    test('fresh create includes forecasters, groups and group_members tables',
        () async {
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      ).get();
      final names = tables.map((r) => r.data['name'] as String).toList();
      expect(names, containsAll(['forecasters', 'groups', 'group_members']));
    });

    test('parties gained nullable group_id and considered columns', () async {
      final cols =
          await db.customSelect("PRAGMA table_info('parties')").get();
      final names = cols.map((r) => r.data['name'] as String).toList();
      expect(names, containsAll(['group_id', 'considered']));
    });

    test('party_ballots gained a nullable member_id column', () async {
      final cols =
          await db.customSelect("PRAGMA table_info('party_ballots')").get();
      final names = cols.map((r) => r.data['name'] as String).toList();
      expect(names, contains('member_id'));
    });

    test(
        'migrates v4 -> v5: creates the new tables and adds party columns, '
        'preserving existing rows', () async {
      // Build a v4-shaped database by hand: parties/party_ballots without the
      // group columns, one existing row each, and user_version = 4.
      final raw = sqlite3.openInMemory();
      raw.execute('''
        CREATE TABLE parties (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          voting_method TEXT NOT NULL,
          options TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          closed INTEGER NOT NULL DEFAULT 0
        );
      ''');
      raw.execute('''
        CREATE TABLE party_ballots (
          id TEXT NOT NULL PRIMARY KEY,
          party_id TEXT NOT NULL REFERENCES parties (id),
          method TEXT NOT NULL,
          approvals TEXT NOT NULL,
          ranking TEXT NOT NULL,
          submitted_at INTEGER NOT NULL
        );
      ''');
      raw.execute(
        "INSERT INTO parties VALUES "
        "('party-old','Dinner?','approval','[]',1700000000,0);",
      );
      raw.execute(
        "INSERT INTO party_ballots VALUES "
        "('ballot-old','party-old','approval','[]','[]',1700000001);",
      );
      raw.execute('PRAGMA user_version = 4');

      // Opening AppDatabase triggers onUpgrade(4 -> 5).
      final upgraded = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(upgraded.close);

      final tables = await upgraded.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'",
      ).get();
      final tableNames = tables.map((r) => r.data['name'] as String).toList();
      expect(tableNames,
          containsAll(['forecasters', 'groups', 'group_members']),
          reason: 'onUpgrade should create the v5 tables');

      final partyRows = await upgraded
          .customSelect('SELECT id, group_id, considered FROM parties')
          .get();
      expect(partyRows, hasLength(1),
          reason: 'existing party must survive migration');
      expect(partyRows.first.data['id'], 'party-old');
      expect(partyRows.first.data['group_id'], isNull,
          reason: 'pre-group parties stay ungrouped');
      expect(partyRows.first.data['considered'], 0,
          reason: 'pre-v5 parties default to not-considered');

      final ballotRows = await upgraded
          .customSelect('SELECT id, member_id FROM party_ballots')
          .get();
      expect(ballotRows, hasLength(1));
      expect(ballotRows.first.data['member_id'], isNull,
          reason: 'pre-v5 ballots stay anonymous');
    });

    test('group_members foreign key to groups is enforced', () async {
      await expectLater(
        db.customStatement(
          "INSERT INTO group_members "
          "(id, group_id, member_id, display_name, joined_at) "
          "VALUES ('gm-orphan', 'no-such-group', 'm1', 'Ann', 1700000000)",
        ),
        throwsA(predicate(
            (e) => e.toString().toUpperCase().contains('FOREIGN KEY'))),
      );
    });

    test('group_members (group_id, member_id) pair is unique', () async {
      await db.customStatement(
        "INSERT INTO \"groups\" (id, name, created_at, archived) "
        "VALUES ('g1', 'Household', 1700000000, 0)",
      );
      await db.customStatement(
        "INSERT INTO group_members "
        "(id, group_id, member_id, display_name, joined_at) "
        "VALUES ('gm1', 'g1', 'm1', 'Ann', 1700000000)",
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO group_members "
          "(id, group_id, member_id, display_name, joined_at) "
          "VALUES ('gm2', 'g1', 'm1', 'Ann again', 1700000001)",
        ),
        throwsA(
            predicate((e) => e.toString().toUpperCase().contains('UNIQUE'))),
      );
    });
  });
}
