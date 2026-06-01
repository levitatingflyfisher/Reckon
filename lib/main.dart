import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/auth/auth_providers.dart';
import 'core/database/database_providers.dart';
import 'core/notifications/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // flutter_gemma 0.13.x requires this one-time init before installModel /
  // getActiveModel are used — without it, starting a case throws
  // "Bad state: FlutterGemma not initialized!".
  await FlutterGemma.initialize();
  runApp(const ProviderScope(child: _Bootstrap()));
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
