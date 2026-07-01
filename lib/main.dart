import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import 'app/app.dart';
import 'core/auth/auth_providers.dart';
import 'core/database/database_providers.dart';
import 'core/llm/gemma_init.dart';
import 'core/notifications/notification_providers.dart';
import 'features/case/data/case_providers.dart';
import 'features/outside_view/data/outside_view_providers.dart';
import 'features/predictions/data/prediction_providers.dart';
import 'features/record/data/record_providers.dart';
import 'features/sanctuary_backup/data/backup_serializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // flutter_gemma 0.13.x requires this one-time init before installModel /
  // getActiveModel are used — without it, starting a case throws
  // "Bad state: FlutterGemma not initialized!". Platform-selected so the web
  // build (which has no model runtime) skips it and never imports flutter_gemma.
  await initGemma();
  runApp(
    ProviderScope(
      overrides: [
        // Encrypted-backup wiring (sanctuary_backup_ui). Reckon is a new
        // consumer, so it gets its own isolated key material (appDomain
        // 'reckon') and its own AEAD context — a blob can never cross apps
        // (SANCTUARY-BRIEF §2.1, §2.3, §4.W2). Party sync
        // (features/party/sync/party_crypto.dart) is untouched by this —
        // it is a separate, ephemeral, link-carried key system.
        sanctuaryAppDomainProvider.overrideWithValue('reckon'),
        sanctuaryBackupConfigProvider.overrideWithValue(
          SanctuaryBackupConfig(
            appId: 'reckon',
            aadContext: 'reckon-backup/v1',
            appDisplayName: 'Reckon',
            restoreReplaceConsequence:
                'Restoring will delete every case, poll, outside view, '
                'resolution, model prediction, and your profile currently '
                'on this device, then replace them with the contents of '
                'the backup file. It does not touch ReckonParty groups or '
                'the forecaster roster — those are not part of this backup.',
            // Restore replaces the case-scoped tables directly through
            // AppDatabase; the Drift watch streams (open cases) self-refresh,
            // but these FutureProviders cache a snapshot and don't — every
            // one must be invalidated or the record/detail screens keep
            // showing wiped rows (SANCTUARY-BRIEF §2.5).
            onAfterRestore: (ref) {
              ref.invalidate(closedCaseRecordsProvider);
              ref.invalidate(clarityScoreProvider);
              ref.invalidate(insightCardsProvider);
              ref.invalidate(closedCasesProvider);
              ref.invalidate(calibrationReportProvider);
              ref.invalidate(personalBaseRatesProvider);
              ref.invalidate(updateQualityProvider);
              ref.invalidate(forecasterWeightsProvider);
              ref.invalidate(caseByIdProvider);
              ref.invalidate(pollsForCaseProvider);
              ref.invalidate(outsideViewForCaseProvider);
              ref.invalidate(duelForecastsForCaseProvider);
            },
          ),
        ),
        backupSerializerProvider.overrideWith(
          (ref) => ReckonBackupSerializer(ref.watch(appDatabaseProvider)),
        ),
      ],
      child: const _Bootstrap(),
    ),
  );
}

class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedReferenceClassesProvider);
    final notif = ref.watch(initNotificationsProvider);
    final onboarded = ref.watch(onboardingCompleteProvider);

    if (seed.isLoading || notif.isLoading || onboarded.isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (seed.hasError || notif.hasError || onboarded.hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Startup error: '
              '${seed.error ?? notif.error ?? onboarded.error}',
            ),
          ),
        ),
      );
    }
    return const ReckonApp();
  }
}
