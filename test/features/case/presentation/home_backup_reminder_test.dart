import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/presentation/home_screen.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';
import 'package:sanctuary_backup_ui/testing.dart';

/// Fleet ruling: first run opens straight into the task, and unfinished
/// setup (no recovery words yet) gets a persistent, dismissible Finish
/// setup line so it is never forgotten. Reckon's journal lives only on the
/// phone until backup is set up, so the line sits on Home.
void main() {
  late InMemoryBackupReminderStore reminders;

  Widget harness() => ProviderScope(
        overrides: [
          openCasesStreamProvider
              .overrideWith((ref) => Stream.value(const <Case>[])),
          secureKeyStoreProvider.overrideWithValue(InMemorySecureKeyStore()),
          sanctuaryAppDomainProvider.overrideWithValue('reckon'),
          sanctuaryBackupConfigProvider.overrideWithValue(
            const SanctuaryBackupConfig(
              appId: 'reckon',
              aadContext: 'reckon-backup/v1',
              appDisplayName: 'Reckon',
              restoreReplaceConsequence: 'Replaces this device’s decisions.',
            ),
          ),
          backupReminderStoreProvider.overrideWithValue(reminders),
        ],
        child:
            MaterialApp(theme: ReckonTheme.light(), home: const HomeScreen()),
      );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    reminders = InMemoryBackupReminderStore();
  });

  testWidgets('with no recovery words, Home says so and can dismiss it',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining("Backup isn't set up"), findsOneWidget);
    // The task is still the first thing: New case is on screen.
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Backup isn't set up"), findsNothing);
    expect(reminders.dismissedAt, isNotNull);
  });
}
