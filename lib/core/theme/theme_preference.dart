import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../../shared/theme/reckon_theme.dart';

/// How Reckon picks its theme.
///
/// Fleet ruling: follow the phone by default, with light and dark one tap
/// away in the app bar ([ReckonThemeToggle]). Late night, the neutral
/// high-contrast dark with a sage accent, stays an explicit extra choice in
/// Settings. Every choice renders one of Reckon's own three themes.
enum ThemePreference {
  /// Follow the phone: [ReckonTheme.light] by day, [ReckonTheme.hearthDark]
  /// when the phone is dark. The default.
  system,

  /// Always [ReckonTheme.light]: ember on linen.
  light,

  /// Always [ReckonTheme.hearthDark]: warm brown-black, ember accent.
  dark,

  /// Always [ReckonTheme.night]: neutral dark with a sage accent.
  night;

  ThemeMode get themeMode => switch (this) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark || ThemePreference.night => ThemeMode.dark,
      };

  /// The theme used whenever the app is dark.
  ThemeData darkTheme() => this == ThemePreference.night
      ? ReckonTheme.night()
      : ReckonTheme.hearthDark();

  /// What the app-bar toggle shows. It has three choices, so Night reads as
  /// Dark there; picking any of them from the toggle leaves Night.
  OhThemeModePreference get toggleValue => switch (this) {
        ThemePreference.system => OhThemeModePreference.system,
        ThemePreference.light => OhThemeModePreference.light,
        ThemePreference.dark ||
        ThemePreference.night =>
          OhThemeModePreference.dark,
      };

  static ThemePreference fromToggle(OhThemeModePreference mode) =>
      switch (mode) {
        OhThemeModePreference.system => ThemePreference.system,
        OhThemeModePreference.light => ThemePreference.light,
        OhThemeModePreference.dark => ThemePreference.dark,
      };

  String get label => switch (this) {
        ThemePreference.system => 'Follow phone',
        ThemePreference.light => 'Light',
        ThemePreference.dark => 'Dark',
        ThemePreference.night => 'Late night',
      };

  String get hint => switch (this) {
        ThemePreference.system => 'Light by day, dark when your phone is.',
        ThemePreference.light => 'Ember on linen, for full daylight.',
        ThemePreference.dark => 'Warm dark, for evening check-ins.',
        ThemePreference.night =>
          'Neutral dark with a sage accent, for long reading in low light.',
      };

  static ThemePreference? _fromName(String? id) {
    for (final v in ThemePreference.values) {
      if (v.name == id) return v;
    }
    return null;
  }

  /// The old Daytime / Evening / Late night picker. It wrote its key only
  /// when a row was tapped (an untouched install stored nothing), so a
  /// stored Daytime is a choice and stays Light. Anything unreadable
  /// follows the phone.
  static ThemePreference _fromLegacy(String? id) => switch (id) {
        'light' => ThemePreference.light,
        'hearthDark' => ThemePreference.dark,
        'night' => ThemePreference.night,
        _ => ThemePreference.system,
      };
}

const _themeKey = 'reckon.themeMode';
const _legacyThemeKey = 'reckon.theme_preference';
const _storage = FlutterSecureStorage();

/// The person's theme choice. A choice saved under the current key wins;
/// otherwise the legacy picker's value is migrated on read. The legacy key
/// is never written, so the two can't disagree later.
final themePreferenceProvider = FutureProvider<ThemePreference>((ref) async {
  final stored =
      ThemePreference._fromName(await _storage.read(key: _themeKey));
  if (stored != null) return stored;
  return ThemePreference._fromLegacy(
      await _storage.read(key: _legacyThemeKey));
});

/// Persist a new theme choice. Caller must invalidate
/// [themePreferenceProvider] after to trigger a rebuild.
Future<void> setThemePreference(ThemePreference pref) async {
  await _storage.write(key: _themeKey, value: pref.name);
}

/// The app-bar theme control: icon plus short label, three choices one menu
/// away (so any theme is at most two taps from a primary screen).
class ReckonThemeToggle extends ConsumerWidget {
  const ReckonThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(themePreferenceProvider).valueOrNull ??
        ThemePreference.system;
    return OhThemeToggle(
      value: pref.toggleValue,
      onChanged: (mode) async {
        await setThemePreference(ThemePreference.fromToggle(mode));
        ref.invalidate(themePreferenceProvider);
      },
    );
  }
}
