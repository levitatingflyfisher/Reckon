import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

/// Reckon's recorded fleet posture — every deliberate divergence from
/// canon lives in this one config (see oh_fleet_conformance's README).
void main() => runFleetConformance(const FleetAppConfig(
      appId: 'reckon',
      // Tokens tier: canonical openhearth_design is the declared dependency;
      // the shipped look stays blessed app identity in lib/shared/theme/
      // (ReckonTheme/ReckonAccents), pinned by the golden sweeps.
      styleTier: StyleTier.tokens,
      androidPermissions: {
        // Relay sync, BYOK cloud LLM calls, on-device model downloads.
        'android.permission.INTERNET',
        // Repoll reminders (flutter_local_notifications).
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SCHEDULE_EXACT_ALARM',
        // Reschedule reminders after reboot.
        'android.permission.RECEIVE_BOOT_COMPLETED',
      },
      // C4 v2 — the release MERGED surface: source permissions plus
      // what plugins and the manifest merge inject. Bites when an APK
      // build has left a merged manifest under build/ (dev box).
      mergedAndroidPermissions: {
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.INTERNET',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.VIBRATE',
        'android.permission.WAKE_LOCK',
        'org.openhearth.reckon.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      },
      // Startup takes the silent freshness snapshot (startup_maintenance).
      expectStartupMaintenance: true,
      // Reckon's analysis_options is a recorded TIGHTER override of the
      // stock template (analyzer excludes for *.g.dart and the relay
      // sub-package, which has its own analysis + CI job).
      analysisOptionsOverrideRecorded: true,
    ));
