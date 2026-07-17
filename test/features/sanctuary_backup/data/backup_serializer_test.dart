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

  // Seeds a case with a poll, an outside view (with a citation), and a
  // resolution — every entity type ExportBundle carries — so the round-trip
  // test below actually exercises the encode/decode pair for all four, not
  // just cases + polls.
  Future<void> seedCase() async {
    await db.into(db.cases).insert(CasesCompanion.insert(
          id: 'c1',
          createdAt: now,
          status: 'decided',
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
    await db.into(db.outsideViews).insert(OutsideViewsCompanion.insert(
          id: 'ov1',
          caseId: 'c1',
          generatedAt: now,
          baseRateSummary: 'summary',
          referenceClassUsed: 'relationship / marriage',
          uncertaintyLevel: 'low',
          stratificationFactors: const {'age': 30},
          llmMode: 'private',
          modelVersion: 'gemma-3-1b-it',
          citations: const Value([
            {'author': 'A', 'title': 'A Study', 'url': 'https://x'},
          ]),
        ));
    await db.into(db.resolutions).insert(ResolutionsCompanion.insert(
          id: 'r1',
          caseId: 'c1',
          decidedAt: now,
          chosenOption: 'Marry',
          resolutionCheckDate: now.add(const Duration(days: 30)),
          satisfactionScore: const Value(8),
          reflection: const Value('glad'),
        ));
    // W4 F1: the forecaster-duel track record must round-trip through the
    // backup, not be silently dropped on restore.
    await db.into(db.modelPredictions).insert(ModelPredictionsCompanion.insert(
          id: 'mp1',
          caseId: 'c1',
          modelVersion: 'gemma-3-1b-it',
          kind: 'duelForecast',
          predictedAt: now,
          payload: const {'lean': 70, 'forecasterName': 'The Actuary'},
          score: const Value(0.4),
          scoredAt: Value(now.add(const Duration(days: 30))),
        ));
  }

  group('dumpAll', () {
    test(
        'envelope stays FLAT (legacy shape byte-compatible) and adds a UTC '
        'createdAt stamp additively', () async {
      final bytes = await serializer.dumpAll();
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      // WIRE-COMPAT: every key the OLD shipped reader requires is still
      // there, at the top level, and no wrap-style nesting appeared.
      expect(json['app'], 'reckon');
      expect(json['schemaVersion'], db.schemaVersion);
      expect(json['generatedAt'], isA<String>());
      expect(json['profile'], isA<Map<String, dynamic>>());
      expect(json['cases'], isA<List<dynamic>>());
      expect(json.containsKey('payload'), isFalse,
          reason: 'old readers look for top-level profile/cases — the flat '
              'shape must never be nested under a payload key');

      // ADDITIVE: the v0.2.0 canonical creation stamp.
      final createdAt = DateTime.parse(json['createdAt'] as String);
      expect(createdAt.isUtc, isTrue);
      expect(
        DateTime.now().toUtc().difference(createdAt).inMinutes,
        lessThan(5),
      );
    });

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

      final outsideView = case0['outsideView'] as Map<String, dynamic>;
      expect(outsideView['id'], 'ov1');
      expect(outsideView['stratificationFactors'], {'age': 30});
      final citations = outsideView['citations'] as List<dynamic>;
      expect((citations.single as Map<String, dynamic>)['title'], 'A Study');

      final resolution = case0['resolution'] as Map<String, dynamic>;
      expect(resolution['chosenOption'], 'Marry');
      expect(resolution['satisfactionScore'], 8);

      final predictions = case0['predictions'] as List<dynamic>;
      expect(predictions, hasLength(1));
      final prediction = predictions.single as Map<String, dynamic>;
      expect(prediction['id'], 'mp1');
      expect(prediction['kind'], 'duelForecast');
      expect(prediction['score'], 0.4);
    });
  });

  group('describeBackup (PreviewableBackupSerializer)', () {
    test('dry-run parses: counts rows, reports metadata, never writes',
        () async {
      await seedCase();
      final bytes = await serializer.dumpAll();

      expect(serializer, isA<PreviewableBackupSerializer>());
      final manifest = await serializer.describeBackup(bytes);
      expect(manifest.appId, 'reckon');
      expect(manifest.schemaVersion, db.schemaVersion);
      expect(manifest.createdAt, isNotNull);
      expect(manifest.tableCounts['cases'], 1);

      // Dry-run guarantee: the seeded case is untouched.
      expect(await db.select(db.cases).get(), hasLength(1));
    });

    test('rejects exactly what restoreAll rejects — wrong app, future '
        'schema, missing cases', () async {
      Uint8List blob(Map<String, dynamic> json) =>
          Uint8List.fromList(utf8.encode(jsonEncode(json)));

      expect(
        () => serializer.describeBackup(blob({
          'app': 'lullaby',
          'schemaVersion': db.schemaVersion,
          'cases': <dynamic>[],
        })),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => serializer.describeBackup(blob({
          'app': 'reckon',
          'schemaVersion': 999,
          'cases': <dynamic>[],
        })),
        throwsA(isA<BackupSchemaException>()),
      );
      expect(
        () => serializer.describeBackup(blob({
          'app': 'reckon',
          'schemaVersion': db.schemaVersion,
        })),
        throwsA(isA<FormatException>()),
      );
      // A profile that isn't an object would blow up restoreAll's parse —
      // the shared gate must refuse it in preview too.
      expect(
        () => serializer.describeBackup(blob({
          'app': 'reckon',
          'schemaVersion': db.schemaVersion,
          'profile': 'not-a-map',
          'cases': <dynamic>[],
        })),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('legacy wire compatibility', () {
    // What every shipped Reckon build before this one wrote: flat keys,
    // generatedAt, NO createdAt.
    Uint8List legacyBlob({bool withGeneratedAt = true}) {
      final json = <String, dynamic>{
        'app': 'reckon',
        'schemaVersion': db.schemaVersion,
        if (withGeneratedAt) 'generatedAt': now.toIso8601String(),
        'profile': {
          'sesBracket': 'middle',
          'religiosity': null,
          'relationshipStatus': null,
        },
        'cases': [
          {
            'id': 'c-legacy',
            'createdAt': now.toIso8601String(),
            'status': 'open',
            'question': 'Old backup, new app?',
            'optionA': 'Restore',
            'optionB': 'Refuse',
            'statedCriteria': <dynamic>[],
            'stakes': 'high',
            'regretHorizon': 'years',
          },
        ],
      };
      return Uint8List.fromList(utf8.encode(jsonEncode(json)));
    }

    test('an old envelope WITHOUT createdAt still restores', () async {
      await serializer.restoreAll(legacyBlob());

      final cases = await db.select(db.cases).get();
      expect(cases, hasLength(1));
      expect(cases.first.question, 'Old backup, new app?');
      final profile = await db.select(db.userProfile).get();
      expect(profile.single.sesBracket, 'middle');
    });

    test('an old envelope WITHOUT createdAt still previews — age falls '
        'back to generatedAt', () async {
      final manifest = await serializer.describeBackup(legacyBlob());
      expect(manifest.tableCounts['cases'], 1);
      // BackupEnvelope treats Reckon's legacy generatedAt as the stamp, so
      // an old backup's age stays informative rather than unknown.
      expect(manifest.createdAt, now);
    });

    test('an envelope with NO stamp at all previews with age unknown and '
        'still restores', () async {
      final blob = legacyBlob(withGeneratedAt: false);

      final manifest = await serializer.describeBackup(blob);
      expect(manifest.createdAt, isNull);
      expect(formatBackupAge(manifest.createdAt, DateTime.now()),
          'age unknown');

      await serializer.restoreAll(blob);
      expect(await db.select(db.cases).get(), hasLength(1));
    });
  });

  group('restoreAll', () {
    test('round-trips a full dump — case, poll, outside view, and '
        'resolution all survive', () async {
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
      expect(polls.first.id, 'p1');

      final views = await db2.select(db2.outsideViews).get();
      expect(views, hasLength(1));
      expect(views.first.stratificationFactors, {'age': 30});
      expect(views.first.citations, hasLength(1));
      final citation =
          (views.first.citations!.single as Map<String, dynamic>);
      expect(citation['title'], 'A Study');
      expect(citation['url'], 'https://x');

      final resolutions = await db2.select(db2.resolutions).get();
      expect(resolutions, hasLength(1));
      expect(resolutions.first.caseId, 'c1');
      expect(resolutions.first.chosenOption, 'Marry');
      expect(resolutions.first.satisfactionScore, 8);
      expect(resolutions.first.reflection, 'glad');

      // W4 F1: the forecaster-duel prediction/track-record history is not
      // silently destroyed by restore — it genuinely round-trips.
      final predictions = await db2.select(db2.modelPredictions).get();
      expect(predictions, hasLength(1));
      expect(predictions.first.caseId, 'c1');
      expect(predictions.first.kind, 'duelForecast');
      expect(predictions.first.score, 0.4);
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
