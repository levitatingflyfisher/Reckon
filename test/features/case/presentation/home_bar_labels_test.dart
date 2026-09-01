import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/core/theme/theme_preference.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/presentation/home_screen.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

/// Fleet ruling: top-bar actions are an icon plus a short visible label; a
/// tooltip is never a command's only name. The group-decision door was a
/// bare people glyph, the only way into half the product (audit, below the
/// cut: humane-interface-07, design-of-everyday-things-09).
void main() {
  for (final (width, scale) in [(360.0, 1.0), (360.0, 1.3), (320.0, 3.0)]) {
    testWidgets('Home bar at ${width.toInt()} dp x $scale: both actions '
        'are worded, whole, and fit', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          openCasesStreamProvider
              .overrideWith((ref) => Stream.value(const <Case>[])),
        ],
        child:
            MaterialApp(theme: ReckonTheme.light(), home: const HomeScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final bar = find.byType(AppBar);
      // The title is never pushed out by the actions (coordinator ruling).
      final title = find.descendant(of: bar, matching: find.text('Reckon'));
      expect(title, findsOneWidget);
      final titlePara = tester.renderObject<RenderParagraph>(title);
      expect(titlePara.didExceedMaxLines, isFalse,
          reason: 'the Reckon title is cut off');
      expect(tester.getSize(title).width, greaterThan(0));

      // New decision (the FAB) stays whole on screen: it grows with its
      // label and does not ellipsize, so a longer word could run off the
      // left edge.
      final fab = tester.getRect(find.byType(FloatingActionButton));
      final screenRect = tester.getRect(find.byType(Scaffold));
      expect(fab.left, greaterThanOrEqualTo(screenRect.left),
          reason: 'New decision runs off the left edge: $fab');

      // Above 1.5x text the action's word moves into its tooltip and
      // screen-reader name (StillLife's rule); at everyday sizes, including
      // 1.3x, it is on the button.
      if (scale > 1.5) {
        expect(find.byTooltip('Group vote'), findsOneWidget);
        return;
      }
      final group = find.descendant(of: bar, matching: find.text('Group vote'));
      expect(group, findsOneWidget, reason: 'the group door has a word');
      expect(find.descendant(of: bar, matching: find.byType(ReckonThemeToggle)),
          findsOneWidget);

      final screen = tester.getRect(find.byType(Scaffold));
      for (final label in [group]) {
        final rect = tester.getRect(label);
        expect(screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
            isTrue,
            reason: 'label off screen: $rect');
        final para = tester.renderObject<RenderParagraph>(label);
        expect(para.didExceedMaxLines, isFalse, reason: 'label truncated');
      }
      // The door still works.
      expect(find.byTooltip('Group vote'), findsNothing,
          reason: 'the word is on the button, not only in a tooltip');
    });
  }
}
