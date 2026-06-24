import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/seed/reference_class_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixtureJson = '''
  [
    {
      "id": "test-1",
      "category": "career",
      "subcategory": "test",
      "base_rate_description": "desc",
      "stratification_variables": ["a", "b"],
      "sources": [{"author": "x", "title": "y", "url": "z"}],
      "common_criteria": ["c1"],
      "common_regret_patterns": "patterns",
      "uncertainty_level": "low",
      "last_updated": "2026-04-01"
    }
  ]
  ''';

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('seedFromJsonString inserts all entries', () async {
    await ReferenceClassSeeder(db).seedFromJsonString(fixtureJson);
    final rows = await db.select(db.referenceClasses).get();
    expect(rows, hasLength(1));
    expect(rows.first.id, 'test-1');
    expect(rows.first.category, 'career');
  });

  test('seedFromJsonString is idempotent — does not duplicate', () async {
    final seeder = ReferenceClassSeeder(db);
    await seeder.seedFromJsonString(fixtureJson);
    await seeder.seedFromJsonString(fixtureJson);
    final rows = await db.select(db.referenceClasses).get();
    expect(rows, hasLength(1));
  });

  test('hasBeenSeeded returns false then true after seeding', () async {
    final seeder = ReferenceClassSeeder(db);
    expect(await seeder.hasBeenSeeded(), false);
    await seeder.seedFromJsonString(fixtureJson);
    expect(await seeder.hasBeenSeeded(), true);
  });

  group('bundled reference_classes.json asset', () {
    late List<dynamic> entries;

    setUp(() {
      entries = jsonDecode(
              File('assets/reference_classes.json').readAsStringSync())
          as List<dynamic>;
    });

    test('meets the launch target of 20 categories', () {
      expect(entries, hasLength(20));
    });

    test('every entry is well-formed with a unique id and a source', () {
      const required = [
        'id',
        'category',
        'subcategory',
        'base_rate_description',
        'stratification_variables',
        'sources',
        'common_criteria',
        'common_regret_patterns',
        'uncertainty_level',
        'last_updated',
      ];
      final ids = <String>{};
      for (final e in entries.cast<Map<String, dynamic>>()) {
        for (final key in required) {
          expect(e.containsKey(key), isTrue,
              reason: 'entry ${e['id']} missing "$key"');
        }
        expect((e['sources'] as List).isNotEmpty, isTrue,
            reason: 'entry ${e['id']} has no sources');
        expect(ids.add(e['id'] as String), isTrue,
            reason: 'duplicate id ${e['id']}');
      }
    });

    test('seeding the real asset inserts all 20 rows', () async {
      await ReferenceClassSeeder(db).seedFromJsonString(
          File('assets/reference_classes.json').readAsStringSync());
      final rows = await db.select(db.referenceClasses).get();
      expect(rows, hasLength(20));
    });
  });
}
