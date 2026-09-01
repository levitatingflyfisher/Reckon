import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/root_overrides.dart';
import 'app/startup_failure.dart';
import 'core/auth/auth_providers.dart';
import 'core/database/database_providers.dart';
import 'core/llm/gemma_init.dart';
import 'core/notifications/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // flutter_gemma 0.13.x requires this one-time init before installModel /
  // getActiveModel are used — without it, starting a case throws
  // "Bad state: FlutterGemma not initialized!". Platform-selected so the web
  // build (which has no model runtime) skips it and never imports flutter_gemma.
  await initGemma();
  runApp(
    ProviderScope(
      overrides: reckonRootOverrides(),
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
      final failed = seed.hasError
          ? seed
          : notif.hasError
              ? notif
              : onboarded;
      debugPrint('Reckon: startup failed: ${failed.error}');
      return StartupFailure(
          error: failed.error!, stackTrace: failed.stackTrace);
    }
    return const ReckonApp();
  }
}
