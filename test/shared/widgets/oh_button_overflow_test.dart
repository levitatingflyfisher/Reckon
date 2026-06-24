import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/shared/widgets/oh_button.dart';

/// Regression guard: an expanded OHButton with a long label must not overflow
/// its Row at the worst-case mobile combination (narrow 320dp width × large
/// accessibility text scale). Before the fix, the inner Text was rigid and the
/// Row (MainAxisSize.max) overflowed horizontally by ~tens of px at ×3.
void main() {
  testWidgets(
      'expanded OHButton with a long label does not overflow at 320dp / ×3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(3.0)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OHButton(
                  label: 'Full width primary action label',
                  onPressed: () {},
                  icon: Icons.check,
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
