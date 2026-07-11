import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/forecasters/data/forecaster_repository_impl.dart';
import 'package:reckon/features/forecasters/domain/entities/forecaster.dart';

void main() {
  late AppDatabase db;
  late ForecasterRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ForecasterRepositoryImpl(db, now: () => DateTime(2026, 7, 11));
  });

  tearDown(() => db.close());

  Forecaster make({
    String id = 'f1',
    String name = 'Custom bot',
    ForecasterKind kind = ForecasterKind.openaiCompat,
    Map<String, dynamic> config = const {'base_url': 'http://10.0.0.2:8080'},
    bool enabled = true,
  }) =>
      Forecaster(
        id: id,
        displayName: name,
        kind: kind,
        config: config,
        enabled: enabled,
        createdAt: DateTime(2026, 7, 11),
      );

  group('default persona roster', () {
    test('first read on an empty table lazily creates the two personas',
        () async {
      final all = await repo.all();
      expect(all, hasLength(2));
      expect(
        all.map((f) => f.id),
        containsAll(
            ['persona-base-rate-skeptic', 'persona-steelman-advocate']),
      );
      final skeptic =
          all.firstWhere((f) => f.id == 'persona-base-rate-skeptic');
      expect(skeptic.displayName, 'Base-rate skeptic');
      expect(skeptic.kind, ForecasterKind.persona);
      expect(skeptic.enabled, isTrue);
      expect(skeptic.config['persona'], isA<String>());
      expect((skeptic.config['persona'] as String), isNotEmpty);
      final advocate =
          all.firstWhere((f) => f.id == 'persona-steelman-advocate');
      expect(advocate.displayName, 'Steelman advocate');
      expect(advocate.config['persona'], isA<String>());
    });

    test('defaults are not re-seeded once the table has ever been populated',
        () async {
      await repo.all(); // seeds
      await repo.delete('persona-base-rate-skeptic');
      final all = await repo.all();
      expect(all, hasLength(1),
          reason: 'a deleted default must stay deleted — the roster is the '
              "user's to prune");
      expect(all.single.id, 'persona-steelman-advocate');
    });

    test('ensureDefaults is a no-op when a custom forecaster already exists',
        () async {
      await repo.upsert(make());
      await repo.ensureDefaults();
      final all = await repo.all();
      expect(all, hasLength(1));
      expect(all.single.id, 'f1');
    });
  });

  group('crud', () {
    test('upsert inserts and round-trips every field', () async {
      await repo.upsert(make());
      final all = await repo.all();
      final f = all.firstWhere((f) => f.id == 'f1');
      expect(f.displayName, 'Custom bot');
      expect(f.kind, ForecasterKind.openaiCompat);
      expect(f.config['base_url'], 'http://10.0.0.2:8080');
      expect(f.enabled, isTrue);
      expect(f.createdAt, DateTime(2026, 7, 11));
    });

    test('upsert with an existing id updates in place', () async {
      await repo.upsert(make());
      await repo.upsert(make(name: 'Renamed bot', config: const {'m': 'q'}));
      final all = await repo.all();
      final ours = all.where((f) => f.id == 'f1');
      expect(ours, hasLength(1), reason: 'no duplicate row on upsert');
      expect(ours.single.displayName, 'Renamed bot');
      expect(ours.single.config['m'], 'q');
    });

    test('setEnabled flips the flag and enabled() filters on it', () async {
      await repo.upsert(make(id: 'f1'));
      await repo.upsert(make(id: 'f2', name: 'Second'));
      await repo.setEnabled('f1', false);

      final enabled = await repo.enabled();
      expect(enabled.map((f) => f.id), isNot(contains('f1')));
      expect(enabled.map((f) => f.id), contains('f2'));

      await repo.setEnabled('f1', true);
      final reEnabled = await repo.enabled();
      expect(reEnabled.map((f) => f.id), contains('f1'));
    });

    test('delete removes the forecaster', () async {
      await repo.upsert(make(id: 'f1'));
      await repo.upsert(make(id: 'f2', name: 'Second'));
      await repo.delete('f1');
      final all = await repo.all();
      expect(all.map((f) => f.id), isNot(contains('f1')));
      expect(all.map((f) => f.id), contains('f2'));
    });
  });

  test('an unknown persisted kind degrades to persona, not a crash', () async {
    await db.customStatement(
      "INSERT INTO forecasters "
      "(id, display_name, kind, config_json, enabled, created_at) "
      "VALUES ('f-future', 'From the future', 'quantumOracle', '{}', 1, "
      "1700000000)",
    );
    final all = await repo.all();
    final future = all.firstWhere((f) => f.id == 'f-future');
    expect(future.kind, ForecasterKind.persona);
  });
}
