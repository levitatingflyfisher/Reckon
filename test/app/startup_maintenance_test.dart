import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/app/app.dart';
import 'package:reckon/core/auth/auth_providers.dart';
import 'package:reckon/core/database/app_database.dart';
import 'package:reckon/core/database/database_providers.dart';
import 'package:reckon/features/sanctuary_backup/data/backup_serializer.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// BACKUP_RETENTION_SPEC §3: app bootstrap must run the silent freshness
/// net — post-first-frame, fire-and-forget — so a user who set up a key but
/// stopped exporting still accumulates vault snapshots. This pumps the real
/// [ReckonApp] and proves the hook actually fires (the maintenance behaviour
/// itself is unit-tested in the package; this is the app-side wiring).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const validPhrase =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
      'abandon abandon abandon about';

  testWidgets(
      'app boot takes a silent freshness snapshot when a key exists and the '
      'vault is stale', (tester) async {
    // ReckonApp's cold-start deep-link check hits the notifications plugin
    // channel; answer null ("not launched from a notification").
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => null,
    );
    // themePreferenceProvider reads flutter_secure_storage; null = unset.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );

    final db = AppDatabase(NativeDatabase.memory());
    // NOT closed in teardown: closing a drift database inside testWidgets'
    // FakeAsync zone deadlocks the test's finalization (its close future
    // needs real event-loop turns that never come). The in-memory database
    // dies with the test process.
    final vault = InMemoryVaultStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          onboardingCompleteProvider.overrideWith((ref) async => true),
          secureKeyStoreProvider.overrideWithValue(
            InMemorySecureKeyStore(mnemonic: validPhrase, acknowledged: true),
          ),
          cryptoServiceProvider.overrideWithValue(FakeCryptoService()),
          sanctuaryAppDomainProvider.overrideWithValue('reckon'),
          vaultStoreProvider.overrideWithValue(vault),
          backupSerializerProvider
              .overrideWith((ref) => ReckonBackupSerializer(db)),
          sanctuaryBackupConfigProvider.overrideWithValue(
            const SanctuaryBackupConfig(
              appId: 'reckon',
              aadContext: 'reckon-backup/v1',
              appDisplayName: 'Reckon',
            ),
          ),
        ],
        child: const ReckonApp(),
      ),
    );

    // First frame, then the post-frame hook's async chain (auth read →
    // dump → encrypt → vault put) — all microtask-backed, so pumps flush it.
    var entries = await vault.list();
    for (var i = 0; i < 50 && entries.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      entries = await vault.list();
    }

    expect(entries, hasLength(1),
        reason: 'boot must vault a freshness snapshot when the newest one '
            'is missing or stale');
    expect(entries.single.label, VaultLabel.freshness);
  });
}
