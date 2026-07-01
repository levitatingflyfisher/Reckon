import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../core/notifications/local_notification_service.dart';
import '../core/notifications/notification_providers.dart';
import '../core/theme/theme_preference.dart';
import 'router.dart';

class ReckonApp extends ConsumerStatefulWidget {
  const ReckonApp({super.key});

  @override
  ConsumerState<ReckonApp> createState() => _ReckonAppState();
}

class _ReckonAppState extends ConsumerState<ReckonApp> {
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    final notif = ref.read(localNotificationServiceProvider);

    // Deep-link on taps that arrive while the app is running.
    _notifSub = notif.selections.listen(_handlePayload);

    // Deep-link on a cold start launched by tapping a notification. Deferred
    // to the first frame so the router exists and the home shell renders
    // underneath the target (back returns to a sane place).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final payload = await notif.initialLaunchPayload();
      if (payload != null) _handlePayload(payload);
    });

    // Silent freshness snapshot (BACKUP_RETENTION_SPEC §3): if the newest
    // vault snapshot is >7 days old and a key exists, take one. Post-frame
    // + fire-and-forget — never blocks boot, never surfaces errors.
    // ReckonApp only mounts after _Bootstrap resolves, so this runs strictly
    // post-bootstrap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupControllerProvider.notifier).runStartupMaintenance();
    });
  }

  void _handlePayload(String payload) {
    final route = routeForNotificationPayload(payload);
    if (route == null || !mounted) return;
    ref.read(routerProvider).go(route);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Tri-theme: the user picks one; we don't auto-switch off system.
    // Default to Light when the preference hasn't loaded / isn't set.
    final pref =
        ref.watch(themePreferenceProvider).valueOrNull ?? ThemePreference.light;
    return MaterialApp.router(
      title: 'Reckon',
      theme: pref.build(),
      routerConfig: router,
      builder: (context, child) {
        final inner = child ?? const SizedBox.shrink();
        if (MediaQuery.of(context).size.width <= 760) return inner;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(child: SizedBox(width: 760, child: inner)),
        );
      },
    );
  }
}
