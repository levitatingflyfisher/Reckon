// The theme follows the phone by default, light and dark are one tap away
// in the app bar, and Late night (Night) stays an explicit extra choice in
// Settings. Installs that stored the old Daytime / Evening / Late night
// picker are migrated on read.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/core/theme/theme_preference.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

Future<ThemePreference> _read(Map<String, String> stored) async {
  FlutterSecureStorage.setMockInitialValues(stored);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(themePreferenceProvider.future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('default and migration', () {
    test('nothing stored follows the phone', () async {
      expect(await _read({}), ThemePreference.system);
    });

    // Reckon only ever wrote the legacy key when the person tapped a row in
    // the picker; an untouched install has nothing stored. So a stored
    // Daytime was a choice, and it stays Light.
    test('legacy Daytime, which was only stored when tapped, stays Light',
        () async {
      expect(await _read({'reckon.theme_preference': 'light'}),
          ThemePreference.light);
    });

    test('legacy Evening becomes Dark', () async {
      expect(await _read({'reckon.theme_preference': 'hearthDark'}),
          ThemePreference.dark);
    });

    test('legacy Late night stays Night', () async {
      expect(await _read({'reckon.theme_preference': 'night'}),
          ThemePreference.night);
    });

    test('an unreadable legacy value follows the phone', () async {
      expect(await _read({'reckon.theme_preference': 'sepia'}),
          ThemePreference.system);
    });

    test('a choice under the new key wins over the legacy one', () async {
      expect(
          await _read({
            'reckon.theme_preference': 'hearthDark',
            'reckon.themeMode': 'light',
          }),
          ThemePreference.light);
    });

    test('a saved choice reads back, and the legacy key is never written',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      await setThemePreference(ThemePreference.dark);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(themePreferenceProvider.future),
          ThemePreference.dark);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'reckon.theme_preference'), isNull);
    });
  });

  group('what each choice renders', () {
    test('follow phone, light, dark and night map to a ThemeMode', () {
      expect(ThemePreference.system.themeMode, ThemeMode.system);
      expect(ThemePreference.light.themeMode, ThemeMode.light);
      expect(ThemePreference.dark.themeMode, ThemeMode.dark);
      expect(ThemePreference.night.themeMode, ThemeMode.dark);
    });

    test('dark is Reckon\'s warm Evening; night is the neutral Late night',
        () {
      expect(ThemePreference.dark.darkTheme().colorScheme.primary,
          ReckonTheme.hearthDark().colorScheme.primary);
      expect(ThemePreference.night.darkTheme().colorScheme.primary,
          ReckonTheme.night().colorScheme.primary);
      expect(ThemePreference.system.darkTheme().colorScheme.primary,
          ReckonTheme.hearthDark().colorScheme.primary);
    });

    test('the app-bar toggle shows Night as Dark, and a pick clears Night', () {
      expect(ThemePreference.night.toggleValue, OhThemeModePreference.dark);
      expect(ThemePreference.fromToggle(OhThemeModePreference.dark),
          ThemePreference.dark);
      expect(ThemePreference.fromToggle(OhThemeModePreference.system),
          ThemePreference.system);
      expect(ThemePreference.fromToggle(OhThemeModePreference.light),
          ThemePreference.light);
    });
  });
}
