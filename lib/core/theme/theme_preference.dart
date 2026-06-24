import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// Which of the three OhTheme variants Reckon is currently displaying.
///
/// Theme is a user-owned preference — we never flip it based on system
/// dark-mode. See `ohStyle/CLAUDE.md` for the full rationale on the
/// tri-theme model and why auto-switching is wrong for this portfolio.
enum ThemePreference {
  /// [OhTheme.light]. Hearth terracotta on linen. Daytime default.
  light,

  /// [OhTheme.hearthDark]. Warm brown-black, still hearth family.
  /// Evening, reflective reading.
  hearthDark,

  /// [OhTheme.night]. Neutral high-contrast dark, sage accent.
  /// Deep reading, late nights, low ambient light.
  night;

  ThemeData build() {
    switch (this) {
      case ThemePreference.light:
        return OhTheme.light();
      case ThemePreference.hearthDark:
        return OhTheme.hearthDark();
      case ThemePreference.night:
        return OhTheme.night();
    }
  }

  String get label => switch (this) {
        ThemePreference.light => 'Daytime',
        ThemePreference.hearthDark => 'Evening',
        ThemePreference.night => 'Late night',
      };

  String get hint => switch (this) {
        ThemePreference.light =>
          'Hearth on linen — default, full ambient light.',
        ThemePreference.hearthDark =>
          'Warm dark — brief evening check-ins, still hearth-family.',
        ThemePreference.night =>
          'Neutral dark with sage accent — deep reading, low light.',
      };

  static ThemePreference fromId(String? id) {
    for (final v in ThemePreference.values) {
      if (v.name == id) return v;
    }
    return ThemePreference.light;
  }
}

const _themeKey = 'reckon.theme_preference';

/// The user's persisted theme preference. Defaults to [ThemePreference.light]
/// when nothing has been picked.
final themePreferenceProvider = FutureProvider<ThemePreference>((ref) async {
  const storage = FlutterSecureStorage();
  final stored = await storage.read(key: _themeKey);
  return ThemePreference.fromId(stored);
});

/// Persist a new theme choice. Caller must invalidate
/// [themePreferenceProvider] after to trigger a rebuild.
Future<void> setThemePreference(ThemePreference pref) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _themeKey, value: pref.name);
}
