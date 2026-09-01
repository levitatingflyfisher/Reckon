import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';
import 'package:reckon/shared/theme/reckon_tokens.dart';

/// Reckon renders Lora/Nunito from openhearth_design's package fonts (fleet
/// font ruling): the app bundles no font files of its own, so every family
/// it names must carry the package prefix or it falls back to the platform
/// face on a real phone.
void main() {
  const prefix = 'packages/openhearth_design/';

  test('every theme text style names a package font', () {
    for (final theme in [
      ReckonTheme.light(),
      ReckonTheme.hearthDark(),
      ReckonTheme.night(),
    ]) {
      final t = theme.textTheme;
      final styles = <String, TextStyle?>{
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };
      styles.forEach((name, style) {
        expect(style?.fontFamily, startsWith(prefix), reason: name);
      });
    }
    expect(ReckonTypography.labelSm().fontFamily, startsWith(prefix));
  });

  test('serifItalic resolves to the package Lora on a sans or serif base', () {
    final t = ReckonTheme.light().textTheme;
    for (final base in [t.bodyMedium, t.titleMedium, t.bodyLarge]) {
      final s = ReckonTypography.serifItalic(base)!;
      // Exactly once: copyWith keeps the base's package, so a pre-prefixed
      // family would come out as packages/.../packages/.../Lora.
      expect(s.fontFamily, '${prefix}Lora');
      expect(s.fontStyle, FontStyle.italic);
    }
  });

  test('no screen names a bare family or a monospace family by hand', () {
    final bare = RegExp(
      r'''fontFamily:\s*(['"](Lora|Nunito|monospace|JetBrains Mono)['"])''',
    );
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (bare.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'use a theme style, ReckonTypography, or OhTypography.code()',
    );
  });

  test('the app declares no font files of its own', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains(RegExp(r'^\s*fonts:', multiLine: true)), isFalse);
    expect(Directory('assets/fonts').existsSync(), isFalse);
  });
}
