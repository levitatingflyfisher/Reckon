import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:reckon/core/theme/theme_preference.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/presentation/home_screen.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

/// Fleet rulings: every screen's content is capped by OhPage (a phone
/// layout stretched across a 1024 px browser reads as broken; the app-wide
/// 760 px box is gone), and the theme is at most two taps from every main
/// screen.
void main() {
  test('every screen puts its body in OhPage', () {
    final missing = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      final scaffolds = RegExp(r'\bScaffold\(').allMatches(src).length;
      final paged =
          RegExp(r'body:\s*(const\s+)?OhPage\(').allMatches(src).length;
      if (scaffolds != paged) {
        missing.add('${f.path}: $scaffolds Scaffold, $paged OhPage bodies');
      }
    }
    expect(missing, isEmpty);
  });

  test('the four tab screens carry the theme toggle in their app bar', () {
    for (final path in [
      'lib/features/case/presentation/home_screen.dart',
      'lib/features/record/presentation/record_screen.dart',
      'lib/features/glossary/presentation/glossary_screen.dart',
      'lib/features/record/presentation/settings_screen.dart',
    ]) {
      expect(File(path).readAsStringSync(), contains('ReckonThemeToggle()'),
          reason: path);
    }
  });

  testWidgets(
      'Home at 1024 px: content capped at 640 and centred; theme two taps '
      'away', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        openCasesStreamProvider
            .overrideWith((ref) => Stream.value(const <Case>[])),
      ],
      child: MaterialApp(theme: ReckonTheme.light(), home: const HomeScreen()),
    ));
    await tester.pumpAndSettle();

    final page = tester.getRect(find.byType(OhPage));
    expect(page.width, 1024, reason: 'the page itself is full width');
    final content = tester.getRect(find
        .descendant(of: find.byType(OhPage), matching: find.byType(Center))
        .first);
    expect(content.width, lessThanOrEqualTo(OhPage.phoneMaxWidth));
    expect(content.center.dx, closeTo(512, 1));

    // Tap one: the toggle in the bar. Tap two: a named choice.
    final toggle = find.descendant(
        of: find.byType(AppBar), matching: find.byType(ReckonThemeToggle));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'reckon.themeMode'), 'dark');
  });
}
