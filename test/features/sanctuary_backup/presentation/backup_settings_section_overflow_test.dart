import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// Regression guard mirroring the fleet's accessibility-overflow convention
/// (sweep textScale up to 3.0 at a 320dp-wide screen): Reckon's encrypted
/// backup section — dropped into SettingsScreen alongside `_BackupCard`
/// (SANCTUARY-BRIEF §4.W2, deliverable 5) — must scroll, not overflow, at
/// the largest supported accessibility text scale on the narrowest supported
/// phone width.
Widget _wrapWithProviders(Widget child, {required SecureKeyStore store}) {
  return ProviderScope(
    overrides: [
      secureKeyStoreProvider.overrideWithValue(store),
      sanctuaryAppDomainProvider.overrideWithValue('reckon'),
      sanctuaryBackupConfigProvider.overrideWithValue(
        const SanctuaryBackupConfig(
          appId: 'reckon',
          aadContext: 'reckon-backup/v1',
          appDisplayName: 'Reckon',
          restoreReplaceConsequence:
              'Restoring will delete every case, poll, outside view, '
              'resolution, model prediction, and your profile currently on '
              'this device, then replace them with the contents of the '
              'backup file.',
        ),
      ),
      backupSerializerProvider.overrideWithValue(FakeBackupSerializer()),
    ],
    child: MaterialApp(
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(3.0)),
        child: widget!,
      ),
      home: Scaffold(body: ListView(children: [child])),
    ),
  );
}

void main() {
  group('BackupSettingsSection at 320dp / textScale 3.0', () {
    Future<void> pumpAt320(WidgetTester tester, Widget app) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app);
    }

    testWidgets('ghost state (no key yet) renders without overflow',
        (tester) async {
      await pumpAt320(
        tester,
        _wrapWithProviders(
          const BackupSettingsSection(),
          store: InMemorySecureKeyStore(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Encrypted Backup'), findsOneWidget);
      expect(find.text('Set up encrypted backup'), findsOneWidget);
    });

    testWidgets('acknowledged state (export/restore visible) renders '
        'without overflow', (tester) async {
      await pumpAt320(
        tester,
        _wrapWithProviders(
          const BackupSettingsSection(),
          store: InMemorySecureKeyStore(
            mnemonic:
                'abandon abandon abandon abandon abandon abandon abandon '
                'abandon abandon abandon abandon about',
            acknowledged: true,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
      expect(find.text('Export backup'), findsOneWidget);
      expect(find.text('Restore from backup'), findsOneWidget);
      expect(find.text('Reset identity'), findsOneWidget);
    });
  });
}
