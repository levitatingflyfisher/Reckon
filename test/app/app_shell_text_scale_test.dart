import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reckon/app/app_shell.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

/// Bottom-navigation labels must stay one word on one line at 360 dp with the
/// font one notch up (textScaler 1.3). "Techniques" broke as "Technique / s",
/// which no overflow check catches because the label wraps instead.
void main() {
  testWidgets('every tab label is a single line at 360 dp, text 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const SizedBox()),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(
      theme: ReckonTheme.light(),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    final labels = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(RichText),
    );
    expect(labels, findsWidgets);
    for (final element in labels.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      final text = paragraph.text.toPlainText();
      if (text.trim().isEmpty) continue; // icon glyphs render as RichText too
      final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: text.length));
      final lineTops = boxes.map((b) => b.top.round()).toSet();
      expect(lineTops.length, 1, reason: '"$text" wraps onto more than one line');
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: '"$text" is truncated');
    }
  });
}
