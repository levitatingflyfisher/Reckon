import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

/// [ReckonBackupSerializer] implements sanctuary_backup_ui's [BackupSerializer]
/// over Reckon's own [AppDatabase], reusing [ExportService.gather()] for the
/// export side (SANCTUARY-BRIEF §4.W2). The JSON envelope carries
/// `{app, schemaVersion}` so [restoreAll] can reject a mismatched app or a
/// future schema — defense in depth behind the AEAD context (§2.8).
void main() {
  late AppDatabase db;
  late ReckonBackupSerializer serializer;

  final now = DateTime.utc(2026, 6, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    serializer = ReckonBackupSerializer(db);
  });

  tearDown(() => db.close());

  Future<void> seedCase() async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'c1',
          createdAt: now,
          status: 'open',
          question: 'Marry now or wait?',
          optionA: 'Wait',
          optionB: 'Marry',
          statedCriteria: const [],
          stakes: 'high',
          regretHorizon: 'years',
        ));
    await db.into(db.polls).insert(PollsCompanion.insert(
          id: 'p1',
          caseId: 'c1',
          createdAt: now,
          pollNumber: 1,
          lean: 60,
          confidence: 'high',
        ));
  }

  group('dumpAll', () {
    test('envelope carries app and schemaVersion', () async {
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(json['app'], equals('reckon'));
      expect(json['schemaVersion'], equals(db.schemaVersion));
      expect(json['cases'], isEmpty);
    });

    test('carries every case, poll, and profile field', () async {
      await seedCase();
      await (db.update(db.userProfile)..where((t) => t.id.equals(1))).write(
        const UserProfileCompanion(sesBracket: Value('middle')),
      );

      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      expect(json['profile']['sesBracket'], 'middle');
      final cases = json['cases'] as List<dynamic>;
      expect(cases, hasLength(1));
      final case0 = cases.single as Map<String, dynamic>;
      expect(case0['id'], 'c1');
      expect(case0['question'], 'Marry now or wait?');
      final polls = case0['polls'] as List<dynamic>;
      expect(polls, hasLength(1));
      expect((polls.single as Map<String, dynamic>)['id'], 'p1');
    });
  });

  group('restoreAll', () {
    test('round-trips a full dump back into the database', () async {
      await seedCase();
      final bytes = await serializer.dumpAll();

      final db2 = AppDatabase(NativeDatabase.memory());
      addTearDown(db2.close);
      await ReckonBackupSerializer(db2).restoreAll(bytes);

      final cases = await db2.select(db2.cases).get();
      expect(cases, hasLength(1));
      expect(cases.first.question, 'Marry now or wait?');
      final polls = await db2.select(db2.polls).get();
      expect(polls, hasLength(1));
    });

    test('rejects a backup from a different app', () async {
      final payload = jsonEncode({
        'app': 'lullaby',
        'schemaVersion': db.schemaVersion,
        'generatedAt': now.toIso8601String(),
        'profile': {
          'sesBracket': null,
          'religiosity': null,
          'relationshipStatus': null,
        },
        'cases': <dynamic>[],
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a backup with no app field', () async {
      final payload = jsonEncode({
        'schemaVersion': db.schemaVersion,
        'generatedAt': now.toIso8601String(),
        'profile': {
          'sesBracket': null,
          'religiosity': null,
          'relationshipStatus': null,
        },
        'cases': <dynamic>[],
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a future schema version', () async {
      final payload = jsonEncode({
        'app': 'reckon',
        'schemaVersion': 999,
        'generatedAt': now.toIso8601String(),
        'profile': {
          'sesBracket': null,
          'religiosity': null,
          'relationshipStatus': null,
        },
        'cases': <dynamic>[],
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<BackupSchemaException>()),
      );
    });

    test('rejects missing cases key', () async {
      final payload = jsonEncode({
        'app': 'reckon',
        'schemaVersion': db.schemaVersion,
      });
      final bytes = Uint8List.fromList(utf8.encode(payload));

      expect(
        () => serializer.restoreAll(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('replaces existing data rather than merging', () async {
      await seedCase();
      final untouchedBytes = await serializer.dumpAll();
      // Sanity: the seeded case really is in there.
      expect(
        (jsonDecode(utf8.decode(untouchedBytes))
                as Map<String, dynamic>)['cases'],
        hasLength(1),
      );

      final replacement = jsonEncode({
        'app': 'reckon',
        'schemaVersion': db.schemaVersion,
        'generatedAt': now.toIso8601String(),
        'profile': {
          'sesBracket': null,
          'religiosity': null,
          'relationshipStatus': null,
        },
        'cases': <dynamic>[],
      });
      await serializer.restoreAll(Uint8List.fromList(utf8.encode(replacement)));

      expect(await db.select(db.cases).get(), isEmpty);
    });
  });
}
