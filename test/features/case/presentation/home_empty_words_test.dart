import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/case/data/case_providers.dart';
import 'package:reckon/features/case/domain/entities/case.dart';
import 'package:reckon/features/case/presentation/home_screen.dart';
import 'package:reckon/shared/theme/reckon_theme.dart';

import '../../../support/whole_words.dart';

/// The empty Home headline used to break mid-word at 320 dp and 3x text
/// ("de / cisions"): a headline that big cannot hold "decisions" on one
/// line, so the words must stay whole even if the headline grows less.
void main() {
  for (final (width, scale) in [(360.0, 1.0), (360.0, 2.0), (320.0, 3.0)]) {
    testWidgets('empty Home headline keeps whole words at '
        '${width.toInt()} dp x $scale', (tester) async {
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

      final headline = find.text('No open decisions yet.');
      expect(headline, findsOneWidget);
      expectNoWordBroken(tester, headline);
      expectNoWordBroken(
          tester, find.text('Choose New decision to start your first one.'));

      // It still grows with the reader's text size, only less.
      final para = tester.renderObject<RenderParagraph>(find.descendant(
          of: headline, matching: find.byType(RichText)));
      if (scale > 1.0) expect(para.textScaler.scale(10) / 10, greaterThan(1.0));
    });
  }
}
