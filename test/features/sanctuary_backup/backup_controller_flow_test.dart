import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// End-to-end net for the wiring: Reckon's real serializer + real crypto,
/// driven through the package's [BackupController] with Reckon's actual
/// config (appId 'reckon', context 'reckon-backup/v1', appDomain 'reckon').
/// The generic controller behaviour (RestoreOutcome mapping, seed flows) is
/// unit-tested in the package; this proves Reckon's wiring works against the
/// real sanctuary_auth_core (SANCTUARY-BRIEF §4.W2).
const _validPhrase =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 6, 1);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer makeContainer({
    required AppDatabase database,
    required SecureKeyStore store,
    void Function(Ref ref)? onAfterRestore,
  }) {
    final c = ProviderContainer(overrides: [
      secureKeyStoreProvider.overrideWithValue(store),
      cryptoServiceProvider.overrideWithValue(const DefaultCryptoService()),
      sanctuaryAppDomainProvider.overrideWithValue('reckon'),
      // v0.2.0 takes a MANDATORY verified pre-restore snapshot; without an
      // in-memory vault the default store needs a real filesystem and every
      // restore fails closed as snapshotFailed.
      vaultStoreProvider.overrideWithValue(InMemoryVaultStore()),
      backupSerializerProvider
          .overrideWith((ref) => ReckonBackupSerializer(database)),
      sanctuaryBackupConfigProvider.overrideWithValue(
        SanctuaryBackupConfig(
          appId: 'reckon',
          aadContext: 'reckon-backup/v1',
          appDisplayName: 'Reckon',
          onAfterRestore: onAfterRestore,
        ),
      ),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('export → restore round-trips Reckon data through the controller',
      () async {
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

    final src = makeContainer(
      database: db,
      store: InMemorySecureKeyStore(
          mnemonic: _validPhrase, acknowledged: true),
    );
    final result =
        await src.read(backupControllerProvider.notifier).exportBackup();
    expect(result, isNotNull);
    expect(result!.filename,
        matches(RegExp(r'^reckon-backup-\d{4}-\d{2}-\d{2}\.ohbk$')));
    // OHBK magic bytes.
    expect(result.bytes.sublist(0, 4), equals([0x4F, 0x48, 0x42, 0x4B]));

    // Restore into a fresh DB with a fresh (empty) keychain, by phrase.
    final db2 = AppDatabase(NativeDatabase.memory());
    addTearDown(db2.close);
    var refreshed = false;
    final dst = makeContainer(
      database: db2,
      store: InMemorySecureKeyStore(),
      onAfterRestore: (_) => refreshed = true,
    );
    final outcome = await dst
        .read(backupControllerProvider.notifier)
        .restoreWithPhrase(result.bytes, _validPhrase);

    expect(outcome, RestoreOutcome.success);
    expect(refreshed, isTrue, reason: 'onAfterRestore must fire');

    final cases = await db2.select(db2.cases).get();
    expect(cases, hasLength(1));
    expect(cases.first.question, equals('Marry now or wait?'));
  });

  test('a non-OHBK blob restores as corruptFile', () async {
    final c = makeContainer(database: db, store: InMemorySecureKeyStore());
    final outcome = await c
        .read(backupControllerProvider.notifier)
        .restoreWithPhrase(Uint8List.fromList(List.filled(64, 0)), _validPhrase);
    expect(outcome, RestoreOutcome.corruptFile);
  });

  test('a Lullaby-context blob cannot be restored under reckon-backup/v1',
      () async {
    // Same key derivation, different AAD context — proves the per-app
    // context binding (SANCTUARY-BRIEF §2.3): a blob made for one app can
    // never decrypt under another's context, even with the same phrase.
    final store = InMemorySecureKeyStore(
        mnemonic: _validPhrase, acknowledged: true);
    final lullabyContainer = ProviderContainer(overrides: [
      secureKeyStoreProvider.overrideWithValue(store),
      cryptoServiceProvider.overrideWithValue(const DefaultCryptoService()),
      sanctuaryAppDomainProvider.overrideWithValue('reckon'),
      backupSerializerProvider
          .overrideWith((ref) => FakeBackupSerializer()),
      sanctuaryBackupConfigProvider.overrideWithValue(
        const SanctuaryBackupConfig(
          appId: 'lullaby',
          aadContext: 'ghost-backup/v1',
          appDisplayName: 'Lullaby',
        ),
      ),
    ]);
    addTearDown(lullabyContainer.dispose);
    final foreignBlob = await lullabyContainer
        .read(backupControllerProvider.notifier)
        .exportBackup();
    expect(foreignBlob, isNotNull);

    final reckon = makeContainer(database: db, store: store);
    final outcome = await reckon
        .read(backupControllerProvider.notifier)
        .restoreWithPhrase(foreignBlob!.bytes, _validPhrase);
    expect(outcome, RestoreOutcome.wrongPhrase);
  });
}
