import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

/// Reckon's recorded fleet posture — every deliberate divergence from
/// canon lives in this one config (see oh_fleet_conformance's README).
void main() => runFleetConformance(const FleetAppConfig(
      appId: 'reckon',
      // Bundles its own type, so nothing falls back to a web font — a
      // character the bundled families cannot draw is a box on a
      // real phone. C7 sweeps lib/ for any.
      // C8: a bare IconButton.filled/.filledTonal would paint its glyph the
      // color of its own fill under ohStyle's ambient iconTheme — invisible
      // on a real phone. Filled icon buttons must go through OhIconButton.
      checks: {
        ...FleetAppConfig.withBundledFonts,
        FleetCheck.c8IconButtons,
        // C10: no raw exception text on screen; failures go through
        // OhErrorState / ohFriendlyErrorMessage (details behind a tap).
        FleetCheck.c10RawErrors,
        // C11, strict: a tooltip is not a bar command's name; every bar
        // action shows its word (OhBarAction / OhBarOverflow).
        FleetCheck.c11StrictBarLabels,
        // C9: every routed screen has a way in.
        FleetCheck.c9Routes,
        // C12: the accent must not read as an error.
        FleetCheck.c12AccentVsError,
        // C5-primaryScreens: each screen below is swept at 360 dp x 1.3
        // (primary action reachable) and 320 dp x 3.0 (no overflow) in
        // test/a11y/primary_action_sweep_test.dart.
        FleetCheck.c5PrimaryScreens,
      },
      // Reckon builds its ColorScheme from ReckonTheme._scheme(seed:, primary:)
      // helper arguments C12 cannot resolve, so the rendered primaries are
      // recorded here: ember500 (light), ember400 (Dark) and sage400
      // (Late night). test/shared/theme/reckon_contrast_test.dart pins that
      // these are the theme primaries.
      accentColors: [
        FleetAccent.light(0xFFAD522E, label: 'ember500 (ReckonTheme.light)'),
        FleetAccent.dark(0xFFE17E4D, label: 'ember400 (ReckonTheme.hearthDark)'),
        FleetAccent.dark(0xFF8FA07E, label: 'sage400 (ReckonTheme.night)'),
      ],
      primaryActionScreens: {
        'HomeScreen',
        'AuthTierScreen',
        'ModelOnboardingScreen',
        'FirstCasePromptScreen',
        'CaseSummaryScreen',
        'RepollScreen',
        'ResolutionCheckInScreen',
        'PartyCreateScreen',
        'PartyVoteScreen',
      },
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
